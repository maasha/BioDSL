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
  # == Assemble sequences the stream using IDBA_UD.
  #
  # +assemble_seq_idba+ is a wrapper around the prokaryotic metagenome
  # assembler IDBA_UD:
  #
  # http://i.cs.hku.hk/~alse/hkubrg/projects/idba_ud/
  #
  # Any records containing sequence information will be included in the
  # assembly, but only the assembled contig sequences will be output to the
  # stream.
  #
  # The sequences records may contain quality scores, and if the sequence
  # names indicates that the sequence order is inter-leaved paired-end
  # assembly will be performed.
  #
  # == Usage
  #
  #    assemble_seq_idba([kmer_min: <uint>[, kmer_max: <uint>[, cpus: <uint>]]])
  #
  # === Options
  #
  # * kmer_min: <uint> - Minimum k-mer value (default: 24).
  # * kmer_max: <uint> - Maximum k-mer value (default: 128).
  # * cpus: <uint>     - Number of CPUs to use (default: 1).
  #
  # == Examples
  #
  # If you have two pair-end sequence files with the Illumina data then you
  # can assemble these using assemble_seq_idba like this:
  #
  #    BP.new.
  #    read_fastq(input: "file1.fq", input2: "file2.fq).
  #    assemble_seq_idba.
  #    write_fasta(output: "contigs.fna").
  #    run
  # rubocop:disable ClassLength
  class AssembleSeqIdba
    require 'English'
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/aux_helper'
    require 'biopieces/helpers/status_helper'

    include AuxHelper
    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out assembled)

    # Constructor for the AssembleSeqIdba class.
    #
    # @param [Hash] options Options hash.
    # @option options [Integer] :kmer_min Minimum kmer value.
    # @option options [Integer] :kmer_max Maximum kmer value.
    # @option options [Integer] :cpus CPUs to use.
    #
    # @return [AssembleSeqIdba] Returns an instance of the class.
    def initialize(options)
      @options = options
      @lengths = []

      aux_exist('idba_ud')
      check_options
      defaults
      status_init(STATS)
    end

    # Return a lambda for the AssembleSeqIdba command.
    #
    # @return [Proc] Returns the command lambda.
    def lmb
      lambda do |input, output, status|
        TmpDir.create('reads.fna', 'contig.fa') do |fa_in, fa_out, tmp_dir|
          process_input(input, output, fa_in)
          execute_idba(fa_in, tmp_dir)
          lengths = process_output(output, fa_out)
          status_term(lengths)
        end

        status_assign(status, STATS)
        calc_n50(status)
      end
    end

    private

    # Check the options.
    def check_options
      options_allowed(@options, :kmer_min, :kmer_max, :cpus)
      options_assert(@options, ':kmer_min >= 16')
      options_assert(@options, ':kmer_min <= 256')
      options_assert(@options, ':kmer_max >= 16')
      options_assert(@options, ':kmer_max <= 512')
      options_assert(@options, ':cpus >= 1')
      options_assert(@options, ":cpus <= #{BioPieces::Config::CORES_MAX}")
    end

    # Set the default option values.
    def defaults
      @options[:kmer_min] ||= 24
      @options[:kmer_max] ||= 48
      @options[:cpus]     ||= 1
    end

    # Read all records from input and emit non-sequence records to the output
    # stream. Sequence records are saved to a temporary file.
    #
    # @param input [Enumerator] input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param fa_in [String] Path to temporary FASTA file.
    def process_input(input, output, fa_in)
      BioPieces::Fasta.open(fa_in, 'w') do |fasta_io|
        input.each do |record|
          @records_in += 1

          if record.key? :SEQ
            entry = BioPieces::Seq.new_bp(record)

            @sequences_in += 1
            @residues_in  += entry.length

            fasta_io.puts entry.to_fasta
          else
            @records_out += 1
            output.puts record
          end
        end
      end
    end

    # Execute IDBA.
    #
    # @param fa_in [String] Path to input FASTA file.
    # @param tmp_dir [String] Temporary directory path.
    #
    # @raise If execution fails.
    def execute_idba(fa_in, tmp_dir)
      cmd_line = compile_cmd_line(fa_in, tmp_dir)
      $stderr.puts "Running: #{cmd_line}" if BioPieces.verbose
      system(cmd_line)

      fail cmd_line unless $CHILD_STATUS.success?
    end

    # Compile the command and options for executing IDBA.
    #
    # @param fa_in [String] Path to input FASTA file.
    # @param tmp_dir [String] Temporary directory path.
    #
    # @return [String] The command line for the IDBA system call.
    def compile_cmd_line(fa_in, tmp_dir)
      cmd = []
      cmd << 'idba_ud'
      cmd << "--read #{fa_in}"
      cmd << "--out #{tmp_dir}"
      cmd << "--mink #{@options[:kmer_min]}"
      cmd << "--maxk #{@options[:kmer_max]}"
      cmd << "--num_threads #{@options[:cpus]}"
      cmd << '> /dev/null 2>&1' unless BioPieces.verbose

      cmd.join(' ')
    end

    # Read the IDBA assembled contigs and output to the stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param fa_out [String] Path to contig FASTA file.
    def process_output(output, fa_out)
      BioPieces::Fasta.open(fa_out, 'r') do |ios|
        ios.each do |entry|
          output << entry.to_bp
          @records_out   += 1
          @sequences_out += 1
          @residues_out  += entry.length

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

      status[:contig_max] = @lengths.first || 0
      status[:contig_min] = @lengths.last  || 0
      status[:contig_n50] = 0

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
