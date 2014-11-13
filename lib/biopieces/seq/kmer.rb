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
    # Method that returns a sorted array of unique kmers, which are integer
    # representations of DNA/RNA sequence oligos where A is encoded in two bits
    # as 00, T as 01, U as 01, C as 10 and G as 11. Oligos with other nucleotids
    # are ignored. The following options applies:
    #   * kmer_size: kmer size in the range 1-12.
    #   * step_size: step size in the range 1-12 (defualt=1).
    #   * score_min: drop kmers with quality score below this.
    def to_kmers(options)
      options[:step_size] ||= 1
      raise KmerError, "No kmer_size" unless options[:kmer_size]
      raise KmerError, "Bad kmer_size: #{options[:kmer_size]}" unless (1 .. 12).include? options[:kmer_size]
      raise KmerError, "Bad step_size: #{options[:step_size]}" unless (1 .. 12).include? options[:step_size]
      if self.qual and options[:score_min]
        unless (Seq::SCORE_MIN .. Seq::SCORE_MAX).include? options[:score_min]
          raise KmerError, "score minimum: #{options[:score_min]} out of range #{Seq::SCORE_MIN} .. #{Seq::SCORE_MAX}"
        end
      end
    end
  end
end
