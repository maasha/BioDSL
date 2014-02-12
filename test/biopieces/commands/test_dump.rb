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

class TestDump < Test::Unit::TestCase 
  include BioPieces::Dump

  def setup
    @command          = BioPieces::Pipeline::Command.new(:dump)
    @input1, @output1 = BioPieces::Pipeline::Stream.pipe
    @input2, @output2 = BioPieces::Pipeline::Stream.pipe
    @hash             = {one: 1, two: 2, three: 3}
  end

  test "BioPieces::Pipeline#dump returns correctly" do
    @output1.write @hash
    @output1.close

    stdout = capture_stdout { @command.run(@input1, @output2) }

    assert_equal(@hash.to_s, stdout.chomp)
    assert_equal(@hash, @input2.read)
  end

  test "BioPieces::Pipeline#dump with options[first: 1] returns correctly" do
    hash = {four: 4, five: 5, six: 6}
    @command = BioPieces::Pipeline::Command.new(:dump, first: 1)
    @output1.write @hash
    @output1.write hash
    @output1.close

    stdout = capture_stdout { @command.run(@input1, @output2) }

    assert_equal(@hash.to_s, stdout.chomp)
    assert_equal(@hash, @input2.read)
  end

  test "BioPieces::Pipeline#dump with options[last: 1] returns correctly" do
    hash = {four: 4, five: 5, six: 6}
    @command = BioPieces::Pipeline::Command.new(:dump, last: 1)
    @output1.write @hash
    @output1.write hash
    @output1.close

    stdout = capture_stdout { @command.run(@input1, @output2) }

    assert_equal(hash.to_s, stdout.chomp)
    assert_equal(hash, @input2.read)
  end
end
