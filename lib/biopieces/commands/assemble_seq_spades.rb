# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                #
#                                                                              #
# This program is free software; you can redistribute it and/or                #
# modify it under the terms of the GNU General Public License                  #
# as published by the Free Software Foundation; either version 2               #
# of the License, or (at your option) any later version.                       #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, write to the Free Software                  #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,    #
# USA.                                                                         #
#                                                                              #
# http://www.gnu.org/copyleft/gpl.html                                         #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# This software is part of the Biopieces framework (www.biopieces.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
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
  # rubocop:disable ClassLength
  class AssembleSeqSpades
    require 'English'
    require 'biopieces/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               records_out assembled)

    # Constructor for the AssembleSeqSpades class.
    #
    # @param [Hash] options Options hash.
    #
    # @option options [Boolean] :careful
    #   Flag indicating use of careful assembly.
    #
    # @option options [Array] :kmers
    #   List of kmers to use.
    #
    # @option options [Integer] :cpus
    #   CPUs to use.
    #
    # @return [AssembleSeqSpades] Returns an instance of the class.
    def initialize(options)
      @options = options
      @lengths = []
      @type    = nil

      aux_exist('spades.py')
      check_options
      defaults
    end

    # Return a lambda for the AssembleSeqSpades command.
    #
    # @return [Proc] Returns the command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        TmpDir.create('reads.fq', 'reads.fa') do |in_fq, in_fa, tmp_dir|
          process_input(in_fq, in_fa, input, output)
          input_file = (@type == :fastq) ? in_fq : in_fa
          execute_spades(input_file, tmp_dir)
          process_output(output, File.join(tmp_dir, 'scaffolds.fasta'))
        end

        calc_n50(status)
      end
    end

    private

    # Check the options.
    def check_options
      options_allowed(@options, :careful, :cpus, :kmers)
      options_allowed_values(@options, careful: [true, false, nil])
      options_assert(@options, ':cpus >= 1')
      options_assert(@options, ":cpus <= #{BioPieces::Config::CORES_MAX}")
    end

    # Set default options.
    def defaults
      @options[:cpus] ||= 1
    end

    # Process input stream and write all sequence records to a temporary file.
    #
    # @param in_fq [String] Path to FASTQ temp file.
    # @param in_fa [String] Path to FASTA temp file.
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    def process_input(in_fq, in_fa, input, output)
      BioPieces::Fastq.open(in_fq, 'w') do |io_fq|
        BioPieces::Fasta.open(in_fa, 'w') do |io_fa|
          input.each do |record|
            @status[:records_in] += 1

            if record.key? :SEQ
              write_sequence(io_fq, io_fa, record)
            else
              @status[:records_out] += 1
              output.puts record
            end
          end
        end
      end
    end

    # Write a sequence record to the temporary file.
    #
    # @param io_fq [BioPieces::Fastq::IO] FASTQ IO stream.
    # @param io_fa [BioPieces::Fasta::IO] FASTA IO stream.
    # @param record [Hash] BioPiece record with sequence.
    def write_sequence(io_fq, io_fa, record)
      entry = BioPieces::Seq.new_bp(record)

      @status[:sequences_in] += 1
      @status[:residues_in]  += entry.length

      if entry.qual
        @type = :fastq
        io_fq.puts entry.to_fastq
      else
        io_fa.puts entry.to_fasta
      end
    end

    # Execute spades using a system call.
    #
    # @param input_file [String] Path to input file.
    # @param tmp_dir [String] Path to temp dir.
    #
    # @raise if command fails.
    def execute_spades(input_file, tmp_dir)
      cmd_line = compile_command(input_file, tmp_dir)

      if BioPices.verbose
        $stderr.puts cmd_line
        system(cmd_line)
      else
        system(cmd_line + ' > /dev/null 2>&1')
      end

      fail "Command failed: #{cmd_line}" unless $CHILD_STATUS.success?
    end

    # Compile the spades command.
    #
    # @param input_file [String] Path to input file.
    # @param tmp_dir [String] Path to temp dir.
    #
    # @return [String] A command string for executing Spades.
    def compile_command(input_file, tmp_dir)
      cmd = []
      cmd << 'spades.py'
      cmd << "--12 #{input_file}"
      cmd << '--only-assembler'
      cmd << '--careful'                        if @options[:careful]
      cmd << "-k #{@options[:kmers].join(',')}" if @options[:kmers]
      cmd << "-t #{@options[:cpus]}"
      cmd << "-o #{tmp_dir}"

      cmd.join(' ')
    end

    # Process the spades output and emit the contigs to the output stream.
    #
    # @param output [Enumerator::Yielder] Output stream
    # @param output_file [String] Path to output FASTA file with contigs.
    def process_output(output, output_file)
      BioPieces::Fasta.open(output_file) do |ios|
        ios.each do |entry|
          output << entry.to_bp
          @status[:records_out]   += 1
          @status[:sequences_out] += 1
          @status[:residues_out]  += entry.length

          @lengths << entry.length
        end
      end
    end

    # Calculate the n50 and add to the status.
    #
    # {http://en.wikipedia.org/wiki/N50_statistic}
    #
    # @param status [Hash] Status hash.
    def calc_n50(status)
      @lengths.sort!
      @lengths.reverse!

      status[:contig_max] = @lengths.first
      status[:contig_min] = @lengths.last

      count = 0

      @lengths.each do |length|
        count += length

        if count >= status[:residues_out] * 0.50
          status[:contig_n50] = length
          break
        end
      end
    end
  end
end
