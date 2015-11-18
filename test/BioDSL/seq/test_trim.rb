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
# This software is part of BioDSL (www.BioDSL.org).                            #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for Trim.
class TestTrim < Test::Unit::TestCase
  def setup
    @entry      = BioDSL::Seq.new
    #                2         3         44         3         2
    #              8901234567890123456789009876543210987654321098
    @entry.qual = '3456789:;<=>?@3BCDEFGHIIHGFEDCB3@?>=<;:9876543'
    @entry.seq  = 'abcdefghijklmnopqrstuvxxvutsrqponmlkjihgfedcba'
  end

  test '#quality_trim with nil seq raises' do
    @entry.seq = nil
    assert_raise(BioDSL::TrimError) { @entry.quality_trim(20, 1) }
  end

  test '#quality_trim with nil qual raises' do
    @entry.qual = nil
    assert_raise(BioDSL::TrimError) { @entry.quality_trim(20, 1) }
  end

  test '#quality_trim with bad min_qual raises' do
    assert_raise(BioDSL::TrimError) { @entry.quality_trim(-1, 1) }
    assert_raise(BioDSL::TrimError) { @entry.quality_trim(41, 1) }
  end

  test '#quality_trim with bad min_len raises' do
    assert_raise(BioDSL::TrimError) { @entry.quality_trim(20, 0) }
  end

  test '#quality_trim returns correctly' do
    trimmed = @entry.quality_trim(30, 3)
    assert_equal('pqrstuvxxvutsrqp', trimmed.seq)
    assert_equal('BCDEFGHIIHGFEDCB', trimmed.qual)
    assert_equal('abcdefghijklmnopqrstuvxxvutsrqponmlkjihgfedcba', @entry.seq)
    assert_equal('3456789:;<=>?@3BCDEFGHIIHGFEDCB3@?>=<;:9876543', @entry.qual)
  end

  test '#quality_trim! returns correctly' do
    @entry.quality_trim!(30, 3)
    assert_equal('pqrstuvxxvutsrqp', @entry.seq)
    assert_equal('BCDEFGHIIHGFEDCB', @entry.qual)
  end

  test '#quality_trim_left returns correctly' do
    trimmed = @entry.quality_trim_left(30, 3)
    assert_equal('pqrstuvxxvutsrqponmlkjihgfedcba', trimmed.seq)
    assert_equal('BCDEFGHIIHGFEDCB3@?>=<;:9876543', trimmed.qual)
    assert_equal('abcdefghijklmnopqrstuvxxvutsrqponmlkjihgfedcba', @entry.seq)
    assert_equal('3456789:;<=>?@3BCDEFGHIIHGFEDCB3@?>=<;:9876543', @entry.qual)
  end

  test '#quality_trim_left! returns correctly' do
    @entry.quality_trim_left!(30, 3)
    assert_equal('pqrstuvxxvutsrqponmlkjihgfedcba', @entry.seq)
    assert_equal('BCDEFGHIIHGFEDCB3@?>=<;:9876543', @entry.qual)
  end

  test '#quality_trim_rigth returns correctly' do
    trimmed = @entry.quality_trim_right(30, 3)
    assert_equal('abcdefghijklmnopqrstuvxxvutsrqpo', trimmed.seq)
    assert_equal('3456789:;<=>?@3BCDEFGHIIHGFEDCB3', trimmed.qual)
    assert_equal('abcdefghijklmnopqrstuvxxvutsrqponmlkjihgfedcba', @entry.seq)
    assert_equal('3456789:;<=>?@3BCDEFGHIIHGFEDCB3@?>=<;:9876543', @entry.qual)
  end

  test '#quality_trim_right! returns correctly' do
    @entry.quality_trim_right!(30, 3)
    assert_equal('abcdefghijklmnopqrstuvxxvutsrqpo', @entry.seq)
    assert_equal('3456789:;<=>?@3BCDEFGHIIHGFEDCB3', @entry.qual)
  end
end
