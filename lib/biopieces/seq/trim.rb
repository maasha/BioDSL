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
  # Error class for all exceptions to do with Trim.
  class TrimError < StandardError; end

  # Module containing methods for end trimming sequences with suboptimal quality
  # scores.
  module Trim
    # Method to progressively trim a Seq object sequence from the right end until
    # a run of min_len residues with quality scores above min_qual is encountered.
    def quality_trim_right(min_qual, min_len = 1)
      check_trim_args(min_qual)

      pos = trim_right_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

      self.subseq(0, pos)
    end

    # Method to progressively trim a Seq object sequence from the right end until
    # a run of min_len residues with quality scores above min_qual is encountered.
    def quality_trim_right!(min_qual, min_len = 1)
      check_trim_args(min_qual)

      pos = trim_right_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

      self.subseq!(0, pos)
    end

    # Method to progressively trim a Seq object sequence from the left end until
    # a run of min_len residues with quality scores above min_qual is encountered.
    def quality_trim_left(min_qual, min_len = 1)
      check_trim_args(min_qual)

      pos = trim_left_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

      self.subseq(pos)
    end

    # Method to progressively trim a Seq object sequence from the left end until
    # a run of min_len residues with quality scores above min_qual is encountered.
    def quality_trim_left!(min_qual, min_len = 1)
      check_trim_args(min_qual)

      pos = trim_left_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

      self.subseq!(pos)
    end

    # Method to progressively trim a Seq object sequence from both ends until a
    # run of min_len residues with quality scores above min_qual is encountered.
    def quality_trim(min_qual, min_len = 1)
      check_trim_args(min_qual)

      pos_right = trim_right_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)
      pos_left  = trim_left_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

      pos_left = pos_right if pos_left > pos_right

      self.subseq(pos_left, pos_right - pos_left)
    end

    # Method to progressively trim a Seq object sequence from both ends until a
    # run of min_len residues with quality scores above min_qual is encountered.
    def quality_trim!(min_qual, min_len = 1)
      check_trim_args(min_qual)

      pos_right = trim_right_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)
      pos_left  = trim_left_pos_c(self.qual, self.length, min_qual, min_len, Seq::SCORE_BASE)

      pos_left = pos_right if pos_left > pos_right

      self.subseq!(pos_left, pos_right - pos_left)
    end

    private

    # Method to check the arguments for trimming and raise on bad sequence, qualities,
    # and min_qual.
    def check_trim_args(min_qual)
      raise TrimError, "no sequence"      if self.seq.nil?
      raise TrimError, "no quality score" if self.qual.nil?
      unless (Seq::SCORE_MIN .. Seq::SCORE_MAX).include? min_qual
        raise TrimError, "minimum quality value: #{min_qual} out of range #{Seq::SCORE_MIN} .. #{Seq::SCORE_MAX}"
      end
    end

    # Inline C functions for speed below.
    inline do |builder|
      # Method for locating the right trim position and return this.
      builder.c %{
        VALUE trim_right_pos_c(
          VALUE _qual,        // quality score string
          VALUE _len,         // length of quality score string
          VALUE _min_qual,    // minimum quality score
          VALUE _min_len,     // minimum quality length
          VALUE _score_base   // score base
        )
        { 
          char          *qual       = StringValuePtr(_qual);
          unsigned int   len        = FIX2UINT(_len);
          unsigned int   min_qual   = FIX2UINT(_min_qual);
          unsigned int   min_len    = FIX2UINT(_min_len);
          unsigned int   score_base = FIX2UINT(_score_base);

          unsigned int i = 0;
          unsigned int c = 0;

          while (i < len)
          {
            c = 0;

            while ((c < min_len) && ((c + i) < len) && (qual[len - (c + i) - 1] - score_base >= min_qual))
              c++;

            if (c == min_len)
              return UINT2NUM(len - i);
            else
              i += c;

            i++;
          }

          return UINT2NUM(0);
        }
      }

      # Method for locating the left trim position and return this.
      builder.c %{
        VALUE trim_left_pos_c(
          VALUE _qual,        // quality score string
          VALUE _len,         // length of quality score string
          VALUE _min_qual,    // minimum quality score
          VALUE _min_len,     // minimum quality length
          VALUE _score_base   // score base
        )
        { 
          char          *qual       = StringValuePtr(_qual);
          unsigned int   len        = FIX2UINT(_len);
          unsigned int   min_qual   = FIX2UINT(_min_qual);
          unsigned int   min_len    = FIX2UINT(_min_len);
          unsigned int   score_base = FIX2UINT(_score_base);

          unsigned int i = 0;
          unsigned int c = 0;

          while (i < len)
          {
            c = 0;

            while ((c < min_len) && ((c + i) < len) && (qual[c + i] - score_base >= min_qual))
              c++;

            if (c == min_len)
              return UINT2NUM(i);
            else
              i += c;

            i++;
          }

          return UINT2NUM(i);
        }
      }
    end
  end
end

__END__
