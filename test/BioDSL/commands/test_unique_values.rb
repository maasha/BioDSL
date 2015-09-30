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

# Test class for UniqueValues.
class TestUniqueValues < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    [{V0: 'HUMAN', V1: 'H1'},
     {V0: 'HUMAN', V1: 'H2'},
     {V0: 'HUMAN', V1: 'H3'},
     {V0: 'DOG',   V1: 'D1'},
     {V0: 'DOG',   V1: 'D2'},
     {V0: 'MOUSE', V1: 'M1'},
     {FOO: 'BAR'}
    ].each do |record|
      @output.write record
    end

    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline#unique_values with disallowed option raises' do
    assert_raise(BioDSL::OptionError) do
      @p.unique_values(key: :V0, foo: 'bar')
    end
  end

  test 'BioDSL::Pipeline#unique_values with allowed options dont raise' do
    assert_nothing_raised { @p.unique_values(key: :V0) }
  end

  test 'BioDSL::Pipeline#unique_values returns correctly' do
    @p.unique_values(key: 'V0').run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:V0=>"HUMAN", :V1=>"H1"}
      |{:V0=>"DOG", :V1=>"D1"}
      |{:V0=>"MOUSE", :V1=>"M1"}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline#unique_values status returns correctly' do
    @p.unique_values(key: 'V0').run(input: @input, output: @output2)

    assert_equal(7, @p.status.first[:records_in])
    assert_equal(4, @p.status.first[:records_out])
  end

  test 'BioDSL::Pipeline#unique_values with :invert returns correctly' do
    @p.unique_values(key: 'V0', invert: true).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:V0=>"HUMAN", :V1=>"H2"}
      |{:V0=>"HUMAN", :V1=>"H3"}
      |{:V0=>"DOG", :V1=>"D2"}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end
end
