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
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for the DereplicateSeq class.
    #
    # @param options [Hash] Options hash.
    # @option options [Boolean] :ignore_case Ignore sequence case.
    #
    # @return [DereplicateSeq] Class intance.
    def initialize(options)
      @options = options
      @lookup  = {}

      check_options
    end

    # Return the command lambda for DereplicateSeq.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        TmpDir.create('dereplicate_seq') do |tmp_file, _|
          process_input(input, output, tmp_file)
          process_output(output, tmp_file)
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :ignore_case)
      options_allowed_values(@options, ignore_case: [nil, true, false])
    end

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
            @status[:records_in] += 1

            if record.key? :SEQ
              serialize(record, s)
            else
              output << record

              @status[:records_out] += 1
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
      @status[:sequences_in] += 1

      seq = record[:SEQ].dup
      @status[:residues_in] += seq.length
      seq.downcase! if @options[:ignore_case]
      key = seq.to_sym

      unless @lookup[key]
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
            @status[:residues_out] += seq.length
            seq.downcase! if @options[:ignore_case]
            record[:SEQ_COUNT] = @lookup[seq.to_sym]

            output << record

            @status[:records_out] += 1
            @status[:sequences_out] += 1
          end
        end
      end
    end
  end
end
