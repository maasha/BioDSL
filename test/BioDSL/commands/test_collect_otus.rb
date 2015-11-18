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

# Test class for CollectOtus.
class TestCollectOtus < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(one: 1, two: 2, three: 3)
    @output.write(TYPE: 'H', S_ID: 'OTU_0', SAMPLE: 'Sample0')
    @output.write(TYPE: 'H', S_ID: 'OTU_0', SAMPLE: 'Sample0')
    @output.write(TYPE: 'H', S_ID: 'OTU_0', SAMPLE: 'Sample1')
    @output.write(TYPE: 'H', S_ID: 'OTU_1', SAMPLE: 'Sample0')
    @output.write(TYPE: 'H', S_ID: 'OTU_1', SAMPLE: 'Sample1')
    @output.write(TYPE: 'H', S_ID: 'OTU_1', SAMPLE: 'Sample1')
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline#collect_otus with disallowed option raises' do
    assert_raise(BioDSL::OptionError) { @p.collect_otus(foo: 'bar') }
  end

  test 'BioDSL::Pipeline#collect_otus outputs correctly' do
    @p.collect_otus.run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:one=>1, :two=>2, :three=>3}
      |{:TYPE=>"H", :S_ID=>"OTU_0", :SAMPLE=>"Sample0"}
      |{:TYPE=>"H", :S_ID=>"OTU_0", :SAMPLE=>"Sample0"}
      |{:TYPE=>"H", :S_ID=>"OTU_0", :SAMPLE=>"Sample1"}
      |{:TYPE=>"H", :S_ID=>"OTU_1", :SAMPLE=>"Sample0"}
      |{:TYPE=>"H", :S_ID=>"OTU_1", :SAMPLE=>"Sample1"}
      |{:TYPE=>"H", :S_ID=>"OTU_1", :SAMPLE=>"Sample1"}
      |{:RECORD_TYPE=>"OTU", :OTU=>"OTU_0", :SAMPLE0_COUNT=>2,
      | :SAMPLE1_COUNT=>1}
      |{:RECORD_TYPE=>"OTU", :OTU=>"OTU_1", :SAMPLE0_COUNT=>1,
      | :SAMPLE1_COUNT=>2}
    EXP

    assert_equal(expected, collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline#collect_otus status outputs correctly' do
    @p.collect_otus.run(input: @input, output: @output2)

    assert_equal(7, @p.status.first[:records_in])
    assert_equal(9, @p.status.first[:records_out])
    assert_equal(6, @p.status.first[:hits_in])
    assert_equal(2, @p.status.first[:hits_out])
  end
end
