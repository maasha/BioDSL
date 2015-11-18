#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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
# This software is part of BioDSL (www.BioDSL.org).                              #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

class TestKmer < Test::Unit::TestCase 
  def setup
    @entry = BioDSL::Seq.new(seq: "aNacCGactGAtacACGTAC")
  end

  test "#to_kmers without argument raises" do
    assert_raise(ArgumentError) { @entry.to_kmers() }
  end

  test "#to_kmers without :kmer_size raises" do
    assert_raise(BioDSL::KmerError) { @entry.to_kmers(step_size: 1) }
  end

  test "#to_kmers with bad :kmer_size raises" do
    assert_raise(BioDSL::KmerError) { @entry.to_kmers(kmer_size: 0) }
    assert_raise(BioDSL::KmerError) { @entry.to_kmers(kmer_size: 13) }
  end

  test "#to_kmers with OK :kmer_size don't raise" do
    assert_nothing_raised { @entry.to_kmers(kmer_size: 1) }
    assert_nothing_raised { @entry.to_kmers(kmer_size: 12) }
  end

  test "#to_kmers with bad :step_size raises" do
    assert_raise(BioDSL::KmerError) { @entry.to_kmers(kmer_size: 8, step_size: 0) }
    assert_raise(BioDSL::KmerError) { @entry.to_kmers(kmer_size: 8, step_size: 13) }
  end

  test "#to_kmers with OK :step_size don't raise" do
    assert_nothing_raised { @entry.to_kmers(kmer_size: 8, step_size: 1) }
    assert_nothing_raised { @entry.to_kmers(kmer_size: 8, step_size: 12) }
  end

  test "#to_kmers with bad :score_min raises" do
    @entry.qual = "IIIIIIIII!IIIIIIIIII"
    assert_raise(BioDSL::KmerError) { @entry.to_kmers(kmer_size: 8, score_min: -1) }
    assert_raise(BioDSL::KmerError) { @entry.to_kmers(kmer_size: 8, score_min: 41) }
  end

  test "#to_kmers with OK :score_min don't raise" do
    @entry.qual = "IIIIIIIII!IIIIIIIIII"
    assert_nothing_raised { @entry.to_kmers(kmer_size: 8, score_min: 0) }
    assert_nothing_raised { @entry.to_kmers(kmer_size: 8, score_min: 40) }
  end

  test "#to_kmers with kmer_size: 1 returns correctly" do
    result = @entry.to_kmers(kmer_size: 1)
    expected = [0, 1, 2, 3]
    assert_equal(expected, result)
  end

  test "#to_kmers with kmer_size: 1 and step_size: 2 returns correctly" do
    result = @entry.to_kmers(kmer_size: 1, step_size: 2)
    expected = [0, 1, 2, 3]
    assert_equal(expected, result)
  end

  test "#to_kmers with kmer_size: 5 returns correctly" do
    result = @entry.to_kmers(kmer_size: 5)
    expected = [72, 139, 156, 172, 180, 290, 452, 557, 625, 690, 713, 722, 786, 807]
    assert_equal(expected, result)
  end

  test "#to_kmers with kmer_size: 5 and step_size: 2 returns correctly" do
    result = @entry.to_kmers(kmer_size: 5, step_size: 2)
    expected = [72, 139, 156, 172, 180, 452, 713]
    assert_equal(expected, result)
  end

  test "#to_kmers with kmer_size: 1 and score_min: 20 returns correctly" do
    @entry.qual = "IIIIIIIII!IIIIIIIIII"
    result = @entry.to_kmers(kmer_size: 1, scores_min: 20)
    expected = [0, 1, 2, 3]
    assert_equal(expected, result)
  end

  test "#to_kmers with kmer_size: 1 and score_min: 20 and step_size: 2 returns correctly" do
    @entry.qual = "IIIIIIIII!IIIIIIIIII"
    result = @entry.to_kmers(kmer_size: 1, scores_min: 20, step_size: 2)
    expected = [0, 1, 2, 3]
    assert_equal(expected, result)
  end

  test "#to_kmers with kmer_size: 5 and score_min: 20 returns correctly" do
    @entry.qual = "IIIIIIIII!IIIIIIIIII"
    result = @entry.to_kmers(kmer_size: 5, scores_min: 20)
    expected = [72, 139, 172, 180, 290, 557, 690, 713, 722]
    assert_equal(expected, result)
  end

  test "#to_kmers with kmer_size: 5 and score_min: 20 and step_size: 2 returns correctly" do
    @entry.qual = "IIIIIIIII!IIIIIIIIII"
    result = @entry.to_kmers(kmer_size: 5, scores_min: 20, step_size: 2)
    expected = [72, 139, 172, 180, 713]
    assert_equal(expected, result)
  end

  test "Kmer#to_oligos return correctly" do
    kmers = @entry.to_kmers(kmer_size: 5)
    result = %w{ataca acacg actga accga acgta tacac tgata cacgt ctgat ccgac cgact cgtac gatac gactg}
    assert_equal(result, BioDSL::Kmer.to_oligos(kmers, 5))
  end
end
