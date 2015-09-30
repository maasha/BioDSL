#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..')

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
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
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for Mummer.
class TestMummer < Test::Unit::TestCase
  def setup
    omit('mummer not found') unless BioPieces::Filesys.which('mummer')

    @entry1 = BioPieces::Seq.new(seq_name: 'test1', seq: 'ctagcttcaacctagctag')
    @entry2 = BioPieces::Seq.new(seq_name: 'test2', seq: 'ctagcttcaGacctagctag')
  end

  test 'Mummer.each_mem with bad :length_min fails' do
    assert_raise(BioPieces::MummerError) do
      BioPieces::Mummer.each_mem(@entry1, @entry2, length_min: 0)
    end

    assert_raise(BioPieces::MummerError) do
      BioPieces::Mummer.each_mem(@entry1, @entry2, length_min: 5.5)
    end
  end

  test 'Mummer.each_mem with bad :direction fails' do
    assert_raise(BioPieces::MummerError) do
      BioPieces::Mummer.each_mem(@entry1, @entry2, direction: 'up')
    end
  end

  test 'Mummer#each_mem returns OK' do
    mems     = BioPieces::Mummer.each_mem(@entry1, @entry2, length_min: 9)
    expected = <<-END.gsub(/^\s+\|/, '')
      |[#<struct BioPieces::Mummer::Match
      |  q_id="test2",
      |  s_id="test1",
      |  dir="forward",
      |  s_beg=0,
      |  q_beg=0,
      |  hit_len=9>,
      | #<struct BioPieces::Mummer::Match
      |  q_id="test2",
      |  s_id="test1",
      |  dir="forward",
      |  s_beg=9,
      |  q_beg=10,
      |  hit_len=10>]
    END

    assert_equal(Enumerator, mems.class)
    assert_equal(expected.gsub("\n", '').gsub('  ', ' '), mems.to_a.to_s)
  end
end
