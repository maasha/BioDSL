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
    # == Dereplicate sequences in the stream.
    # 
    # +dereplicate_seq+ removes all duplicate sequence records. Dereplicated
    # sequences are output along with the count of replicates. Using the
    # +ignore_case+ option disables the default case sensitive sequence
    # matching.
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
    # {:SEQ_NAME=>"test1", :SEQ=>"ATGC", :SEQ_LEN=>4, :SEQ_COUNT=>2}
    # {:SEQ_NAME=>"test3", :SEQ=>"GCAT", :SEQ_LEN=>4, :SEQ_COUNT=>1}
    def dereplicate_seq(options = {})
      require 'google_hash'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :ignore_case)
      options_allowed_values(options, ignore_case: [nil, true, false])

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0

          hash = GoogleHashDenseLongToInt.new

          tmpfile = Tempfile.new('tmp')

          File.open(tmpfile, 'w') do |ios|
            input.each do |record|
              status[:records_in] += 1

              if seq = record[:SEQ]
                seq = seq.dup.downcase if options[:ignore_case]
                key = seq.hash

                status[:sequences_in] += 1

                unless hash.has_key? key
                  msg = Marshal.dump(record)
                  ios.write([msg.size].pack("I"))
                  ios.write(msg)

                  hash[key] = 0
                end

                hash[key] += 1
              else
                output << record

                status[:records_out] += 1
              end
            end
          end

          File.open(tmpfile) do |ios|
            while ! ios.eof?
              size   = ios.read(4)
              raise EOFError unless size
              size   = size.unpack("I").first
              msg    = ios.read(size)
              record = Marshal.load(msg)
              seq    = record[:SEQ].dup
              seq.downcase! if options[:ignore_case]
              record[:SEQ_COUNT] = hash[seq.hash]

              output << record

              status[:records_out] += 1
              status[:sequences_out] += 1
            end
          end

          status[:sequences_delta]         = status[:sequences_out] - status[:sequences_in]
          status[:sequences_delta_percent] = 100 * status[:sequences_delta] / status[:sequences_in].to_f
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

