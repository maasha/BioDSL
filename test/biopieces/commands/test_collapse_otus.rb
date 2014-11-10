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

class TestCollapseOtus < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({OTU: 'OTU_0', SAMPLE1_COUNT: 3352, TAXONOMY: 'Streptococcaceae(100);Lactococcus(100)'})
    @output.write({OTU: 'OTU_1', SAMPLE1_COUNT: 881,  TAXONOMY: 'Leuconostocaceae(100);Leuconostoc(100)'})
    @output.write({OTU: 'OTU_2', SAMPLE1_COUNT: 228,  TAXONOMY: 'Streptococcaceae(100);Lactococcus(100)'})
    @output.write({OTU: 'OTU_3', SAMPLE1_COUNT: 5,    TAXONOMY: 'Pseudomonadaceae(100);Pseudomonas(100)'})

    @output.close

    @p = BP.new
  end

  test "BioPieces::Pipeline::Count with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.collapse_otus(foo: "bar") }
  end

  test "BioPieces::Pipeline::Count to file outputs correctly" do
    @p.collapse_otus.run(input: @input, output: @output2)
    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:OTU=>"OTU_0", :SAMPLE1_COUNT=>3580, :TAXONOMY=>"Streptococcaceae(100);Lactococcus(100)"}'
    expected << '{:OTU=>"OTU_1", :SAMPLE1_COUNT=>881, :TAXONOMY=>"Leuconostocaceae(100);Leuconostoc(100)"}'
    expected << '{:OTU=>"OTU_3", :SAMPLE1_COUNT=>5, :TAXONOMY=>"Pseudomonadaceae(100);Pseudomonas(100)"}'
    assert_equal(expected, result)
  end
end

