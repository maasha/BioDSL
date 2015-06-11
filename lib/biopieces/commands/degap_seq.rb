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
  # == Remove gaps from sequences or gap only columns in alignments.
  #
  # +degap_seq+ remove gaps from sequences (the letters ~-_.). If the option
  # +columns_only+ is used then gaps from aligned sequences will be removed, if
  # and only if the the entire columns consists of gaps.
  #
  # == Usage
  #
  #    degap_seq([columns_only: <bool>])
  #
  # === Options
  #
  # * columns_only: <bool> - Remove gap columns only (default=false).
  #
  # == Examples
  #
  # Consider the following FASTA entries in the file `test.fna`:
  #
  #    >test1
  #    A-G~T.C_
  #    >test2
  #    AGG_T-C~
  #
  # To remove all gaps from all sequences do:
  #
  #    BP.new.read_fasta(input: "test.fna").degap_seq.dump.run
  #
  #    {:SEQ_NAME=>"test1", :SEQ=>"AGTC", :SEQ_LEN=>4}
  #    {:SEQ_NAME=>"test2", :SEQ=>"AGGTC", :SEQ_LEN=>5}
  #
  #
  # To remove all gap-only columns use the +columns_only+ option:
  #
  #    BP.new.
  #    read_fasta(input: "test.fna").
  #    degap_seq(columns_only: true).
  #    dump.
  #    run
  #
  #    {:SEQ_NAME=>"test1", :SEQ=>"A-GTC", :SEQ_LEN=>5}
  #    {:SEQ_NAME=>"test2", :SEQ=>"AGGTC", :SEQ_LEN=>5}
  #
  # rubocop:disable ClassLength
  class DegapSeq
    require 'narray'
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'

    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for DegapSeq.
    #
    # @param options [Hash] Options Hash.
    #
    # @option options [Boolean] :columns_only
    #   Flag indicating that only gap-columns only shoule be removed.
    #
    # @return [DegapSeq] Instance of DegapSeq.
    def initialize(options)
      @options = options
      @indels  = BioPieces::Seq::INDELS.sort.join('')
      @na_mask = nil
      @max_len = nil
      @count   = 0

      check_options
      status_init(STATS)
    end

    # Return the command lambda for DegapSeq.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        if @options[:columns_only]
          degap_columns(input, output)
          status[:columns_removed] = @na_mask.count_false
        else
          degap_all(input, output)
        end

        status_assign(status, STATS)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :columns_only)
      options_allowed_values(@options, columns_only: [true, false, nil])
    end

    # Remove all gap-only columns from all sequences in input stream and output
    # to output stream.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yeilder] Output stream.
    def degap_columns(input, output)
      TmpDir.create('degap_seq') do |tmp_file, _|
        process_input(input, tmp_file)
        create_mask
        process_output(output, tmp_file)
      end
    end

    # Serialize all input record to a temporary file and at the same time add
    # all sequence type records to the gap mask.
    #
    # @param input [Enumerator] Input stream.
    # @param tmp_file [String] Path to temporary file.
    def process_input(input, tmp_file)
      File.open(tmp_file, 'wb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          input.each do |record|
            @records_in += 1

            if (seq = record[:SEQ])
              mask_add(seq)
              @count += 1
            end

            s << record
          end
        end
      end
    end

    # Add sequence gaps to mask.
    #
    # @param seq [String] Sequences.
    def mask_add(seq)
      @sequences_in += 1
      @residues_in  += seq.length

      @max_len ||= seq.length

      check_length(seq)

      @na_mask ||= NArray.int(seq.length)
      na_seq  = NArray.to_na(seq, 'byte')
      @indels.each_char { |c| @na_mask += na_seq.eq(c.ord) }
    end

    # Check if sequence length match max_len.
    #
    # @param seq [String] Sequences.
    #
    # @raise [BioPieces::SeqError] if sequence length and max_len don't match.
    def check_length(seq)
      return if @max_len == seq.length
      fail BioPieces::SeqError,
           "Uneven seq lengths: #{@max_len} != #{seq.length}"
    end

    # Create a mask for all-gap columns.
    def create_mask
      @na_mask = @na_mask.ne @count
    end

    # Read all serialized records from the temporary file and emit to the output
    # stream records with degapped sequences.
    #
    # @param output [Enumerator::Yeilder] Output stream.
    # @param tmp_file [String] Path to temporary file.
    def process_output(output, tmp_file)
      File.open(tmp_file, 'rb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          s.each do |record|
            remove_residues(record) if record[:SEQ]

            output << record
            @records_out += 1
          end
        end
      end
    end

    # Given a BioPieces record containing sequence information
    # remove all residues based on the na_mask.
    #
    # @param record [Hash] BioPieces record.
    def remove_residues(record)
      na_seq           = NArray.to_na(record[:SEQ], 'byte')
      record[:SEQ]     = na_seq[@na_mask].to_s
      record[:SEQ_LEN] = record[:SEQ].length

      @sequences_out += 1
      @residues_out  += record[:SEQ].length
    end

    # Remove all gaps from all sequences in input stream and output to output
    # stream.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yeilder] Output stream.
    def degap_all(input, output)
      input.each do |record|
        @records_in += 1

        degap_seq(record) if record.key? :SEQ

        output << record

        @records_out += 1
      end
    end

    # Given a BioPieces record with sequence information, remove all gaps from
    # the sequence.
    #
    # @param record [Hash] BioPieces record.
    def degap_seq(record)
      entry = BioPieces::Seq.new_bp(record)

      @sequences_in += 1
      @residues_in  += entry.length

      entry.seq.delete!(@indels)

      @sequences_out += 1
      @residues_out  += entry.length

      record.merge! entry.to_bp
    end
  end
end
