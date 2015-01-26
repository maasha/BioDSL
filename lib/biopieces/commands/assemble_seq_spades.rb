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
    # == Assemble sequences the stream using SPAdes.
    # 
    # +assemble_seq_spades+ is a wrapper around the single prokaryotic genome
    # assembler SPAdes:
    #
    # http://bioinf.spbau.ru/spades
    #
    # Any records containing sequence information will be included in the
    # assembly, but only the assembled contig sequences will be output to the
    # stream.
    #
    # The sequences records may contain qualty scores, and if the sequence
    # names indicates that the sequence order is inter-leaved paired-end
    # assembly will be performed.
    #
    # == Usage
    # 
    #    assemble_seq_spades([careful: <bool>[, cpus: <uint>[, kmers: <list>]]])
    #
    # === Options
    #
    # * careful: <bool>  - Run SPAdes with the careful flag set.
    # * cpus: <uint>     - Number of CPUs to use (default: 1).
    # * kmers: <list>    - List of kmers to use (default: auto).
    # 
    # == Examples
    # 
    # If you have two pair-end sequence files with the Illumina data then you
    # can assemble these using assemble_seq_spades like this:
    #
    #    BP.new.
    #    read_fastq(input: "file1.fq", input2: "file2.fq).
    #    assemble_seq_spades(kmers: [55,77,99,127]).
    #    write_fasta(output: "contigs.fna").
    #    run
    def assemble_seq_spades(options = {})
      require 'parallel'
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :careful, :cpus, :kmers)
      options_allowed_values(options, careful: [true, false, nil])
      options_assert(options, ":cpus >= 1")
      options_assert(options, ":cpus <= #{Parallel.processor_count}")

      options[:cpus] ||= 1

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          status[:residues_in]   = 0
          status[:residues_out]  = 0

          Dir.mktmpdir do |tmpdir|
            fastq       = false
            input_fastq = File.join(tmpdir, "reads.fq")
            input_fasta = File.join(tmpdir, "reads.fa")

            BioPieces::Fastq.open(input_fastq, 'w') do |io_fq|
              BioPieces::Fasta.open(input_fasta, 'w') do |io_fa|
                input.each do |record|
                  status[:records_in] += 1

                  if record and record[:SEQ]
                    entry = BioPieces::Seq.new_bp(record)

                    status[:sequences_in] += 1
                    status[:residues_in]  += entry.length

                    if entry.qual
                      fastq = true
                      io_fq.puts entry.to_fastq
                    else
                      io_pa.puts entry.to_fasta
                    end
                  else
                    status[:records_out]   += 1
                    output.puts record
                  end
                end
              end
            end

            input_file = fastq ? input_fastq : input_fasta

            cmd = []
            cmd << "spades.py"
            cmd << "--12 #{input_file}"
            cmd << "--only-assembler"
            cmd << "--careful"                       if options[:careful]
            cmd << "-k #{options[:kmers].join(',')}" if options[:kmers]
            cmd << "-t #{options[:cpus]}"
            cmd << "-o #{tmpdir}"

            if $VERBOSE
              $stderr.puts cmd.join(" ")
              system(cmd.join(" "))
            else
              system(cmd.join(" ") + " > /dev/null 2>&1")
            end

            raise "Command failed: #{cmd.join(" ")}" unless $?.success?

            lengths = []

            BioPieces::Fasta.open(File.join(tmpdir, "scaffolds.fasta")) do |ios|
              ios.each do |entry|
                output << entry.to_bp
                status[:records_out]   += 1
                status[:sequences_out] += 1
                status[:residues_out]  += entry.length

                lengths << entry.length
              end
            end

            lengths.sort!
            lengths.reverse!

            status[:contig_max] = lengths.first
            status[:contig_min] = lengths.last

            count = 0

            lengths.each do |length|
              count += length

              if count >= status[:residues_out] * 0.50
                status[:contig_n50] = length
                break
              end
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end
