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
    # == Remove gaps from sequences or gap only columns in alignments.
    # 
    # +degap_seq+ remove gaps from sequences (the letters ~-_.). If the option
    # +columns_only+ is used then gaps from aligned sequences will be removed,
    # if and only if the the entire columns consists of gaps.
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
    #    BP.new.read_fasta(input: "test.fna").degap_seq(columns_only: true).dump.run
    #
    #    {:SEQ_NAME=>"test1", :SEQ=>"A-GTC", :SEQ_LEN=>5}
    #    {:SEQ_NAME=>"test2", :SEQ=>"AGGTC", :SEQ_LEN=>5}
    def degap_seq(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :columns_only)
      options_allowed_values(options, columns_only: [true, false, nil])

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          status[:residues_in]   = 0
          status[:residues_out]  = 0

          indels = BioPieces::Seq::INDELS.sort.join("")

          if options[:columns_only]
            require 'tempfile'
            require 'narray'

            na_mask = nil
            max_len = nil
            count   = 0

            file = Tempfile.new("degap_seq")

            begin
              File.open(file, 'wb') do |ios|
                BioPieces::Serializer.new(ios) do |s|
                  input.each do |record|
                    status[:records_in] += 1

                    if record[:SEQ]
                      status[:sequences_in] += 1
                      status[:residues_in]  += record[:SEQ].length

                      max_len = record[:SEQ].length unless max_len

                      if max_len != record[:SEQ].length
                        raise BioPieces::SeqError, "Uneven seq lengths: #{max_len} != #{record[:SEQ].length}"
                      end

                      na_mask = NArray.int(record[:SEQ].length) unless na_mask
                      na_seq  = NArray.to_na(record[:SEQ], "byte")
                      indels.each_char { |c| na_mask += na_seq.eq(c.ord) }

                      count += 1
                    end

                    s << record
                  end
                end
              end

              na_mask = na_mask.ne count

              File.open(file, 'rb') do |ios|
                BioPieces::Serializer.new(ios) do |s|
                  s.each do |record|
                    if record[:SEQ]
                      na_seq           = NArray.to_na(record[:SEQ], "byte")
                      record[:SEQ]     = na_seq[na_mask].to_s
                      record[:SEQ_LEN] = record[:SEQ].length

                      status[:sequences_out] += 1
                      status[:residues_out]  += record[:SEQ].length
                    end

                    output << record
                    status[:records_out] += 1
                  end
                end
              end
            ensure
              file.close
              file.unlink
            end
          else
            input.each do |record|
              status[:records_in] += 1

              if record[:SEQ]
                entry = BioPieces::Seq.new_bp(record)

                status[:sequences_in] += 1
                status[:residues_in]  += entry.length

                entry.seq.delete!(indels)

                status[:sequences_out] += 1
                status[:residues_out]  += entry.length

                record.merge! entry.to_bp
              end

              output << record

              status[:records_out] += 1
            end
          end

          status[:residues_delta]         = status[:residues_out] - status[:residues_in]
          status[:residues_delta_mean]    = (status[:residues_delta].to_f / status[:records_out]).round(2)
          status[:residues_delta_percent] = (100 * status[:residues_delta].to_f / status[:residues_out]).round(2)
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

