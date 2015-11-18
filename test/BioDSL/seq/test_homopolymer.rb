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

# Test class for Homopolymer.
class TestHomopolymer < Test::Unit::TestCase
  def setup
    @entry = BioDSL::Seq.new(seq: 'atcgatTTTTTTcggttga')
  end

  test '#each_homopolymer with bad min raises' do
    assert_raise(BioDSL::HomopolymerError) { @entry.each_homopolymer(0) }
    assert_raise(BioDSL::HomopolymerError) { @entry.each_homopolymer(-1) }
  end

  test '#each_homopolymer returns correctly' do
    hps = @entry.each_homopolymer(3)
    assert_equal(1, hps.size)
    assert_equal(7, hps.first.length)
    assert_equal('TTTTTTT', hps.first.pattern)
    assert_equal(5, hps.first.pos)
  end

  test '#each_homopolymer in block context returns correctly' do
    @entry.each_homopolymer(3) do |hp|
      assert_equal(7, hp.length)
      assert_equal('TTTTTTT', hp.pattern)
      assert_equal(5, hp.pos)
      break
    end
  end
end
