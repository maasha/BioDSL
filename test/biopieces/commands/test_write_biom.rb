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

class TestWriteBiom < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.otu')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({OTU: 'OTU_0', SAMPLE1_COUNT: 3352, TAXONOMY: 'Streptococcaceae(100);Lactococcus(100)'})
    @output.write({OTU: 'OTU_1', SAMPLE1_COUNT: 881,  TAXONOMY: 'Leuconostocaceae(100);Leuconostoc(100)'})
    @output.write({OTU: 'OTU_2', SAMPLE1_COUNT: 5,    TAXONOMY: 'Pseudomonadaceae(100);Pseudomonas(100)'})
    @output.write({FOO: "BAR"})

    @output.close

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::WriteBiom with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.write_biom(foo: "bar") }
  end

  test "BioPieces::Pipeline::WriteBiom with valid options don't raise" do
    assert_nothing_raised { @p.write_biom(output: @file) }
  end

  test "BioPieces::Pipeline::WriteBiom to file outputs correctly" do
    @p.write_biom(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = '{"id": "None","format": "Biological Observation Matrix 2.1.0","format_url": "http://biom-format.org","matrix_type": "sparse","generated_by": "BIOM-Format 2.1","date": "2014-11-10T11:03:34.980081","type": "OTU table","matrix_element_type": "float","shape": [3, 1],"data": [[0,0,3352.0],[1,0,881.0],[2,0,5.0]],"rows": [{"id": "OTU_0", "metadata": {"taxonomy": "Streptococcaceae(100);Lactococcus(100)"}},{"id": "OTU_1", "metadata": {"taxonomy": "Leuconostocaceae(100);Leuconostoc(100)"}},{"id": "OTU_2", "metadata": {"taxonomy": "Pseudomonadaceae(100);Pseudomonas(100)"}}],"columns": [{"id": "SAMPLE1_COUNT", "metadata": null}]}'
    assert_equal(expected.sub(/"date":[^,]+,/, ''), result.sub(/"date":[^,]+,/, ''))
  end

  test "BioPieces::Pipeline::WriteBiom to existing file raises" do
    `touch #{@file}`
    assert_raise(BioPieces::OptionError) { @p.write_biom(output: @file) }
  end

  test "BioPieces::Pipeline::WriteBiom to existing file with options[:force] outputs correctly" do
    `touch #{@file}`
    @p.write_biom(output: @file, force: true).run(input: @input)
    result = File.open(@file).read
    expected = '{"id": "None","format": "Biological Observation Matrix 2.1.0","format_url": "http://biom-format.org","matrix_type": "sparse","generated_by": "BIOM-Format 2.1","date": "2014-11-10T11:03:34.980081","type": "OTU table","matrix_element_type": "float","shape": [3, 1],"data": [[0,0,3352.0],[1,0,881.0],[2,0,5.0]],"rows": [{"id": "OTU_0", "metadata": {"taxonomy": "Streptococcaceae(100);Lactococcus(100)"}},{"id": "OTU_1", "metadata": {"taxonomy": "Leuconostocaceae(100);Leuconostoc(100)"}},{"id": "OTU_2", "metadata": {"taxonomy": "Pseudomonadaceae(100);Pseudomonas(100)"}}],"columns": [{"id": "SAMPLE1_COUNT", "metadata": null}]}'
    assert_equal(expected.sub(/"date":[^,]+,/, ''), result.sub(/"date":[^,]+,/, ''))
  end

  test "BioPieces::Pipeline::WriteBiom with flux outputs correctly" do
    @p.write_biom(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = '{"id": "None","format": "Biological Observation Matrix 2.1.0","format_url": "http://biom-format.org","matrix_type": "sparse","generated_by": "BIOM-Format 2.1","date": "2014-11-10T11:03:34.980081","type": "OTU table","matrix_element_type": "float","shape": [3, 1],"data": [[0,0,3352.0],[1,0,881.0],[2,0,5.0]],"rows": [{"id": "OTU_0", "metadata": {"taxonomy": "Streptococcaceae(100);Lactococcus(100)"}},{"id": "OTU_1", "metadata": {"taxonomy": "Leuconostocaceae(100);Leuconostoc(100)"}},{"id": "OTU_2", "metadata": {"taxonomy": "Pseudomonadaceae(100);Pseudomonas(100)"}}],"columns": [{"id": "SAMPLE1_COUNT", "metadata": null}]}'
    assert_equal(expected.sub(/"date":[^,]+,/, ''), result.sub(/"date":[^,]+,/, ''))

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << %Q{{:OTU=>"OTU_0", :SAMPLE1_COUNT=>3352, :TAXONOMY=>"Streptococcaceae(100);Lactococcus(100)"}}
    stream_expected << %Q{{:OTU=>"OTU_1", :SAMPLE1_COUNT=>881, :TAXONOMY=>"Leuconostocaceae(100);Leuconostoc(100)"}}
    stream_expected << %Q{{:OTU=>"OTU_2", :SAMPLE1_COUNT=>5, :TAXONOMY=>"Pseudomonadaceae(100);Pseudomonas(100)"}}
    stream_expected << %Q{{:FOO=>"BAR"}}

    assert_equal(stream_expected, stream_result)
  end
end
