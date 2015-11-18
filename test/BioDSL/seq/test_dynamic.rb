#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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
# This software is part of BioDSL (http://maasha.github.io/BioDSL).            #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for Dynamic.
class TestDynamic < Test::Unit::TestCase
  def setup
    @p = BioDSL::Seq.new(seq_name: 'test', seq: 'atcg')
    @p.extend(BioDSL::Dynamic)
  end

  test '#patmatch with no match returns nil' do
    assert_nil(@p.patmatch('gggg'))
  end

  test '#patmatch with perfect match returns correctly' do
    m = @p.patmatch('atcg')
    assert_equal(0, m.beg)
    assert_equal('atcg', m.match)
    assert_equal(0, m.mis)
    assert_equal(0, m.ins)
    assert_equal(0, m.del)
    assert_equal(4, m.length)
  end

  test '#patmatch with perfect match with ambiguity codes returns correctly' do
    m = @p.patmatch('nnnn')
    assert_equal(0, m.beg)
    assert_equal('atcg', m.match)
    assert_equal(0, m.mis)
    assert_equal(0, m.ins)
    assert_equal(0, m.del)
    assert_equal(4, m.length)
  end

  test '#patmatch with one mismatch and edit dist zero returns nil' do
    assert_nil(@p.patmatch('aCcg'))
  end

  test '#patmatch with one mismatch and edit dist one returns correctly' do
    m = @p.patmatch('aCcg', 0, 1)
    assert_equal(0, m.beg)
    assert_equal('atcg', m.match)
    assert_equal(1, m.mis)
    assert_equal(0, m.ins)
    assert_equal(0, m.del)
    assert_equal(4, m.length)
  end

  test '#patmatch with two mismatch and edit dist one returns nil' do
    assert_nil(@p.patmatch('aGcA', 0, 1))
  end

  test '#patmatch with one insertion and edit dist zero returns nil' do
    assert_nil(@p.patmatch('atGcg'))
  end

  test '#patmatch with one insertion and edit dist one returns correctly' do
    m = @p.patmatch('atGcg', 0, 1)
    assert_equal(0, m.beg)
    assert_equal('atcg', m.match)
    assert_equal(0, m.mis)
    assert_equal(1, m.ins)
    assert_equal(0, m.del)
    assert_equal(4, m.length)
  end

  test '#patmatch with two insertions and edit dist one returns nil' do
    assert_nil(@p.patmatch('atGcTg', 0, 1))
  end

  test '#patmatch with two insertions and edit dist two returns correctly' do
    m = @p.patmatch('atGcTg', 0, 2)
    assert_equal(0, m.beg)
    assert_equal('atcg', m.match)
    assert_equal(0, m.mis)
    assert_equal(2, m.ins)
    assert_equal(0, m.del)
    assert_equal(4, m.length)
  end

  test '#patmatch with one deletion and edit distance zero returns nil' do
    assert_nil(@p.patmatch('acg'))
  end

  test '#patmatch with one deletion and edit distance one returns correctly' do
    m = @p.patmatch('acg', 0, 1)
    assert_equal(0, m.beg)
    assert_equal('atcg', m.match)
    assert_equal(0, m.mis)
    assert_equal(0, m.ins)
    assert_equal(1, m.del)
    assert_equal(4, m.length)
  end

  test '#patscan locates three patterns ok' do
    p = BioDSL::Seq.new(seq_name: 'test', seq: 'ataacgagctagctagctagctgactac')
    p.extend(BioDSL::Dynamic)
    assert_equal(3, p.patscan('tag').count)
  end

  test '#patscan with pos locates two patterns ok' do
    p = BioDSL::Seq.new(seq_name: 'test', seq: 'ataacgagctagctagctagctgactac')
    p.extend(BioDSL::Dynamic)
    assert_equal(2, p.patscan('tag', 10).count)
  end
end
