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
  class Seq
    def oligofy(options)
      oligos = []

      regex_ambig = Regexp.new('^[ATCGatcg]+$') if options[:skip_ambiguity]

      if options[:min_score]
        low_score   = (0 + BioPieces::Seq::SCORE_BASE).chr
        high_score  = (options[:min_score] + BioPieces::Seq::SCORE_BASE).chr
        regex_score = Regexp.new("#{low_score}-#{high_score}")
      end

      0.upto(self.length - options[:kmer_size]) do |i|
        oligo = self[i ... i + options[:kmer_size]]

        next if options[:skip_ambiguity] and oligo.seq !~ regex_ambig
        next if options[:min_score]      and oligo.seq =~ regex_score

        bin = 0

        oligo.seq.upcase.each_char do |c|
          bin <<= 2;

          case c
          when 'A' then bin |= 0
          when 'T' then bin |= 1
          when 'C' then bin |= 2
          when 'G' then bin |= 3
          end
        end

        oligos << bin
      end

      oligos
    end
  end

  class FindSim
    BYTES_IN_INT      = 4
    BYTES_IN_FLOAT    = 4
    BYTES_IN_HIT      = 2 * BYTES_IN_INT + 1 * BYTES_IN_FLOAT   # i.e. 12
    NUC_ALPH_SIZE     = 4            # Alphabet size of nucleotides.
    RESULT_ARY_BUFFER = 10_000_000   # Buffer for the result_ary.
    HIT_ARY_BUFFER    = 1_000_000    # Buffer for the hit_ary.

    def initialize(options)
      @options    = options
      @q_total    = []
      @oligo_hash = Hash.new { |h, k| h[k] = [] }
      @count      = 0
    end

    def <<(entry)
      raise unless entry.is_a? BioPieces::Seq

      oligos = entry.oligofy(@options).uniq.sort

      @q_total << oligos.size

      oligos.each { |oligo| @oligo_hash[oligo] << @count }

      @count += 1
    end

    def search(options)
      raise "No query" if @count == 0

      q_total_ary = @q_total.pack("I*")
      q_ary       = ""

      beg        = 0
      oligo_begs = Array.new(BioPieces::Seq::DNA.size ** @options[:kmer_size], 0)
      oligo_ends = Array.new(BioPieces::Seq::DNA.size ** @options[:kmer_size], 0)

      @oligo_hash.each do |oligo, list|
        q_ary << list.pack("I*")
        oligo_begs[oligo] = beg
        oligo_ends[oligo] = beg + list.size

        beg += list.size
      end

      q_begs_ary = oligo_begs.pack("I*")
      q_ends_ary = oligo_ends.pack("I*")

      oligo_ary    = Cary.new(BioPieces::Seq::DNA.size ** @options[:kmer_size], BYTES_IN_INT)
      shared_ary   = Cary.new(@count, BYTES_IN_INT)
      result_ary   = Cary.new(RESULT_ARY_BUFFER, BYTES_IN_HIT)
      result_count = 0

      Fasta.open(options[:database]) do |ios|
        ios.each do |entry|
          oligo_ary.zero!
          shared_ary.zero!

          entry.oligofy(@options).uniq.sort.each_with_index { |oligo, i| oligo_ary[i] = oligo }

          count_shared_C()

          pp oligos
        end
      end

      self
    end

    def each
      return enum_for :each unless block_given?
    end

    class Cary
      def initialize(count, size)
        @count = count
        @size  = size
        @ary   = "\0" * count * size
      end

      def zero!
        @ary = "\0" * @count * @size
      end

      def []=(index, value)
        @ary[index] = 'a'
      end
    end
  end
end
