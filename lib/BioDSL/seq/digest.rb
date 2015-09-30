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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

# Namespace for BioDSL.
module BioDSL
  # Error class for all exceptions to do with Digest.
  DigestError = Class.new(StandardError)

  # Namespace for Digest.
  module Digest
    # Method to get the next digestion product from a sequence.
    def each_digest(pattern, cut_pos)
      return to_enum(:each_digest, pattern, cut_pos) unless block_given?
      pattern = disambiguate(pattern)
      offset  = 0

      seq.upcase.scan pattern do
        pos = $`.length + cut_pos

        if pos >= 0 && pos < length - 2
          subseq = self[offset...pos]
          subseq.seq_name = "#{seq_name}[#{offset}-#{pos - offset - 1}]"

          yield subseq
        end

        offset = pos
      end

      offset = 0 if offset < 0 || offset > length
      subseq = self[offset..-1]
      subseq.seq_name = "#{seq_name}[#{offset}-#{length - 1}]"

      yield subseq
    end

    private

    # Method that returns a regexp object with a restriction
    # enzyme pattern with ambiguity codes substituted to the
    # appropriate regexp.
    def disambiguate(pattern)
      ambiguity = {
        'A' => 'A',
        'T' => 'T',
        'U' => 'T',
        'C' => 'C',
        'G' => 'G',
        'M' => '[AC]',
        'R' => '[AG]',
        'W' => '[AT]',
        'S' => '[CG]',
        'Y' => '[CT]',
        'K' => '[GT]',
        'V' => '[ACG]',
        'H' => '[ACT]',
        'D' => '[AGT]',
        'B' => '[CGT]',
        'N' => '[GATC]'
      }

      new_pattern = ''

      pattern.upcase.each_char do |char|
        if ambiguity[char]
          new_pattern << ambiguity[char]
        else
          fail DigestError, "Could not disambiguate residue: #{char}"
        end
      end

      Regexp.new(new_pattern)
    end
  end
end
