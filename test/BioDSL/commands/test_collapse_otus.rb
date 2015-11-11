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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for CollapseOtus.
class TestCollapseOtus < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(OTU: 'OTU_0', SAMPLE1_COUNT: 3352,
                  TAXONOMY: 'Streptococcaceae(100);Lactococcus(100)')
    @output.write(OTU: 'OTU_1', SAMPLE1_COUNT: 881,
                  TAXONOMY: 'Leuconostocaceae(100);Leuconostoc(100)')
    @output.write(OTU: 'OTU_2', SAMPLE1_COUNT: 228,
                  TAXONOMY: 'Streptococcaceae(100);Lactococcus(100)')
    @output.write(OTU: 'OTU_3', SAMPLE1_COUNT: 5,
                  TAXONOMY: 'Pseudomonadaceae(100);Pseudomonas(100)')

    @output.close

    @p = BD.new
  end

  test 'BioDSL::Pipeline::Count with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.collapse_otus(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::Count to file outputs correctly' do
    @p.collapse_otus.run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:OTU=>"OTU_0",
      | :SAMPLE1_COUNT=>3580,
      | :TAXONOMY=>"Streptococcaceae(100);Lactococcus(100)"}
      |{:OTU=>"OTU_1",
      | :SAMPLE1_COUNT=>881,
      | :TAXONOMY=>"Leuconostocaceae(100);Leuconostoc(100)"}
      |{:OTU=>"OTU_3",
      | :SAMPLE1_COUNT=>5,
      | :TAXONOMY=>"Pseudomonadaceae(100);Pseudomonas(100)"}
    EXP
    assert_equal(expected, collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::Count status outputs correctly' do
    @p.collapse_otus.run(input: @input, output: @output2)

    assert_equal(4, @p.status.first[:records_in])
    assert_equal(3, @p.status.first[:records_out])
    assert_equal(4, @p.status.first[:otus_in])
    assert_equal(3, @p.status.first[:otus_out])
  end
end
