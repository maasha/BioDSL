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

class TestTranslate < Test::Unit::TestCase 
  def setup
    @entry = BioPieces::Seq.new(seq: "atcgatcgatcgtacggttga", type: :dna)
  end

  test "#tranlate with bad type raises" do
    @entry.type = nil
    assert_raise(BioPieces::SeqError) { @entry.translate }
  end

  test "#tranlate with bad length raises" do
    @entry.seq = "atcgatcgatcgtacggtga"
    assert_raise(BioPieces::SeqError) { @entry.translate }
  end

  test "#tranlate with bad translation table raises" do
    @entry.seq = "atcgatcgatcgtacggttga"
    assert_raise(BioPieces::SeqError) { @entry.translate(0) }
  end

  test "#tranlate with bad start codon raises" do
    @entry.seq = "ttagatcgatcgtacggttga"
    assert_raise(BioPieces::SeqError) { @entry.translate }
  end

  test "#tranlate with bad codon raises" do
    @entry.seq = "atggatcgaxxxtcgtacggttga"
    assert_raise(BioPieces::SeqError) { @entry.translate }
  end

  test "#tranlate returns correctly" do
    entry = @entry.translate
    assert_equal("MDRSYG", entry.seq)
    assert_equal(:protein, entry.type)
    assert_equal("atcgatcgatcgtacggttga", @entry.seq)
    assert_equal(:dna, @entry.type)
  end

  test "#tranlate! returns correctly" do
    @entry.translate!
    assert_equal("MDRSYG", @entry.seq)
    assert_equal(:protein, @entry.type)
  end
end
