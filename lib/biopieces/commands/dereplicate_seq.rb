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
  # == Dereplicate sequences in the stream.
  #
  # +dereplicate_seq+ removes all duplicate sequence records. Dereplicated
  # sequences are output along with the count of replicates. Using the
  # +ignore_case+ option disables the default case sensitive sequence matching.
  #
  # == Usage
  #
  #    dereplicate_seq([ignore_case: <bool>])
  #
  # === Options
  #
  # * ignore_case: <bool> - Ignore sequence case.
  #
  # == Examples
  #
  # Consider the following FASTA file test.fna:
  #
  #    >test1
  #    ATGC
  #    >test2
  #    ATGC
  #    >test3
  #    GCAT
  #
  # To dereplicate all sequences we use +read_fasta+ and +dereplicate_seq+:
  #
  #    BP.new.read_fasta(input: "test.fna").dereplicate_seq.dump.run
  #
  #    {:SEQ_NAME=>"test1", :SEQ=>"ATGC", :SEQ_LEN=>4, :SEQ_COUNT=>2}
  #    {:SEQ_NAME=>"test3", :SEQ=>"GCAT", :SEQ_LEN=>4, :SEQ_COUNT=>1}
  class DereplicateSeq
    require 'google_hash'
    require 'biopieces/helpers/options_helper'

    extend OptionsHelper
    include OptionsHelper

    # Check options and return command lambda for dereplicate_seq.
    #
    # @param options [Hash] Options hash.
    # @option options [Boolean] :ignore_case Ignore sequence case.
    #
    # @return [Proc] Lambda for the command.
    def self.lmb(options)
      options_allowed(options, :ignore_case)
      options_allowed_values(options, ignore_case: [nil, true, false])

      new(options).lmb
    end

    # Constructor for the DereplicateSeq class.
    #
    # @param options [Hash] Options hash.
    # @option options [Boolean] :ignore_case Ignore sequence case.
    #
    # @return [DereplicateSeq] Class intance.
    def initialize(options)
      @options       = options
      @records_in    = 0
      @records_out   = 0
      @sequences_in  = 0
      @sequences_out = 0
      @lookup        = GoogleHashDenseLongToInt.new
    end

    # Return the command lambda for DereplicateSeq.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        TmpDir.create('dereplicate_seq') do |tmp_file, _|
          process_input(input, output, tmp_file)
          process_output(output, tmp_file)
        end

        assign_status(status)
      end
    end

    private

    # Process input stream and serialize all records with sequence information.
    # All other records are emitted to the output stream.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_file [String] Path to temporary file.
    def process_input(input, output, tmp_file)
      File.open(tmp_file, 'wb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          input.each do |record|
            @records_in += 1

            if record.key? :SEQ
              serialize(record, s)
            else
              output << record

              @records_out += 1
            end
          end
        end
      end
    end

    # Serialize records with unique sequences and keep a count of how many time
    # each sequence was encountered.
    #
    # @param record [Hash] BioPieces record.
    # @param s [BioPieces::Serializer] Serializer.
    def serialize(record, s)
      @sequences_in += 1

      seq = record[:SEQ].dup
      seq.downcase! if @options[:ignore_case]
      key = seq.hash

      unless @lookup.key? key
        s << record

        @lookup[key] = 0
      end

      @lookup[key] += 1
    end

    # Read all serialized records from tmp file and emit to the output stream
    # along with the sequence count.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_file [String] Path to tmp file.
    def process_output(output, tmp_file)
      File.open(tmp_file, 'rb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          s.each do |record|
            seq = record[:SEQ].dup
            seq.downcase! if @options[:ignore_case]
            record[:SEQ_COUNT] = @lookup[seq.hash]

            output << record

            @records_out += 1
            @sequences_out += 1
          end
        end
      end
    end

    # Assign values to status hash.
    #
    # @param status [Hash] Status hash.
    def assign_status(status)
      status[:records_in]    = @records_in
      status[:records_out]   = @records_out
      status[:sequences_in]  = @sequences_in
      status[:sequences_out] = @sequences_out
    end
  end
end
