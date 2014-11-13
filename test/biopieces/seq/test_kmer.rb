#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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

require 'test/helper'

class TestKmer < Test::Unit::TestCase 
  def setup
    @entry = BioPieces::Seq.new(seq: "AtacCGactGAtacACGTAC")
  end

  test "#to_kmers without argument raises" do
    assert_raise(ArgumentError) { @entry.to_kmers() }
  end

  test "#to_kmers without :kmer_size raises" do
    assert_raise(BioPieces::KmerError) { @entry.to_kmers(step_size: 1) }
  end

  test "#to_kmers with bad :kmer_size raises" do
    assert_raise(BioPieces::KmerError) { @entry.to_kmers(kmer_size: 0) }
    assert_raise(BioPieces::KmerError) { @entry.to_kmers(kmer_size: 13) }
  end

  test "#to_kmers with OK :kmer_size don't raise" do
    assert_nothing_raised { @entry.to_kmers(kmer_size: 1) }
    assert_nothing_raised { @entry.to_kmers(kmer_size: 12) }
  end

  test "#to_kmers with bad :step_size raises" do
    assert_raise(BioPieces::KmerError) { @entry.to_kmers(kmer_size: 8, step_size: 0) }
    assert_raise(BioPieces::KmerError) { @entry.to_kmers(kmer_size: 8, step_size: 13) }
  end

  test "#to_kmers with OK :step_size don't raise" do
    assert_nothing_raised { @entry.to_kmers(kmer_size: 8, step_size: 1) }
    assert_nothing_raised { @entry.to_kmers(kmer_size: 8, step_size: 12) }
  end

  test "#to_kmers with bad :score_min raises" do
    @entry.qual = "IIIIIIIII!IIIIIIIIII"
    assert_raise(BioPieces::KmerError) { @entry.to_kmers(kmer_size: 8, score_min: -1) }
    assert_raise(BioPieces::KmerError) { @entry.to_kmers(kmer_size: 8, score_min: 41) }
  end

  test "#to_kmers with OK :score_min don't raise" do
    @entry.qual = "IIIIIIIII!IIIIIIIIII"
    assert_nothing_raised { @entry.to_kmers(kmer_size: 8, score_min: 0) }
    assert_nothing_raised { @entry.to_kmers(kmer_size: 8, score_min: 40) }
  end
end
