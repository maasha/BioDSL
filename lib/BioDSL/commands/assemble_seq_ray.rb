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
# This software is part of the BioDSL framework (www.BioDSL.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # rubocop:disable ClassLength

  # == Assemble sequences the stream using Ray.
  #
  # +assemble_seq_ray+ is a wrapper around the deBruijn graph assembler Ray:
  #
  # http://denovoassembler.sourceforge.net/
  #
  # Any records containing sequence information will be included in the
  # assembly, but only the assembled contig sequences will be output to the
  # stream.
  #
  # The sequences records may contain quality scores, and if the sequence
  # names indicates that the sequence order is inter-leaved paired-end
  # assembly will be performed.
  #
  # Kmer values must be odd.
  #
  # == Usage
  #
  #    assemble_seq_ray([kmer_min: <uint>[, kmer_max: <uint>
  #                     [, contig_min: <uint>[, cpus: <uint>]]]])
  #
  # === Options
  #
  # * kmer_min: <uint>   - Minimum k-mer value (default: 21).
  # * kmer_max: <uint>   - Maximum k-mer value (default: 49).
  # * contig_min: <uint> - Minimum contig size (default: 500).
  # * cpus: <uint>       - Number of CPUs to use (default: 1).
  #
  # == Examples
  #
  # If you have two pair-end sequence files with the Illumina data then you
  # can assemble these using +assemble_seq_ray+ like this:
  #
  #    BD.new.
  #    read_fastq(input: "file1.fq", input2: "file2.fq).
  #    assemble_seq_ray.
  #    write_fasta(output: "contigs.fna").
  #    run
  class AssembleSeqRay
    require 'English'
    require 'BioDSL/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out n50 contig_min contig_max kmer)

    # Constructor for the AssembleSeqRay class.
    #
    # @param [Hash] options Options hash.
    # @option options [Integer] :kmer_min Minimum kmer value.
    # @option options [Integer] :kmer_max Maximum kmer value.
    # @option options [Integer] :cpus CPUs to use.
    #
    # @return [AssembleSeqRay] Returns an instance of the class.
    def initialize(options)
      @options = options
      @lengths = []
      @paired  = nil

      aux_exist('Ray')
      aux_exist('mpiexec')
      defaults
      check_options
    end

    # Return a lambda for the AssembleSeqRay command.
    #
    # @return [Proc] Returns the command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        TmpDir.create('reads.fa') do |fa_in, tmp_dir|
          process_input(input, output, fa_in)
          @paired = paired?(fa_in)

          n50s = run_assemblies(fa_in, tmp_dir)

          best_kmer = n50s.sort_by(&:n50).reverse.first.kmer

          process_output(output, tmp_dir, best_kmer)
        end
      end
    end

    private

    # Run assemblies for all kmers and return a list of N50 objects which
    # contain info about the resulting n50 for each kmer.
    #
    # @param fa_in   [String] Path to input FASTA file.
    # @param tmp_dir [String] Temporary directory path.
    #
    # @return [Array] List of N50 objects.
    def run_assemblies(fa_in, tmp_dir)
      n50s = []

      (@options[:kmer_min]..@options[:kmer_max]).step(2).to_a.each do |kmer|
        result_dir = File.join(tmp_dir, kmer.to_s)
        execute_ray(fa_in, result_dir, kmer)
        n50s << parse_result(result_dir, kmer)
      end

      n50s
    end

    # Check the options.
    def check_options
      options_allowed(@options, :kmer_min, :kmer_max, :contig_min, :cpus)
      options_assert(@options, ':kmer_min >= 21')
      options_assert(@options, ':kmer_min <= 255')
      options_assert(@options, ':kmer_max >= 21')
      options_assert(@options, ':kmer_max <= 255')
      options_assert(@options, ':contig_min > 0')
      options_assert(@options, ':cpus >= 1')
      options_assert(@options, ":cpus <= #{BioDSL::Config::CORES_MAX}")

      assert_uneven(@options, :kmer_min)
      assert_uneven(@options, :kmer_max)
    end

    # Assert that the value to a given key and options hash is uneven.
    #
    # @param options [Hash]   Options hash.
    # @param key     [Symbol] Hash key whos value to check.
    #
    # @raise [RuntimeError] if even.
    def assert_uneven(options, key)
      return unless options[key].even?

      fail "#{key} must be an odd number - not #{options[key]}"
    end

    # Set the default option values.
    def defaults
      @options[:kmer_min]   ||= 21
      @options[:kmer_max]   ||= 49
      @options[:contig_min] ||= 500
      @options[:cpus]       ||= 1
    end

    # Read all records from input and emit non-sequence records to the output
    # stream. Sequence records are saved to a temporary file.
    #
    # @param input [Enumerator] input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param fa_in [String] Path to temporary FASTA file.
    def process_input(input, output, fa_in)
      BioDSL::Fasta.open(fa_in, 'w') do |fasta_io|
        input.each do |record|
          @status[:records_in] += 1

          if record.key? :SEQ
            entry = BioDSL::Seq.new_bp(record)

            @status[:sequences_in] += 1
            @status[:residues_in]  += entry.length

            fasta_io.puts entry.to_fasta
          else
            @status[:records_out] += 1
            output.puts record
          end
        end
      end
    end

    # Check if the reads in a given FASTA file are
    # paired by inspecting the sequence names of the first
    # two entries.
    #
    # @param file [String] Path to FASTA file.
    #
    # @return [Booleon] True if paired else false.
    def paired?(file)
      BioDSL::Fasta.open(file, 'r') do |ios|
        entry1 = ios.next_entry
        entry2 = ios.next_entry

        begin
          BioDSL::Seq.check_name_pair(entry1, entry2)

          return true
        rescue SeqError
          return false
        end
      end
    end

    # Execute Ray.
    #
    # @param fa_in   [String] Path to input FASTA file.
    # @param tmp_dir [String] Temporary directory path.
    # @param kmer    [Fixnum] Kmer size.
    #
    # @raise If execution fails.
    def execute_ray(fa_in, tmp_dir, kmer)
      cmd_line = compile_cmd_line(fa_in, tmp_dir, kmer)
      $stderr.puts "Running: #{cmd_line}" if BioDSL.verbose
      system(cmd_line)

      fail cmd_line unless $CHILD_STATUS.success?
    end

    # Compile the command and options for executing IDBA.
    #
    # @param fa_in   [String] Path to input FASTA file.
    # @param out_dir [String] Output directory path.
    # @param kmer    [Fixnum] Kmer size.
    #
    # @return [String] The command line for the IDBA system call.
    def compile_cmd_line(fa_in, out_dir, kmer)
      # mpiexec -n 6 Ray -k 31 -i interleaved -o output_dir
      # mpiexec -n 6 Ray -k 31 -s single -o output_dir
      cmd = []
      cmd << 'mpiexec'
      cmd << "-n #{@options[:cpus]}"
      cmd << 'Ray'
      cmd << "-k #{kmer}"

      if @paired
        cmd << "-i #{fa_in}"
      else
        cmd << "-s #{fa_in}"
      end

      cmd << "-o #{out_dir}"
      cmd << '> /dev/null 2>&1' unless BioDSL.verbose

      cmd.join(' ')
    end

    # Read the assembled scaffolds and return a N50 object.
    #
    # @param dir  [String] Path to output dir.
    # @param kmer [Fixnum] Kmer size.
    #
    # @return [N50] Result object
    def parse_result(dir, kmer)
      lengths = []

      BioDSL::Fasta.open(File.join(dir, 'Scaffolds.fasta')) do |ios|
        ios.each do |entry|
          lengths << entry.length if entry.length >= @options[:contig_min]
        end
      end

      N50.new(kmer, calc_n50(lengths))
    end

    # Calculate the n50.
    #
    # {http://en.wikipedia.org/wiki/N50_statistic}
    #
    # @param lengths [Array] List of contig lengths.
    def calc_n50(lengths)
      lengths.sort!
      lengths.reverse!

      sum   = lengths.inject(&:+)
      count = 0

      lengths.each do |length|
        count += length

        return length if count >= sum * 0.50
      end

      nil
    end

    # Read the best contigs and emit to the output stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param dir    [String]              Path to tmp_dir.
    # @param kmer   [Fixnum]              Highest n50 scoring kmer.
    def process_output(output, dir, kmer)
      lengths = []
      file    = File.join(dir, kmer.to_s, 'Scaffolds.fasta')

      BioDSL::Fasta.open(file, 'r') do |ios|
        ios.each do |entry|
          next if entry.length < @options[:contig_min]

          lengths << entry.length
          output  << entry.to_bp

          @status[:records_out]   += 1
          @status[:sequences_out] += 1
          @status[:residues_out]  += entry.length
        end
      end

      add_stats(kmer, lengths)
    end

    # Add status values to status hash.
    #
    # @param kmer    [Fixnum] Highest n50 scoring kmer.
    # @param lengths [Array]  List of contig lengths.
    def add_stats(kmer, lengths)
      @status[:kmer]   = kmer
      @status[:paired] = @paired

      unless lengths.empty?
        @status[:contig_min] = lengths.min
        @status[:contig_max] = lengths.max
        @status[:n50]        = calc_n50(lengths)
      end
    end

    N50 = Struct.new(:kmer, :n50)
  end
end
