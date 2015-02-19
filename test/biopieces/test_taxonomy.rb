#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

class TestTaxonomy < Test::Unit::TestCase 
  def setup
    @index = BioPieces::Taxonomy::Index.new(kmer_size: 3, step_size: 1)
  end

  test "BioPieces::Taxonomy#add with bad header with wrong number of tax levels raises" do
    assert_raise(BioPieces::TaxonomyError) { @index.add(BioPieces::Seq.new(seq_name: "K#1;P#2", seq: "aaga")) }
  end

  test "BioPieces::Taxonomy#add with bad header with wrong tax order raises" do
    assert_raise(BioPieces::TaxonomyError) { @index.add(BioPieces::Seq.new(seq_name: "K#1;C#;P#3;O#;F#;G#;S#", seq: "aaga")) }
  end

  test "BioPieces::Taxonomy#add with bad header with gapped info raises" do
    assert_raise(BioPieces::TaxonomyError) { @index.add(BioPieces::Seq.new(seq_name: "K#1;P#;C#3;O#;F#;G#;S#", seq: "aaga")) }
  end

  test "BioPieces::Taxonomy#add with OK header don't raise" do
    assert_nothing_raised { @index.add(BioPieces::Seq.new(seq_name: "K#;P#;C#;O#;F#;G#;S#", seq: "aaga")) }
    assert_nothing_raised { @index.add(BioPieces::Seq.new(seq_name: "K#1;P#2;C#3;O#4;F#5;G#6;S#7", seq: "aaga")) }
  end

  test "BioPieces::Taxonomy#add with empty tree returns correctly" do
    assert_equal(1, @index.size)
    @index.add(BioPieces::Seq.new(seq_name: "K#1;P#2;C#3;O#;F#;G#;S#", seq: "aaga"))
    assert_equal(4, @index.size)
    assert_equal("root", @index.get_node(0).name)
    assert_equal("1", @index.get_node(1).name)
    assert_equal("2", @index.get_node(2).name)
    assert_equal("3", @index.get_node(3).name)
  end
end
