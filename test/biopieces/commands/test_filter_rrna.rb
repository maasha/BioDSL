#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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

class TestFilterRrna < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")

    omit("sortmerna not found")   unless BioPieces::Filesys.which("sortmerna")
    omit("indexdb_rna not found") unless BioPieces::Filesys.which("indexdb_rna")

    @file   = File.join(@tmpdir, 'test.tree')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({SEQ: "attgactgacg--"})
    @output.write({SEQ: "attgactaagacg"})
    @output.write({SEQ: "a---actgacg--"})
    @output.write({SEQ: "a---actaagacg"})
    @output.write({SEQ: "a---actaagacg"})
    @output.write({FOO: "BAR"})
    @output.close

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir if @tmpdir
  end

  test "BioPieces::Pipeline::FilterRrna with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.filter_rrna(foo: "bar") }
  end

  test "BioPieces::Pipeline::FilterRrna to stdout outputs correctly" do
    result = capture_stdout { @p.filter_rrna.run(input: @input) }
    expected = "(1:0.00055,(3:0.0,4:0.0):0.00054,(0:0.00055,2:0.00054)0.996:0.34079);\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::FilterRrna to file outputs correctly" do
    @p.filter_rrna(output: @file).run(input: @input, output: @output2)
    result = File.read(@file)
    expected = "(1:0.00055,(3:0.0,4:0.0):0.00054,(0:0.00055,2:0.00054)0.996:0.34079);\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::FilterRrna with flux outputs correctly" do
    @p.filter_rrna(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "(1:0.00055,(3:0.0,4:0.0):0.00054,(0:0.00055,2:0.00054)0.996:0.34079);\n"
    assert_equal(expected, result)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ=>"attgactgacg--"}'
    stream_expected << '{:SEQ=>"attgactaagacg"}'
    stream_expected << '{:SEQ=>"a---actgacg--"}'
    stream_expected << '{:SEQ=>"a---actaagacg"}'
    stream_expected << '{:SEQ=>"a---actaagacg"}'
    stream_expected << '{:FOO=>"BAR"}'

    assert_equal(stream_expected, stream_result)
  end
end
