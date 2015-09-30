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
# This software is part of BioDSL (www.BioDSL.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for the dump command.
class TestDump < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(one: 1, two: 2, three: 3)
    @output.write(SEQ_NAME: 'test1', SEQ: 'atcg', SEQ_LEN: 4)
    @output.write(SEQ_NAME: 'test2', SEQ: 'gtac', SEQ_LEN: 4)
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline#dump with disallowed option raises' do
    assert_raise(BioDSL::OptionError) { @p.dump(foo: 'bar') }
  end

  test 'BioDSL::Pipeline#dump with bad first raises' do
    assert_raise(BioDSL::OptionError) { @p.dump(first: 0) }
  end

  test 'BioDSL::Pipeline#dump with bad last raises' do
    assert_raise(BioDSL::OptionError) { @p.dump(last: 0) }
  end

  test 'BioDSL::Pipeline#dump with first and last raises' do
    assert_raise(BioDSL::OptionError) { @p.dump(first: 1, last: 1) }
  end

  test 'BioDSL::Pipeline#dump returns correctly' do
    result1 = capture_stdout { @p.dump.run(input: @input, output: @output2) }
    result2 = collect_result

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:one=>1, :two=>2, :three=>3}
      |{:SEQ_NAME=>\"test1\", :SEQ=>\"atcg\", :SEQ_LEN=>4}
      |{:SEQ_NAME=>\"test2\", :SEQ=>\"gtac\", :SEQ_LEN=>4}
    EXP

    assert_equal(expected, result1)
    assert_equal(expected, result2)
  end

  test 'BioDSL::Pipeline#dump status returns correctly' do
    capture_stdout { @p.dump.run(input: @input, output: @output2) }

    assert_equal(3, @p.status.first[:records_in])
    assert_equal(3, @p.status.first[:records_out])
  end

  test 'BioDSL::Pipeline#dump with options[first: 1] returns correctly' do
    result1 = capture_stdout do
      @p.dump(first: 1).run(input: @input, output: @output2)
    end

    result2 = collect_result

    expected = "{:one=>1, :two=>2, :three=>3}\n"

    assert_equal(expected, result1)
    assert_equal(expected, result2)
  end

  test 'BioDSL::Pipeline#dump with options[last: 1] returns correctly' do
    result1 = capture_stdout do
      @p.dump(last: 1).run(input: @input, output: @output2)
    end

    result2 = collect_result

    expected = "{:SEQ_NAME=>\"test2\", :SEQ=>\"gtac\", :SEQ_LEN=>4}\n"

    assert_equal(expected, result1)
    assert_equal(expected, result2)
  end
end
