# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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
    # == Align sequences in the stream using Mothur.
    # 
    # This is a wrapper for the +mothur+ command +align.seqs()+. Basically,
    # it aligns sequences to a reference alignment.
    #
    # Please refer to the manual:
    #
    # http://www.mothur.org/wiki/Align.seqs
    #
    # Mothur must be installed for +align_seq_mothurs+ to work. Read more here:
    #
    # http://www.mothur.org/
    # 
    # == Usage
    # 
    #    align_seq_mothur(<template_file: <file>>[, cpus: <uint>])
    # 
    # === Options
    #
    # * template_file: <file>  - File with template alignment in FASTA format.
    # * cpus: <uint>           - Number of CPU cores to use (default=1).
    #
    # == Examples
    # 
    # To align the entries in the FASTA file `test.fna` to the template alignment
    # in the file `template.fna` do:
    #
    #    BP.new.
    #    read_fasta(input: "test.fna").
    #    align_seq_mothur(template_file: "template.fna").
    #    run
    def align_seq_mothur(options = {})
      require 'parallel'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :template_file, :cpus)
      options_required(options, :template_file)
      options_files_exist(options, :template_file)
      options_assert(options, ":cpus >= 1")
      options_assert(options, ":cpus <= #{Parallel.processor_count}")
      aux_exist("mothur")

      options[:cpus] ||= 1

      lmb = lambda do |input, output, status|
        status[:sequences_in]  = 0
        status[:sequences_out] = 0
        status[:residues_in]   = 0
        status[:residues_out]  = 0

        status_track(status) do
          tmp_dir = File.join(Dir.tmpdir, "#{Time.now.to_i}#{$$}")

          begin
            Dir.mkdir(tmp_dir)

            tmp_in = File.join(tmp_dir, "input.fasta")

            BioPieces::Fasta.open(tmp_in, 'w') do |ios|
              input.each_with_index do |record, i|
                status[:records_in] += 1

                if record[:SEQ]
                  status[:sequences_in] += 1
                  seq_name = record[:SEQ_NAME] || i.to_s

                  entry = BioPieces::Seq.new(seq_name: seq_name, seq: record[:SEQ])

                  status[:residues_in] += entry.length

                  ios.puts entry.to_fasta
                else
                  output << record
                  status[:records_out] += 1
                end
              end
            end

            cmd = %Q{mothur "#set.dir(input=#{tmp_dir}); \
                              set.dir(output=#{tmp_dir}); \
                              align.seqs(candidate=#{tmp_in}, \
                              template=#{options[:template_file]}, \
                              processors=#{options[:cpus]})"}

            if BioPieces::verbose
              system(cmd)
            else
              system("#{cmd} > /dev/null 2>&1")
            end

            raise "Mothur failed" unless $?.success?

            tmp_out = File.join(tmp_dir, "input.align")

            BioPieces::Fasta.open(tmp_out) do |ios|
              ios.each do |entry|
                output << entry.to_bp
                status[:records_out]   += 1
                status[:sequences_out] += 1
                status[:residues_out]  += entry.length
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

