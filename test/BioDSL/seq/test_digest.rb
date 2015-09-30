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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

class TestDigest < Test::Unit::TestCase
  def setup
    @entry = BioPieces::Seq.new(seq: "cgatcgatcGGATCCgagagggtgtgtagtgGAATTCcgctgc")
  end

  test "#each_digest with bad residue in pattern raises" do
    assert_raise(BioPieces::DigestError) { @entry.each_digest("X", 0).to_a }
  end

  test "#each_digest returns correctly" do
    digests = @entry.each_digest("GGATCC", 1).to_a
    assert_equal(2, digests.size)
    assert_equal("[0-9]", digests.first.seq_name)
    assert_equal("cgatcgatcG", digests.first.seq)
    assert_equal("[10-42]", digests.last.seq_name)
    assert_equal("GATCCgagagggtgtgtagtgGAATTCcgctgc", digests.last.seq)
  end

  test "#each_digest with negavive offset returns correctly" do
    digests = @entry.each_digest("CGATCG", -1).to_a
    assert_equal(1, digests.size)
    assert_equal("[0-42]", digests.first.seq_name)
    assert_equal(@entry.seq, digests.first.seq)
  end

  test "#each_digest with offset out of bounds returns correctly" do
    digests = @entry.each_digest("AATTCcgctgc", 15).to_a
    assert_equal(1, digests.size)
    assert_equal("[0-42]", digests.first.seq_name)
    assert_equal(@entry.seq, digests.first.seq)
  end

  test "#each_digest in block context returns correctly" do
    @entry.each_digest("GGATCC", 1) do |digest|
      assert_equal("[0-9]", digest.seq_name)
      assert_equal("cgatcgatcG", digest.seq)
      break
    end
  end
end
