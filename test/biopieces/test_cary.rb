#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

class TestCAry < Test::Unit::TestCase 
  test "BioPieces::CAry.new with bad count raises" do
    assert_raise(BioPieces::CAryError) { BioPieces::CAry.new(-10, 4) }
    assert_raise(BioPieces::CAryError) { BioPieces::CAry.new(0, 4) }
  end

  test "BioPieces::CAry.new with bad size raises" do
    assert_raise(BioPieces::CAryError) { BioPieces::CAry.new(10, -4) }
    assert_raise(BioPieces::CAryError) { BioPieces::CAry.new(10, 0) }
  end

  test "BioPieces::CAry.to_s returns correctly" do
    assert_equal("0" * 40, BioPieces::CAry.new(5, 1).to_s)
  end

  test "BioPieces::CAry.new with ary returns correctly" do
    assert_equal([1,2].pack("I*").unpack("B*").first, BioPieces::CAry.new(2, 4, [1,2].pack("I*")).to_s)
  end

  test "BioPieces::CAry.fill! returns correctly" do
    cary = BioPieces::CAry.new(5, 1)
    cary.fill!
    assert_equal("1" * 40, cary.to_s)
  end

  test "BioPieces::CAry.fill returns correctly" do
    cary = BioPieces::CAry.new(5, 1)
    new = cary.fill
    assert_equal("0" * 40, cary.to_s)
    assert_equal("1" * 40, new.to_s)
  end

  test "BioPieces::CAry.zero! returns correctly" do
    cary = BioPieces::CAry.new(5, 1).fill
    cary.zero!
    assert_equal("0" * 40, cary.to_s)
  end

  test "BioPieces::CAry.zero returns correctly" do
    cary = BioPieces::CAry.new(5, 1).fill
    new  = cary.zero
    assert_equal("1" * 40, cary.to_s)
    assert_equal("0" * 40, new.to_s)
  end

  test "BioPieces::CAry.& raises with bad object type" do
    cary = BioPieces::CAry.new(5, 1)
    assert_raise(BioPieces::CAryError) { cary & 10 }
  end

  test "BioPieces::CAry.& raises with uneven counts" do
    cary1 = BioPieces::CAry.new(5, 1)
    cary2 = BioPieces::CAry.new(4, 1)
    assert_raise(BioPieces::CAryError) { cary1 & cary2 }
  end

  test "BioPieces::CAry.& raises with uneven sizes" do
    cary1 = BioPieces::CAry.new(5, 1)
    cary2 = BioPieces::CAry.new(5, 2)
    assert_raise(BioPieces::CAryError) { cary1 & cary2 }
  end

  test "BioPieces::CAry.& returns correctly" do
    cary1 = BioPieces::CAry.new(5, 1).fill
    cary2 = BioPieces::CAry.new(5, 1).fill

    cary1 & cary2

    assert_equal("1" * 40, cary1.to_s)
    assert_equal("1" * 40, cary1.to_s)
  end

  test "BioPieces::CAry.| raises with bad object type" do
    cary = BioPieces::CAry.new(5, 1)
    assert_raise(BioPieces::CAryError) { cary | 10 }
  end

  test "BioPieces::CAry.| raises with uneven counts" do
    cary1 = BioPieces::CAry.new(5, 1)
    cary2 = BioPieces::CAry.new(4, 1)
    assert_raise(BioPieces::CAryError) { cary1 | cary2 }
  end

  test "BioPieces::CAry.| raises with uneven sizes" do
    cary1 = BioPieces::CAry.new(5, 1)
    cary2 = BioPieces::CAry.new(5, 2)
    assert_raise(BioPieces::CAryError) { cary1 | cary2 }
  end

  test "BioPieces::CAry.| returns correctly" do
    cary1 = BioPieces::CAry.new(5, 1)
    cary2 = BioPieces::CAry.new(5, 1).fill

    cary1 | cary2

    assert_equal("1" * 40, cary1.to_s)
    assert_equal("1" * 40, cary2.to_s)
  end

  test "BioPieces::CAry.^ raises with bad object type" do
    cary = BioPieces::CAry.new(5, 1)
    assert_raise(BioPieces::CAryError) { cary ^ 10 }
  end

  test "BioPieces::CAry.^ raises with uneven counts" do
    cary1 = BioPieces::CAry.new(5, 1)
    cary2 = BioPieces::CAry.new(4, 1)
    assert_raise(BioPieces::CAryError) { cary1 ^ cary2 }
  end

  test "BioPieces::CAry.^ raises with uneven sizes" do
    cary1 = BioPieces::CAry.new(5, 1)
    cary2 = BioPieces::CAry.new(5, 2)
    assert_raise(BioPieces::CAryError) { cary1 ^ cary2 }
  end

  test "BioPieces::CAry.^ returns correctly" do
    cary1 = BioPieces::CAry.new(5, 1)
    cary2 = BioPieces::CAry.new(5, 1).fill

    cary1 ^ cary2

    assert_equal("1" * 40, cary1.to_s)
    assert_equal("1" * 40, cary2.to_s)
  end

  test "BioPieces::CAry #store and #retrieve returns correctly" do
    file = Tempfile.new('cary')
    cary = BioPieces::CAry.new(5, 1).fill

    begin
      BioPieces::CAry.store(file, cary)
      cary2 = BioPieces::CAry.retrieve(file)
      assert_equal(cary.to_s, cary2.to_s)
    ensure
      file.close
      file.unlink
    end
  end
end

