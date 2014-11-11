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

class TestReadTable < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")

    data = <<EOF
#ID COUNT
# 2014-10-14
TCMID104 12
TCMID105 123
TCMID106 1231

EOF

    @file   = File.join(@tmpdir, 'test.tab')
    @file2  = File.join(@tmpdir, 'test2.tab')

    File.open(@file, 'w') do |ios|
      ios.puts data
    end

    File.open(@file2, 'w') do |ios|
      ios.puts data
    end

    hash1 = '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    hash2 = '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write hash1
    @output.write hash2
    @output.close

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::ReadTable with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_table(foo: "bar") }
  end

  test "BioPieces::Pipeline::ReadTable without required options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_table() }
  end

  test "BioPieces::Pipeline::ReadTable with bad first raises" do
    assert_raise(BioPieces::OptionError) { @p.read_table(input: @file, first: -1) }
  end

  test "BioPieces::Pipeline::ReadTable with bad last raises" do
    assert_raise(BioPieces::OptionError) { @p.read_table(input: @file, last: -1) }
  end

  test "BioPieces::Pipeline::ReadTable with exclusive unique options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_table(input: @file, first: 1, last: 1) }
  end

  test "BioPieces::Pipeline::ReadTable with non-existing input file raises" do
    assert_raise(BioPieces::OptionError) { @p.read_table(input: "___adsf") }
  end

  test "BioPieces::Pipeline::ReadTable with duplicate keys raises" do
    assert_raise(BioPieces::OptionError) { @p.read_table(input: @file, keys: [:a, :a]) }
  end

  test "BioPieces::Pipeline::ReadTable with duplicate columns raises" do
    assert_raise(BioPieces::OptionError) { @p.read_table(input: @file, columns: [1, 1]) }
  end

  test "BioPieces::Pipeline::ReadTable returns correctly" do
    @p.read_table(input: @file).run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with :skip returns correctly" do
    @p.read_table(input: @file, skip: 2).run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:V0=>"TCMID104", :V1=>12}}
    expected << %Q{{:V0=>"TCMID105", :V1=>123}}
    expected << %Q{{:V0=>"TCMID106", :V1=>1231}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with :delimeter returns correctly" do
    @p.read_table(input: @file, skip: 2, delimiter: "ID").run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:V0=>"TCM", :V1=>"104 12"}}
    expected << %Q{{:V0=>"TCM", :V1=>"105 123"}}
    expected << %Q{{:V0=>"TCM", :V1=>"106 1231"}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with :keys returns correctly" do
    @p.read_table(input: @file, keys: ["FOO", :BAR]).run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:FOO=>"TCMID104", :BAR=>12}}
    expected << %Q{{:FOO=>"TCMID105", :BAR=>123}}
    expected << %Q{{:FOO=>"TCMID106", :BAR=>1231}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with :columns and :keys returns correctly" do
    @p.read_table(input: @file, columns: [1], keys: ["FOO"]).run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:FOO=>12}}
    expected << %Q{{:FOO=>123}}
    expected << %Q{{:FOO=>1231}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with :skip and :keys returns correctly" do
    @p.read_table(input: @file, skip: 2, keys: ["FOO", :BAR]).run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:FOO=>"TCMID104", :BAR=>12}}
    expected << %Q{{:FOO=>"TCMID105", :BAR=>123}}
    expected << %Q{{:FOO=>"TCMID106", :BAR=>1231}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with :columns returns correctly" do
    @p.read_table(input: @file, columns: [1]).run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:COUNT=>12}}
    expected << %Q{{:COUNT=>123}}
    expected << %Q{{:COUNT=>1231}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with :skip and :columns returns correctly" do
    @p.read_table(input: @file, skip: 2, columns: [1, 0]).run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:V0=>12, :V1=>"TCMID104"}}
    expected << %Q{{:V0=>123, :V1=>"TCMID105"}}
    expected << %Q{{:V0=>1231, :V1=>"TCMID106"}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with gzipped data returns correctly" do
    `gzip #{@file}`

    @p.read_table(input: "#{@file}.gz").run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with bzip2'ed data returns correctly" do
    `bzip2 #{@file}`

    @p.read_table(input: "#{@file}.bz2").run(output: @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with multiple files returns correctly" do
    @p.read_table(input: [@file, @file2]).run(output: @output2)

    expected = ""
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with input glob returns correctly" do
    @p.read_table(input: File.join(@tmpdir, "test*.tab")).run(output: @output2)

    expected = ""
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with options[:first] returns correctly" do
    @p.read_table(input: [@file, @file2], first: 3).run(output: @output2)

    expected = ""
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable#to_s with options[:first] returns correctly" do
    @p.read_table(input: @file, first: 3)

    expected = %{BP.new.read_table(input: "#{@file}", first: 3)}

    assert_equal(expected, @p.to_s)
  end

  test "BioPieces::Pipeline::ReadTable with options[:last] returns correctly" do
    @p.read_table(input: [@file, @file2], last: 2).run(output: @output2)

    expected = ""
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadTable with flux returns correctly" do
    @p.read_table(input: @file2).run(input: @input, output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}}
    expected << %Q{{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}}
    expected << %Q{{:ID=>"TCMID104", :COUNT=>12}}
    expected << %Q{{:ID=>"TCMID105", :COUNT=>123}}
    expected << %Q{{:ID=>"TCMID106", :COUNT=>1231}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end
end
