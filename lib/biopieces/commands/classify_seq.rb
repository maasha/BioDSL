# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2014 Martin Asser Hansen (mail@maasha.dk).                  #
#                                                                                #
# This program is free software; you can redistribute it and/or                  #
# modify it under the terms of the GNU General Public License                    #
# as published by the Free Software Foundation; either version 2                 #
# of the License, or (at your option) any later version.                         #
#                                                                                #
# This program is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  #
# GNU General Public License for more details.                                   #
#                                                                                #
# You should have received a copy of the GNU General Public License              #
# along with this program; if not, write to the Free Software                    #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. #
#                                                                                #
# http://www.gnu.org/copyleft/gpl.html                                           #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module Commands
    # == Run classify_seq on sequences in the stream.
    # 
    # This is a wrapper for the +mothur+ command +classify.seqs()+. Basically,
    # it classifies sequences in the stream given a database file and a taxonomy
    # file which can be downloaded here:
    #
    # http://www.mothur.org/w/images/5/59/Trainset9_032012.pds.zip
    #
    # Please refer to the manual:
    #
    # http://www.mothur.org/wiki/Classify.seqs
    #
    # Mothur must be installed for +classify_seqs+ to work. Read more here:
    #
    # http://www.mothur.org/
    # 
    # == Usage
    # 
    #    classify_seq(<database: <file>>, <taxonomy: <file>>[, confidence: <uint>[, cpus: <uint>]])
    # 
    # === Options
    #
    # * database:   <file> - Database to search.
    # * taxonomy:   <file> - Taxonomy file for mapping names.
    # * confidence: <uint> - Confidence threshold (defualt=80).
    # * cpus:       <uint> - Number of CPU cores to use (default=1).
    #
    # == Examples
    # 
    # To classify a bunch of OTU sequences in the file +otus.fna+ we do:
    #
    #    database = "trainset9_032012.pds.fasta"
    #    taxonomy = "trainset9_032012.pds.tax"
    #
    #    BP.new.
    #    read_fasta(input: "otus.fna").
    #    classify_seq(database: database, taxonomy: taxonomy).
    #    grab(exact: true, keys: :RECORD_TYPE, select: "taxonomy").
    #    write_table(output: "classified.tab", header: true, force: true, skip: [:RECORD_TYPE]).
    #    run
    def classify_seq(options = {})
      require 'parallel'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :database, :taxonomy, :confidence, :cpus)
      options_required(options, :database, :taxonomy)
      options_files_exist(options, :database, :taxonomy)
      options_assert(options, ":confidence > 0")
      options_assert(options, ":confidence <= 100")
      options_assert(options, ":cpus >= 1")
      options_assert(options, ":cpus <= #{Parallel.processor_count}")

      options[:confidence] ||= 80
      options[:cpus]       ||= 1

      lmb = lambda do |input, output, status|
        status[:sequences_in]  = 0

        status_track(status) do
          tmp_dir = File.join(Dir.tmpdir, "#{Time.now.to_i}#{$$}")

          begin
            Dir.mkdir(tmp_dir)

            tmp_cmd = File.join(tmp_dir, "mothur.batch")
            tmp_in  = File.join(tmp_dir, "input.fasta")

            File.open(tmp_cmd, 'w') do |ios|
              ios.puts "classify.seqs(fasta=#{tmp_in}, reference=#{options[:database]}, taxonomy=#{options[:taxonomy]}, processors=#{options[:cpus]})"
            end

            BioPieces::Fasta.open(tmp_in, 'w') do |ios|
              input.each_with_index do |record, i|
                status[:records_in] += 1

                if record[:SEQ]
                  status[:sequences_in] += 1
                  seq_name = record[:SEQ_NAME] || i.to_s

                  entry = BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])

                  ios.puts entry.to_fasta
                end

                output << record
                status[:records_out] += 1
              end
            end

            if $VERBOSE
              system("mothur #{tmp_cmd}")
            else
              system("mothur #{tmp_cmd} > /dev/null 2&>1")
            end

            raise "Mothur failed" unless $?.success?

            tmp_out = Dir.glob("#{tmp_dir}/input.*.taxonomy").first

            BioPieces::CSV.open(tmp_out) do |ios|
              ios.each_hash(header: [:SEQ_NAME, :TAXONOMY]) do |new_record|
                new_record[:TAXONOMY].tr!('"', '')

                new_levels = []
                levels = new_record[:TAXONOMY].split(';')

                levels.each do |level|
                  if level =~ /^([^(]+)\((\d+)\)$/
                    name       = $1
                    confidence = $2.to_i

                    if confidence >= options[:confidence]
                      new_levels << "#{name}(#{confidence})"
                    end
                  else
                    raise "level unmatched: #{level}"
                  end
                end

                new_record[:TAXONOMY]    = new_levels.join(';')
                new_record[:RECORD_TYPE] = "taxonomy"
                output << new_record
                status[:records_out]
              end
            end
          ensure
            FileUtils.rm_rf(tmp_dir)
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

