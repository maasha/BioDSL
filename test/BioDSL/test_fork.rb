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
# This software is part of BioDSL (www.BioDSL.org).                            #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

class TestFork < Test::Unit::TestCase
  def setup
    @obj = {foo: "bar"}
  end

  test "BioDSL::Fork.new without block raises" do
    assert_raise(ArgumentError) { BioDSL::Fork.new }
  end

  test "BioDSL::Fork.read with no running fork raises" do
    parent = BioDSL::Fork.new do |child|
    end

    assert_raise(BioDSL::ForkError) { parent.read }
  end

  test "BioDSL::Fork.write with no running fork raises" do
    parent = BioDSL::Fork.new do |child|
    end

    assert_raise(BioDSL::ForkError) { parent.write @obj }
  end

  test "BioDSL::Fork.wait with no running fork raises" do
    parent = BioDSL::Fork.new do |child|
    end

    assert_raise(BioDSL::ForkError) { parent.wait }
  end

  test "BioDSL::Fork.wait with running fork don't raise" do
    parent = BioDSL::Fork.execute do |child|
    end

    assert_nothing_raised { parent.wait }
  end

  test "BioDSL::Fork IPC returns correctly" do
    parent = BioDSL::Fork.execute do |child|
      obj = child.read
      obj[:child] = true
      child.write obj
    end

    parent.write @obj
    parent.output.close

    result = parent.read

    parent.wait

    assert_equal({foo: "bar", child: true}, result)
  end
end
