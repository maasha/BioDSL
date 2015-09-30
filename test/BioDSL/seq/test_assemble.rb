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
# This software is part of BioDSL (www.BioDSL.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

class TestAssemble < Test::Unit::TestCase 
  def setup
    @entry1 = BioDSL::Seq.new(seq: "ttttttttttATCTCGC")
    @entry2 = BioDSL::Seq.new(seq: "naTCTCGgaaaaaaaaa")
  end

  test "#assemble with bad mismatches_max raises" do
    assert_raise(BioDSL::AssembleError) { BioDSL::Assemble.pair(@entry1, @entry2, mismatches_max: -1) }
  end

  test "#assemble with bad overlap_max raises" do
    assert_raise(BioDSL::AssembleError) { BioDSL::Assemble.pair(@entry1, @entry2, overlap_max: 0) }
  end

  test "#assemble with bad overlap_min raises" do
    assert_raise(BioDSL::AssembleError) { BioDSL::Assemble.pair(@entry1, @entry2, overlap_min: 0) }
  end

  test "#assemble returns correctly" do
    assembly = BioDSL::Assemble.pair(@entry1, @entry2)
    assert_equal("ttttttttttatctcgCatctcggaaaaaaaaa", assembly.seq)
  end

  test "#assemble with uneven sequence length returns correctly" do
    @entry1.seq = "tttttttttATCTCGC"
    @entry2.seq = "naTCTCGgaaaaa"
    assembly = BioDSL::Assemble.pair(@entry1, @entry2)
    assert_equal("tttttttttatctcgCatctcggaaaaa", assembly.seq)
  end

  test "#assemble with subsequence returns correctly" do
    @entry1.seq = "tttttttttATCTCGC"
    @entry2.seq = "naTCTCG"
    assembly = BioDSL::Assemble.pair(@entry1, @entry2)
    assert_equal("ttttttttTATCTCGc", assembly.seq)
  end

  test "#assemble with seq_name returns correctly" do
    @entry1.seq_name = "foo"
    assembly = BioDSL::Assemble.pair(@entry1, @entry2)
    assert_equal("foo:overlap=1:hamming=0", assembly.seq_name)
    assert_equal("ttttttttttatctcgCatctcggaaaaaaaaa", assembly.seq)
  end

  test "#assemble with qual returns correctly" do
    @entry1.qual = "00000000000000000"
    @entry2.qual = "@@@@@@@@@@@@@@@@@"
    assembly = BioDSL::Assemble.pair(@entry1, @entry2)
    assert_equal("ttttttttttatctcgNatctcggaaaaaaaaa", assembly.seq)
    assert_equal("00000000000000008@@@@@@@@@@@@@@@@", assembly.qual)
  end

  test "#assemble with mismatches_max returns correctly" do
    assembly = BioDSL::Assemble.pair(@entry1, @entry2, mismatches_max: 10)
    assert_equal("tttttttttTATCTCGCaaaaaaaaa", assembly.seq)
  end

  test "#assemble with overlap_max returns correctly" do
    assembly = BioDSL::Assemble.pair(@entry1, @entry2, mismatches_max: 10, overlap_max: 7)
    assert_equal("ttttttttttatctcgCatctcggaaaaaaaaa", assembly.seq)
  end

  test "#assemble with overlap_min returns correctly" do
    assembly = BioDSL::Assemble.pair(@entry1, @entry2, mismatches_max: 10, overlap_min: 9)
    assert_nil(assembly)
  end
end
