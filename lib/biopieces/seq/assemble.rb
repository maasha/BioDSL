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
  # Class containing methods to assemble two overlapping sequences into a single.
  class Assemble
    extend BioPieces::Ambiguity

    # Class method to assemble two Seq objects.
    def self.pair(entry1, entry2, options = {})
      assemble = self.new(entry1, entry2, options)
      assemble.match
    end

    # Method to initialize an Assembly object.
    def initialize(entry1, entry2, options)
      @entry1  = entry1
      @entry2  = entry2
      @options = options
      @options[:mismatches_max] ||= 0
      @options[:overlap_min]    ||= 1
      @options[:overlap_max]    ||= entry1.length
      @options[:overlap_max]      = [@options[:overlap_max], entry1.length, entry2.length].min
    end

    # Method to locate overlapping matches between two sequences.
    def match
      overlap = @options[:overlap_max]

      while overlap >= @options[:overlap_min]
        mismatches_max = (overlap * @options[:mismatches_max] * 0.01).round

        if match_C(@entry1.seq, @entry2.seq, @entry1.length - overlap, 0, overlap, mismatches_max)
          entry_left  = @entry1[0 ... @entry1.length - overlap]
          entry_right = @entry2[overlap .. -1]

          if @entry1.qual and @entry2.qual
            entry_overlap1 = @entry1[-1 * overlap .. -1]
            entry_overlap2 = @entry2[0 ... overlap]

            entry_overlap = merge_overlap(entry_overlap1, entry_overlap2)
          else
            entry_overlap = @entry1[-1 * overlap .. -1]
          end

          entry_left.seq.downcase!
          entry_overlap.seq.upcase!
          entry_right.seq.downcase!
          entry_merged          = entry_left + entry_overlap + entry_right
          entry_merged.seq_name = @entry1.seq_name + ":overlap=#{overlap}"

          return entry_merged
        end

        overlap -= 1
      end
    end

    # Method to merge sequence and quality scores in an overlap.
    # The residue with the highest score at mismatch positions is selected.
    # The quality scores of the overlap are the mean of the two sequences.
    def merge_overlap(entry_overlap1, entry_overlap2)
      na_seq = NArray.byte(entry_overlap1.length, 2)
      na_seq[true, 0] = NArray.to_na(entry_overlap1.seq.downcase, "byte")
      na_seq[true, 1] = NArray.to_na(entry_overlap2.seq.downcase, "byte")

      na_qual = NArray.byte(entry_overlap1.length, 2)
      na_qual[true, 0] = NArray.to_na(entry_overlap1.qual, "byte")
      na_qual[true, 1] = NArray.to_na(entry_overlap2.qual, "byte")

      mask_xor = na_seq[true, 0] ^ na_seq[true, 1] > 0
      mask_seq = ((na_qual * mask_xor).eq( (na_qual * mask_xor).max(1)))

      merged      = BioPieces::Seq.new()
      merged.seq  = (na_seq * mask_seq).max(1).to_s
      merged.qual = na_qual.mean(1).round.to_type("byte").to_s

      merged
    end

    inline do |builder|
      add_ambiguity_macro(builder)

      # C method for determining if two strings of equal length match
      # given a maximum allowed mismatches and allowing for IUPAC
      # ambiguity codes. Returns true if match, else false.
      builder.c %{
        VALUE match_C(
          VALUE _string1,       // String 1
          VALUE _string2,       // String 2
          VALUE _offset1,       // Offset 1
          VALUE _offset2,       // Offset 2
          VALUE _length,        // String length
          VALUE _max_mismatch   // Maximum mismatches
        )
        {
          char         *string1      = StringValuePtr(_string1);
          char         *string2      = StringValuePtr(_string2);
          unsigned int  offset1      = FIX2UINT(_offset1);
          unsigned int  offset2      = FIX2UINT(_offset2);
          unsigned int  length       = FIX2UINT(_length);
          unsigned int  max_mismatch = FIX2UINT(_max_mismatch);

          unsigned int max_match = length - max_mismatch;
          unsigned int match     = 0;
          unsigned int mismatch  = 0;
          unsigned int i         = 0;

          for (i = 0; i < length; i++)
          {
            if (MATCH(string1[i + offset1], string2[i + offset2]))
            {
              match++;

              if (match >= max_match) {
                return Qtrue;
              }
            }
            else
            {
              mismatch++;

              if (mismatch > max_mismatch) {
                return Qfalse;
              }
            }
          }

          return Qfalse;
        }
      }
    end
  end
end
