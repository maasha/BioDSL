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

    @tmpdir = Dir.mktmpdir("Taxonomy")

    @index2 = BioPieces::Taxonomy::Index.new(kmer_size: 3, step_size: 1, output_dir: @tmpdir, prefix: "test")
    @index2.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#;O#;F#;G#;S#",  seq: "aaga"))
    @index2.add(BioPieces::Seq.new(seq_name: "K#b;P#f;C#;O#;F#;G#;S#",  seq: "aagu"))
    @index2.add(BioPieces::Seq.new(seq_name: "K#b;P#;C#;O#;F#;G#;S#",   seq: "aag"))
    @index2.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#g;O#;F#;G#;S#", seq: "aagag"))

    @tree_file = File.join(@tmpdir, "test_tax_index.dat")
    @kmer_file = File.join(@tmpdir, "test_kmer_index.dat")
  end

  def teardown
    FileUtils.rm_r @tmpdir
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

  # '00' then oligo << 'a'
  # '01' then oligo << 't'
  # '10' then oligo << 'c'
  # '11' then oligo << 'g'

  test "BioPieces::Taxonomy#add with empty tree returns correctly" do
    assert_equal(1, @index.size)
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#;O#;F#;G#;S#", seq: "aaga"))
    assert_equal(3,       @index.size)
    assert_equal("root",  @index.get_node(0).name)
    assert_equal("b",     @index.get_node(1).name)
    assert_equal("e",     @index.get_node(2).name)
    assert_equal([],      @index.get_node(0).kmers.to_a)
    assert_equal([],      @index.get_node(1).kmers.to_a)
    assert_equal([3, 12], @index.get_node(2).kmers.to_a) # AAG=000011=3, AGA=001100=12 
  end

  test "BioPieces::Taxonomy#add with edge split returns correctly" do
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#;O#;F#;G#;S#", seq: "aaga"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#f;C#;O#;F#;G#;S#", seq: "aagu"))
    assert_equal(4,       @index.size)
    assert_equal("root",  @index.get_node(0).name)
    assert_equal("b",     @index.get_node(1).name)
    assert_equal("e",     @index.get_node(2).name)
    assert_equal("f",     @index.get_node(3).name)
    assert_equal([],      @index.get_node(0).kmers.to_a)
    assert_equal([],      @index.get_node(1).kmers.to_a)
    assert_equal([3, 12], @index.get_node(2).kmers.to_a) # AAG=000011=3, AGA=001100=12 
    assert_equal([3, 13], @index.get_node(3).kmers.to_a) # AAG=000011=3, AGU=001101=13 
  end

  test "BioPieces::Taxonomy#add to existing non-leaf node returns correctly" do
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#;O#;F#;G#;S#", seq: "aaga"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#f;C#;O#;F#;G#;S#", seq: "aagu"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#;C#;O#;F#;G#;S#",  seq: "aag"))
    assert_equal(4,       @index.size)
    assert_equal("root",  @index.get_node(0).name)
    assert_equal("b",     @index.get_node(1).name)
    assert_equal("e",     @index.get_node(2).name)
    assert_equal("f",     @index.get_node(3).name)
    assert_equal([],      @index.get_node(0).kmers.to_a)
    assert_equal([3],     @index.get_node(1).kmers.to_a) # AAG=000011=3
    assert_equal([3, 12], @index.get_node(2).kmers.to_a) # AAG=000011=3, AGA=001100=12 
    assert_equal([3, 13], @index.get_node(3).kmers.to_a) # AAG=000011=3, AGU=001101=13 
  end

  test "BioPieces::Taxonomy#add exteding existing leaf node returns correctly" do
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#;O#;F#;G#;S#",  seq: "aaga"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#f;C#;O#;F#;G#;S#",  seq: "aagu"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#;C#;O#;F#;G#;S#",   seq: "aag"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#g;O#;F#;G#;S#", seq: "aagag"))
    assert_equal(5,           @index.size)
    assert_equal("root",      @index.get_node(0).name)
    assert_equal("b",         @index.get_node(1).name)
    assert_equal("e",         @index.get_node(2).name)
    assert_equal("f",         @index.get_node(3).name)
    assert_equal("g",         @index.get_node(4).name)
    assert_equal([],          @index.get_node(0).kmers.to_a.sort)
    assert_equal([3],         @index.get_node(1).kmers.to_a.sort) # AAG=000011=3
    assert_equal([3, 12],     @index.get_node(2).kmers.to_a.sort) # AAG=000011=3, AGA=001100=12 
    assert_equal([3, 13],     @index.get_node(3).kmers.to_a.sort) # AAG=000011=3, AGU=001101=13 
    assert_equal([3, 12, 51], @index.get_node(4).kmers.to_a.sort) # AAG=000011=3, AGA=001101=12, GAG=110011=51 
  end

  test "BioPieces::Taxonomy#tree_union returns correctly" do
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#;O#;F#;G#;S#",  seq: "aaga"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#f;C#;O#;F#;G#;S#",  seq: "aagu"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#;C#;O#;F#;G#;S#",   seq: "aag"))
    @index.add(BioPieces::Seq.new(seq_name: "K#b;P#e;C#g;O#;F#;G#;S#", seq: "aagag"))
    @index.tree_union
    assert_equal(5,               @index.size)
    assert_equal("root",          @index.get_node(0).name)
    assert_equal("b",             @index.get_node(1).name)
    assert_equal("e",             @index.get_node(2).name)
    assert_equal("f",             @index.get_node(3).name)
    assert_equal("g",             @index.get_node(4).name)
    assert_equal([3, 12, 13, 51], @index.get_node(0).kmers.to_a.sort)
    assert_equal([3, 12, 13, 51], @index.get_node(1).kmers.to_a.sort)
    assert_equal([3, 12, 51],     @index.get_node(2).kmers.to_a.sort)
    assert_equal([3, 13],         @index.get_node(3).kmers.to_a.sort)
    assert_equal([3, 12, 51],     @index.get_node(4).kmers.to_a.sort)
  end

  test "BioPieces::Taxonomy#save outputs correct tax tree inxex" do
    @index2.save

    expected = <<EOD
#SEQ_ID\tNODE_ID\tLEVEL\tNAME\tPARENT_ID
\t0\tr\troot\t
0\t1\tk\tb\t0
1\t3\tp\tf\t1
0\t2\tp\te\t1
3\t4\tc\tg\t2
EOD

    assert_equal(expected, File.read(@tree_file))
  end

  # r             0
  #             /
  # k          1
  #          /   \
  # p       2     3
  #       /
  # c    4
  #
  # node 0 - [3, 12, 13, 51]
  # node 1 - [3, 12, 13, 51]
  # node 2 - [3, 12, 51]
  # node 3 - [3, 13]
  # node 4 - [3, 12, 51]
  test "BioPieces::Taxonomy#save outputs correct kmer index" do
    @index2.save

    expected = <<EOD
#LEVEL\tKMER\tNODES
r\t3\t0
r\t12\t0
r\t13\t0
r\t51\t0
k\t3\t1
k\t12\t1
k\t13\t1
k\t51\t1
p\t3\t2;3
p\t12\t2
p\t13\t3
p\t51\t2
c\t3\t4
c\t12\t4
c\t51\t4
EOD

    assert_equal(expected, File.read(@kmer_file))
  end
end
