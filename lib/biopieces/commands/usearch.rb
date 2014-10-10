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
    # == Run usearch on sequences in the stream.
    # 
    # Use +usearch+ to process sequences in the stream:
    # Avaliable programs:
    # * cluster_otus - Does what?
    #
    # Usearch 7.0 must be installed for +usearch+ to work. Read more here:
    #
    # http://www.drive5.com/usearch/
    # 
    # == Usage
    # 
    #    usearch(<program: <string>)
    # 
    # === Options
    #
    # * program: <string> - Usearch program to run.
    #
    # == Examples
    # 
    def usearch(options = {})
      options_orig = options.dup
      options_allowed(options, :program, :database)
      options_required(options, :program)
      options_allowed_values(options, program: [:cluster_otus, :uchime_ref])
      options_files_exist(options, :database)

      if options[:program] == :uchime_ref and not options[:database]
        raise BioPieces::OptionError, "Database missing"
      end

      options[:strand] ||= "plus"  # This option cannot be changed in usearch7.0

      lmb = lambda do |input, output, status|
        status[:sequences_in]  = 0
        status[:sequences_out] = 0

        status_track(status) do
          begin
            tmp_in  = Tempfile.new("uclust")
            tmp_out = Tempfile.new("uclust")

            BioPieces::Fasta.open(tmp_in, 'w') do |ios|
              input.each_with_index do |record, i|
                status[:records_in] += 1

                if record[:SEQ]
                  status[:sequences_in] += 1
                  seq_name = record[:SEQ_NAME] || i.to_s

                  if record[:SEQ_COUNT]
                    seq_name << ";size=#{record[:SEQ_COUNT]}"
                  elsif options[:program] == :cluster_otus
                    raise BioPieces::SeqError, "Missing SEQ_COUNT"
                  end

                  entry = BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])

                  ios.puts entry.to_fasta
                else
                  output << record
                  status[:records_out] += 1
                end
              end
            end

            case options[:program]
            when :cluster_otus 
              BioPieces::Usearch.cluster_otus(input: tmp_in,
                                              output: tmp_out,
                                              verbose: options[:verbose])
            when :uchime_ref 
              BioPieces::Usearch.uchime_ref(input: tmp_in, 
                                            output: tmp_out,
                                            database: options[:database],
                                            strand: options[:strand],
                                            verbose: options[:verbose])
            end

            Fasta.open(tmp_out) do |ios|
              ios.each do |entry|
                record = entry.to_bp

                if options[:program] == :cluster_otus
                  if record[:SEQ_NAME] =~ /;size=(\d+)$/
                    record[:SEQ_COUNT] = $1.to_i
                    record[:SEQ_NAME].sub!(/;size=\d+$/, '')
                  else
                    raise BioPieces::UsearchError, "Missing size in SEQ_NAME: #{record[:SEQ_NAME]}"
                  end
                end

                output << record
                status[:sequences_out] += 1
                status[:records_out]   += 1
              end
            end
          ensure
            tmp_in.unlink
            tmp_out.unlink
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

