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
  # == Genecall sequences in the stream.
  #
  # +Genecall+ predict genes in prokaryotic single genomes or metagenomes using
  # Prodigal 2.6 which must be installed:
  #
  # http://prodigal.ornl.gov/
  #
  # The records produced are of the type:
  #
  #     {:RECORD_TYPE=>"gene",
  #      :S_BEG=>2, :S_END=>109,
  #      :S_LEN=>108,
  #      :STRAND=>"-",
  #      :SEQ_NAME=>"contig1",
  #      :SEQ=>"MGKVIGIDLGTTNSCVAVMDGKTAKVIENAEGMRTT",
  #      :SEQ_LEN=>36}
  #
  # == Usage
  #
  #    genecall([type: <string>[, procedure: <string>[, closed_ends: <bool>
  #             [, masked: <bool>]]]])
  #
  # === Options
  #
  # * type:        <string> - Output dna or protein sequence (default: dna).
  # * procedure:   <string> - Single or meta (default: single).
  # * closed_ends: <bool>   - Don't allow truncated gene at ends.
  # * masked:      <bool>   - Ignore stretch of Ns.
  #
  # == Examples
  #
  # To genecall a genome do:
  #
  #    BD.new.
  #    read_fasta(input: "contigs.fna").
  #    genecall.
  #    grab(select: "genecall", key: :type, exact: true).
  #    write_fasta(output: "genes.fna").
  #    run
  #
  # To add genecall data to the sequence name use +merge_values+:
  #
  #    BD.new.
  #    read_fasta(input: "contigs.fna").
  #    genecall(type: "protein").
  #    grab(select: "genecall", key: :type, exact: true).
  #    merge_values(keys: [:SEQ_NAME, :S_BEG, :S_END, :S_LEN, :STRAND]).
  #    write_fasta(output: "genes.faa").
  #    run
  class Genecall
    require 'English'
    require 'BioDSL/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for the Genecall class.
    #
    # @param [Hash] options Options hash.
    # @option options [Symbol]  :type of output.
    # @option options [Symbol]  :procedure used for genecalling.
    # @option options [Boolean] :closed_ends disallow truncated genes at ends.
    # @option options [Boolean] :masked ignore stretch of Ns.
    #
    # @return [Genecall] Returns an instance of the class.
    def initialize(options)
      @options = options
      @names   = {}

      aux_exist('prodigal')
      defaults
      check_options

      @type = @options[:type].to_sym
    end

    # Return a lambda for the genecall command.
    #
    # @return [Proc] Returns the command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        TmpDir.create('i.fa', 'o.fna', 'o.faa') do |tmp_in, tmp_fna, tmp_faa|
          process_input(input, output, tmp_in)
          run_prodigal(tmp_in, tmp_fna, tmp_faa)
          process_output(output, tmp_fna, tmp_faa)
        end
      end
    end

    private

    # Run Prodigal on the input file.
    #
    # @param tmp_in  [String] Path to input FASTA file.
    # @param tmp_fna [String] Path to output FASTA DNA file.
    # @param tmp_faa [String] Path to output FASTA Protein file.
    def run_prodigal(tmp_in, tmp_fna, tmp_faa)
      cmd = []
      cmd << 'prodigal'
      cmd << '-f gff'
      cmd << '-c' if @options[:closed_ends]
      cmd << '-m' if @options[:masked]
      cmd << "-p #{@options[:procedure]}"
      cmd << "-i #{tmp_in}"
      cmd << "-d #{tmp_fna}"
      cmd << "-a #{tmp_faa}"
      cmd << '-q'               unless BioDSL.verbose
      cmd << '> /dev/null 2>&1' unless BioDSL.verbose

      cmd_line = cmd.join(' ')

      $stderr.puts "Running: #{cmd_line}" if BioDSL.verbose
      system(cmd_line)

      fail cmd_line unless $CHILD_STATUS.success?
    end

    # Check the options.
    def check_options
      options_allowed(@options, :type, :procedure, :closed_ends, :masked)
      options_allowed_values(@options, type: [:dna, :protein, 'dna',
                                              'protein'])
      options_allowed_values(@options, procedure: ['single', 'meta', :single,
                                                   :meta])
      options_allowed_values(@options, closed_ends: [nil, true, false])
      options_allowed_values(@options, masked: [nil, true, false])
    end

    # Set the default option values.
    def defaults
      @options[:type]      ||= :dna
      @options[:procedure] ||= :single
    end

    # Read all records from input and emit non-sequence records to the output
    # stream. Sequence records are saved to a temporary file.
    #
    # @param input [Enumerator] input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param fa_in [String] Path to temporary FASTA file.
    def process_input(input, output, fa_in)
      BioDSL::Fasta.open(fa_in, 'w') do |fasta_io|
        input.each_with_index do |record, i|
          @status[:records_in] += 1

          if record.key? :SEQ
            entry = BioDSL::Seq.new(seq_name: i, seq: record[:SEQ])
            @names[i] = record[:SEQ_NAME] || i

            @status[:sequences_in]  += 1
            @status[:sequences_out] += 1
            @status[:residues_in]   += entry.length
            @status[:residues_out]  += entry.length

            fasta_io.puts entry.to_fasta
          end

          @status[:records_out] += 1
          output << record
        end
      end
    end

    # Read the output from file and emit to the output stream.
    #
    # @param output  [Enumerator::Yielder] Output stream.
    # @param tmp_fna [String]              Path to output FASTA DNA file.
    # @param tmp_faa [String]              Path to output FASTA Protein file.
    def process_output(output, tmp_fna, tmp_faa)
      file = (@type == :dna) ? tmp_fna : tmp_faa

      BioDSL::Fasta.open(file, 'r') do |ios|
        ios.each do |entry|
          output << parse_entry(entry)

          @status[:records_out]   += 1
          @status[:sequences_out] += 1
          @status[:residues_out]  += entry.length
        end
      end
    end

    # Parse Prodigal genecall data from sequence name.
    #
    # @param entry [BioDSL::Seq] Sequence object.
    #
    # @return [Hash] BioPiece record.
    def parse_entry(entry)
      record = {}
      fields = entry.seq_name.split(' # ')

      record[:RECORD_TYPE] = 'genecall'
      record[:S_BEG]       = fields[1].to_i - 1
      record[:S_END]       = fields[2].to_i - 1
      record[:S_LEN]       = record[:S_END] - record[:S_BEG] + 1
      record[:STRAND]      = fields[3] == '1' ? '+' : '-'
      record[:SEQ_NAME]    = @names[fields[0].split('_').first.to_i]
      record[:SEQ]         = entry.seq
      record[:SEQ_LEN]     = entry.length
      record[:SEQ_TYPE]    = @type.to_s

      record
    end
  end
end
