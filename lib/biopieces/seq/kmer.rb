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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Error class for all exceptions to do with Kmer.
  class KmerError < StandardError; end

  # Module containing methods for manipulating sequence kmers.
  module Kmer
    # Debug method to convert an array of binary encoded kmers to
    # nucleotide oligos.
    def self.to_oligos(kmers, kmer_size)
      oligos = []

      kmers.each do |kmer|
        oligo = ""
        bin   = "%0#{kmer_size * 2}b" % kmer

        bin.scan(/.{2}/) { |m|
          case m
          when '00' then oligo << 'a'
          when '01' then oligo << 't'
          when '10' then oligo << 'c'
          when '11' then oligo << 'g'
          else
            raise "unknown m #{m}"
          end
        }

        oligos << oligo
      end

      oligos
    end

    # Method that returns a sorted array of unique kmers, which are integer
    # representations of DNA/RNA sequence oligos where A is encoded in two bits
    # as 00, T as 01, U as 01, C as 10 and G as 11. Oligos with other nucleotides
    # are ignored. The following options apply:
    #   * kmer_size: kmer size in the range 1-12.
    #   * step_size: step size in the range 1-12 (defualt=1).
    #   * score_min: drop kmers with quality score below this.
    def to_kmers(options)
      options[:step_size] ||= 1
      options[:score_min] ||= Seq::SCORE_MAX
      raise KmerError, "No kmer_size" unless options[:kmer_size]
      raise KmerError, "Bad kmer_size: #{options[:kmer_size]}" unless (1 .. 12).include? options[:kmer_size]
      raise KmerError, "Bad step_size: #{options[:step_size]}" unless (1 .. 12).include? options[:step_size]
      if self.qual and not (Seq::SCORE_MIN .. Seq::SCORE_MAX).include? options[:score_min]
        raise KmerError, "score minimum: #{options[:score_min]} out of range #{Seq::SCORE_MIN} .. #{Seq::SCORE_MAX}"
      end

      #naive_bin(options)
      if self.qual
        to_kmers_qual_C(self.seq, self.qual, self.length, options[:kmer_size], options[:step_size], options[:score_min], Seq::SCORE_BASE)
      else
        to_kmers_C(self.seq, self.length, options[:kmer_size], options[:step_size])
      end
    end

    private

    inline do |builder|
      builder.prefix %{
        int encode_nuc(char nuc, unsigned int *bin)
        {
          *bin <<= 2;

          switch(nuc)
          {
            case 'a':
              *bin |= 0;
              break;
            case 'A':
              *bin |= 0;
              break;
            case 't':
              *bin |= 1;
              break;
            case 'T':
              *bin |= 1;
              break;
            case 'u':
              *bin |= 1;
              break;
            case 'U':
              *bin |= 1;
              break;
            case 'c':
              *bin |= 2;
              break;
            case 'C':
              *bin |= 2;
              break;
            case 'g':
              *bin |= 3;
              break;
            case 'G':
              *bin |= 3;
              break;
            default:
              return 0;
          }

          return 1;
        }
      }

      builder.c %{
        VALUE to_kmers_C(
          VALUE _seq,         // DNA or RNA sequence string.
          VALUE _len,         // sequence length.
          VALUE _kmer_size,   // Size of kmer or oligo.
          VALUE _step_size    // Step size for overlapping kmers.
        )
        {
          char         *seq       = StringValuePtr(_seq);
          unsigned int  len       = FIX2UINT(_len);
          unsigned int  kmer_size = FIX2UINT(_kmer_size);
          unsigned int  step_size = FIX2UINT(_step_size);
          
          VALUE         array = rb_ary_new();
          unsigned int  bin   = 0;
          unsigned int  enc   = 0;
          unsigned int  i     = 0;
          unsigned int  mask  = (1 << (2 * kmer_size)) - 1;

          for (i = 0; i < len; i++)
          {
            if (encode_nuc(seq[i], &bin))
            {
              enc++;

              if (((i % step_size) == 0) && (enc >= kmer_size)) {
                rb_ary_push(array, UINT2NUM((bin & mask)));
              }
            }
            else
            {
              enc = 0;
            }
          }

          return array;
        }
      }

      builder.c %{
        VALUE to_kmers_qual_C(
          VALUE _seq,         // DNA or RNA sequence string.
          VALUE _qual,        // Quality score string.
          VALUE _len,         // sequence length.
          VALUE _kmer_size,   // Size of kmer or oligo.
          VALUE _step_size,   // Step size for overlapping kmers.
          VALUE _score_min,   // Miminum quality score to accept in a kmer.
          VALUE _score_base   // Quality score base.
        )
        {
          char         *seq        = StringValuePtr(_seq);
          char         *qual       = StringValuePtr(_qual);
          unsigned int  len        = FIX2UINT(_len);
          unsigned int  kmer_size  = FIX2UINT(_kmer_size);
          unsigned int  step_size  = FIX2UINT(_step_size);
          unsigned int  score_min  = FIX2UINT(_score_min);
          unsigned int  score_base = FIX2UINT(_score_base);
          
          VALUE         array = rb_ary_new();
          unsigned int  bin   = 0;
          unsigned int  enc   = 0;
          unsigned int  i     = 0;
          unsigned int  mask  = (1 << (2 * kmer_size)) - 1;

          for (i = 0; i < len; i++)
          {
            if (encode_nuc(seq[i], &bin))
            {
              enc++;

              if ((unsigned int) qual[i] - score_base < score_min)
              {
                enc = 0;
              }
              else if ((enc >= kmer_size) && ((i % step_size) == 0))
              {
                rb_ary_push(array, UINT2NUM((bin & mask)));
              }
            }
            else
            {
              enc = 0;
            }
          }

          return array;
        }
      }
    end

    def naive(options)
      oligos = []

      (0 .. self.length - options[:kmer_size]).each do |i|
        oligo = self[i ... i + options[:kmer_size]]

        next unless oligo.seq.upcase =~ /^[ATUCG]+$/
        next if oligo.qual and options[:scores_min] and oligo.scores_min < options[:scores_min]

        oligos << oligo.seq.upcase
      end

      oligos
    end

    def naive_bin(options)
      oligos = []

      (0 .. self.length - options[:kmer_size]).each do |i|
        oligo = self[i ... i + options[:kmer_size]]

        next unless oligo.seq.upcase =~ /^[ATCG]+$/
        next if oligo.qual and options[:scores_min] and oligo.scores_min < options[:scores_min]

        bin = 0

        oligo.seq.upcase.each_char do |c|
          bin <<= 2
          case c
          when 'T' then bin |= 1
          when 'U' then bin |= 1
          when 'C' then bin |= 2
          when 'G' then bin |= 3
          end
        end

        oligos << bin
      end

      oligos
    end
  end
end
