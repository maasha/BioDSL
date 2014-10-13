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

class TestCollectOtus < Test::Unit::TestCase 
  test "BioPieces::Pipeline#collect_otus with disallowed option raises" do
    p = BioPieces::Pipeline.new
    assert_raise(BioPieces::OptionError) { p.collect_otus(foo: "bar") }
  end

  test "BioPieces::Pipeline#collect_otus outputs correctly" do
    input, output   = BioPieces::Stream.pipe
    input2, output2 = BioPieces::Stream.pipe

    output.write({one: 1, two: 2, three: 3})
    output.write({TYPE: 'H', S_ID: "OTU_0", SAMPLE: "Sample0"})
    output.write({TYPE: 'H', S_ID: "OTU_0", SAMPLE: "Sample0"})
    output.write({TYPE: 'H', S_ID: "OTU_0", SAMPLE: "Sample1"})
    output.write({TYPE: 'H', S_ID: "OTU_1", SAMPLE: "Sample0"})
    output.write({TYPE: 'H', S_ID: "OTU_1", SAMPLE: "Sample1"})
    output.write({TYPE: 'H', S_ID: "OTU_1", SAMPLE: "Sample1"})
    output.close

    p = BioPieces::Pipeline.new
    p.collect_otus.run(input: input, output: output2)
    result   = input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:one=>1, :two=>2, :three=>3}}
    expected << %Q{{:TYPE=>"H", :S_ID=>"OTU_0", :SAMPLE=>"Sample0"}}
    expected << %Q{{:TYPE=>"H", :S_ID=>"OTU_0", :SAMPLE=>"Sample0"}}
    expected << %Q{{:TYPE=>"H", :S_ID=>"OTU_0", :SAMPLE=>"Sample1"}}
    expected << %Q{{:TYPE=>"H", :S_ID=>"OTU_1", :SAMPLE=>"Sample0"}}
    expected << %Q{{:TYPE=>"H", :S_ID=>"OTU_1", :SAMPLE=>"Sample1"}}
    expected << %Q{{:TYPE=>"H", :S_ID=>"OTU_1", :SAMPLE=>"Sample1"}}
    expected << %Q{{:RECORD_TYPE=>"OTU", :OTU=>"OTU_0", :SAMPLE0_COUNT=>2, :SAMPLE1_COUNT=>1}}
    expected << %Q{{:RECORD_TYPE=>"OTU", :OTU=>"OTU_1", :SAMPLE0_COUNT=>1, :SAMPLE1_COUNT=>2}}

    assert_equal(expected, result)
  end
end
