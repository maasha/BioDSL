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
  module Translate
    # Translation table 11
    # (http://www.ncbi.nlm.nih.gov/Taxonomy/taxonomyhome.html/index.cgi?chapter=cgencodes#SG11)
    #   AAs  = FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
    # Starts = ---M---------------M------------MMMM---------------M------------
    # Base1  = TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG
    # Base2  = TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG
    # Base3  = TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG
    TRANS_TAB11_START = {
      "TTG" => "M", "CTG" => "M", "ATT" => "M", "ATC" => "M",
      "ATA" => "M", "ATG" => "M", "GTG" => "M"
    }

    TRANS_TAB11 = {
      "TTT" => "F", "TCT" => "S", "TAT" => "Y", "TGT" => "C",
      "TTC" => "F", "TCC" => "S", "TAC" => "Y", "TGC" => "C",
      "TTA" => "L", "TCA" => "S", "TAA" => "*", "TGA" => "*",
      "TTG" => "L", "TCG" => "S", "TAG" => "*", "TGG" => "W",
      "CTT" => "L", "CCT" => "P", "CAT" => "H", "CGT" => "R",
      "CTC" => "L", "CCC" => "P", "CAC" => "H", "CGC" => "R",
      "CTA" => "L", "CCA" => "P", "CAA" => "Q", "CGA" => "R",
      "CTG" => "L", "CCG" => "P", "CAG" => "Q", "CGG" => "R",
      "ATT" => "I", "ACT" => "T", "AAT" => "N", "AGT" => "S",
      "ATC" => "I", "ACC" => "T", "AAC" => "N", "AGC" => "S",
      "ATA" => "I", "ACA" => "T", "AAA" => "K", "AGA" => "R",
      "ATG" => "M", "ACG" => "T", "AAG" => "K", "AGG" => "R",
      "GTT" => "V", "GCT" => "A", "GAT" => "D", "GGT" => "G",
      "GTC" => "V", "GCC" => "A", "GAC" => "D", "GGC" => "G",
      "GTA" => "V", "GCA" => "A", "GAA" => "E", "GGA" => "G",
      "GTG" => "V", "GCG" => "A", "GAG" => "E", "GGG" => "G"
    }

    # Method to translate a DNA sequence to protein.
    def translate!(trans_tab = 11)
      entry = translate(trans_tab)

      self.seq_name = entry.seq_name ? entry.seq_name.dup : nil
      self.seq      = entry.seq.dup
      self.type     = entry.type
      self.qual     = entry.qual

      self
    end

    alias :to_protein! :translate!

    def translate(trans_tab = 11)
      raise SeqError, "Sequence type must be 'dna' - not #{self.type}" unless self.type == :dna
      raise SeqError, "Sequence length must be a multiplum of 3 - was: #{self.length}" unless (self.length % 3) == 0

      case trans_tab
      when 11
        codon_start_hash = TRANS_TAB11_START
        codon_hash       = TRANS_TAB11
      else
        raise SeqError, "Unknown translation table: #{trans_tab}"
      end

      codon = self.seq[0 ... 3].upcase

      aa = codon_start_hash[codon]

      raise SeqError, "Unknown start codon: #{codon}" if aa.nil?

      protein = aa.dup

      (3 ... self.length).step(3) do |i|
        codon = self.seq[i ... i + 3].upcase

        aa = codon_hash[codon]

        raise SeqError, "Unknown codon: #{codon}" if aa.nil?

        protein << aa.dup
      end

      Seq.new(seq_name: self.seq_name, seq: protein[0 .. -2], type: :protein)
    end

    alias :to_protein :translate
  end
end
