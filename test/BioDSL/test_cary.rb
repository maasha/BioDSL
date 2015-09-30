#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..')

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
# This software is part of BioDSL (www.BioDSL.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

# rubocop: disable ClassLength

require 'test/helper'

# Test class for CAry.
class TestCAry < Test::Unit::TestCase
  test 'BioDSL::CAry.new with bad count raises' do
    assert_raise(BioDSL::CAryError) { BioDSL::CAry.new(-10, 4) }
    assert_raise(BioDSL::CAryError) { BioDSL::CAry.new(0, 4) }
  end

  test 'BioDSL::CAry.new with bad size raises' do
    assert_raise(BioDSL::CAryError) { BioDSL::CAry.new(10, -4) }
    assert_raise(BioDSL::CAryError) { BioDSL::CAry.new(10, 0) }
  end

  test 'BioDSL::CAry.to_s returns correctly' do
    assert_equal('0' * 40, BioDSL::CAry.new(5, 1).to_s)
  end

  test 'BioDSL::CAry.new with ary returns correctly' do
    assert_equal([1, 2].pack('I*').unpack('B*').first,
                 BioDSL::CAry.new(2, 4, [1, 2].pack('I*')).to_s)
  end

  test 'BioDSL::CAry.fill! returns correctly' do
    cary = BioDSL::CAry.new(5, 1)
    cary.fill!
    assert_equal('1' * 40, cary.to_s)
  end

  test 'BioDSL::CAry.fill returns correctly' do
    cary = BioDSL::CAry.new(5, 1)
    new = cary.fill
    assert_equal('0' * 40, cary.to_s)
    assert_equal('1' * 40, new.to_s)
  end

  test 'BioDSL::CAry.zero! returns correctly' do
    cary = BioDSL::CAry.new(5, 1).fill
    cary.zero!
    assert_equal('0' * 40, cary.to_s)
  end

  test 'BioDSL::CAry.zero returns correctly' do
    cary = BioDSL::CAry.new(5, 1).fill
    new  = cary.zero
    assert_equal('1' * 40, cary.to_s)
    assert_equal('0' * 40, new.to_s)
  end

  test 'BioDSL::CAry.& raises with bad object type' do
    cary = BioDSL::CAry.new(5, 1)
    assert_raise(BioDSL::CAryError) { cary & 10 }
  end

  test 'BioDSL::CAry.& raises with uneven counts' do
    cary1 = BioDSL::CAry.new(5, 1)
    cary2 = BioDSL::CAry.new(4, 1)
    assert_raise(BioDSL::CAryError) { cary1 & cary2 }
  end

  test 'BioDSL::CAry.& raises with uneven sizes' do
    cary1 = BioDSL::CAry.new(5, 1)
    cary2 = BioDSL::CAry.new(5, 2)
    assert_raise(BioDSL::CAryError) { cary1 & cary2 }
  end

  test 'BioDSL::CAry.& returns correctly' do
    cary1 = BioDSL::CAry.new(5, 1).fill
    cary2 = BioDSL::CAry.new(5, 1).fill

    cary1 & cary2

    assert_equal('1' * 40, cary1.to_s)
    assert_equal('1' * 40, cary1.to_s)
  end

  test 'BioDSL::CAry.| raises with bad object type' do
    cary = BioDSL::CAry.new(5, 1)
    assert_raise(BioDSL::CAryError) { cary | 10 }
  end

  test 'BioDSL::CAry.| raises with uneven counts' do
    cary1 = BioDSL::CAry.new(5, 1)
    cary2 = BioDSL::CAry.new(4, 1)
    assert_raise(BioDSL::CAryError) { cary1 | cary2 }
  end

  test 'BioDSL::CAry.| raises with uneven sizes' do
    cary1 = BioDSL::CAry.new(5, 1)
    cary2 = BioDSL::CAry.new(5, 2)
    assert_raise(BioDSL::CAryError) { cary1 | cary2 }
  end

  test 'BioDSL::CAry.| returns correctly' do
    cary1 = BioDSL::CAry.new(5, 1)
    cary2 = BioDSL::CAry.new(5, 1).fill

    cary1 | cary2

    assert_equal('1' * 40, cary1.to_s)
    assert_equal('1' * 40, cary2.to_s)
  end

  test 'BioDSL::CAry.^ raises with bad object type' do
    cary = BioDSL::CAry.new(5, 1)
    assert_raise(BioDSL::CAryError) { cary ^ 10 }
  end

  test 'BioDSL::CAry.^ raises with uneven counts' do
    cary1 = BioDSL::CAry.new(5, 1)
    cary2 = BioDSL::CAry.new(4, 1)
    assert_raise(BioDSL::CAryError) { cary1 ^ cary2 }
  end

  test 'BioDSL::CAry.^ raises with uneven sizes' do
    cary1 = BioDSL::CAry.new(5, 1)
    cary2 = BioDSL::CAry.new(5, 2)
    assert_raise(BioDSL::CAryError) { cary1 ^ cary2 }
  end

  test 'BioDSL::CAry.^ returns correctly' do
    cary1 = BioDSL::CAry.new(5, 1)
    cary2 = BioDSL::CAry.new(5, 1).fill

    cary1 ^ cary2

    assert_equal('1' * 40, cary1.to_s)
    assert_equal('1' * 40, cary2.to_s)
  end

  test 'BioDSL::CAry #store and #retrieve returns correctly' do
    file = Tempfile.new('cary')
    cary = BioDSL::CAry.new(5, 1).fill

    begin
      BioDSL::CAry.store(file, cary)
      cary2 = BioDSL::CAry.retrieve(file)
      assert_equal(cary.to_s, cary2.to_s)
    ensure
      file.close
      file.unlink
    end
  end
end
