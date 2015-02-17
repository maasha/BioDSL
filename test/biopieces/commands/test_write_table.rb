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

class TestWriteTable < Test::Unit::TestCase 
  def setup
    @zcat = BioPieces::Filesys::which('gzcat') || BioPieces::Filesys::which('zcat')

    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.fna')
    @file2  = File.join(@tmpdir, 'test.fna')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({ORGANISM: "Human", COUNT: 23524, SEQ: "ATACGTCAG"})
    @output.write({ORGANISM: "Dog",   COUNT: 2442,  SEQ: "AGCATGAC"})
    @output.write({ORGANISM: "Mouse", COUNT: 234,   SEQ: "GACTG"})
    @output.write({ORGANISM: "Cat",   COUNT: 2342,  SEQ: "AAATGCA"})

    @output.close

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::WriteTable with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.write_table(foo: "bar") }
  end

  test "BioPieces::Pipeline::WriteTable with valid options don't raise" do
    assert_nothing_raised { @p.write_table(keys: [:SEQ]) }
  end

  test "BioPieces::Pipeline::WriteTable to stdout outputs correctly" do
    result = capture_stdout { @p.write_table.run(input: @input) }
    expected = "Human\t23524\tATACGTCAG\nDog\t2442\tAGCATGAC\nMouse\t234\tGACTG\nCat\t2342\tAAATGCA\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with options[:keys] outputs correctly" do
    result = capture_stdout { @p.write_table(keys:[:SEQ, "COUNT"]).run(input: @input) }
    expected = "ATACGTCAG\t23524\nAGCATGAC\t2442\nGACTG\t234\nAAATGCA\t2342\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with options[:skip] outputs correctly" do
    result = capture_stdout { @p.write_table(skip:[:SEQ, "COUNT"]).run(input: @input) }
    expected = "Human\nDog\nMouse\nCat\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with options[:header] outputs correctly" do
    result = capture_stdout { @p.write_table(header: true).run(input: @input) }
    expected = "#ORGANISM\tCOUNT\tSEQ\nHuman\t23524\tATACGTCAG\nDog\t2442\tAGCATGAC\nMouse\t234\tGACTG\nCat\t2342\tAAATGCA\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with options[:delimiter] outputs correctly" do
    result = capture_stdout { @p.write_table(delimiter: ";").run(input: @input) }
    expected = "Human;23524;ATACGTCAG\nDog;2442;AGCATGAC\nMouse;234;GACTG\nCat;2342;AAATGCA\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with options[:delimiter] with options[:pretty] raises" do
    assert_raise(BioPieces::OptionError) { @p.write_table(delimiter: ";", pretty: true) }
  end

  test "BioPieces::Pipeline::WriteTable with options[:commify] with options[:pretty] raises" do
    assert_raise(BioPieces::OptionError) { @p.write_table(commify: true) }
  end

  test "BioPieces::Pipeline::WriteTable with options[:pretty] outputs correctly" do
    result = capture_stdout { @p.write_table(pretty: true).run(input: @input) }
    expected = "+-------+-------+-----------+\n| Human | 23524 | ATACGTCAG |\n| Dog   |  2442 | AGCATGAC  |\n| Mouse |   234 | GACTG     |\n| Cat   |  2342 | AAATGCA   |\n+-------+-------+-----------+\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with options[:pretty] and options[:header] outputs correctly" do
    result = capture_stdout { @p.write_table(pretty: true, header: true).run(input: @input) }
    expected = "+----------+-------+-----------+\n| ORGANISM | COUNT | SEQ       |\n+----------+-------+-----------+\n| Human    | 23524 | ATACGTCAG |\n| Dog      |  2442 | AGCATGAC  |\n| Mouse    |   234 | GACTG     |\n| Cat      |  2342 | AAATGCA   |\n+----------+-------+-----------+\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with options[:pretty] and options[:commify] outputs correctly" do
    result = capture_stdout { @p.write_table(pretty: true, commify: true).run(input: @input) }
    expected = "+-------+--------+-----------+\n| Human | 23,524 | ATACGTCAG |\n| Dog   |  2,442 | AGCATGAC  |\n| Mouse |    234 | GACTG     |\n| Cat   |  2,342 | AAATGCA   |\n+-------+--------+-----------+\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with options[:pretty] and options[:commify] and floats outputs correctly" do
    input, output   = BioPieces::Stream.pipe

    output.write({ORGANISM: "Human", COUNT: 23524, SEQ: "ATACGTCAG"})
    output.write({ORGANISM: "Dog",   COUNT: 244.1, SEQ: "AGCATGAC"})
    output.write({ORGANISM: "Mouse", COUNT: 234,   SEQ: "GACTG"})
    output.write({ORGANISM: "Cat",   COUNT: 2342,  SEQ: "AAATGCA"})

    output.close

    p = BioPieces::Pipeline.new

    result = capture_stdout { p.write_table(pretty: true, commify: true).run(input: input) }
    expected = "+-------+--------+-----------+\n| Human | 23,524 | ATACGTCAG |\n| Dog   |  244.1 | AGCATGAC  |\n| Mouse |    234 | GACTG     |\n| Cat   |  2,342 | AAATGCA   |\n+-------+--------+-----------+\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with V<num> keys are output correctly" do
    input, output   = BioPieces::Stream.pipe

    output.write({V1: "Human", V2: 23524, V0: "ATACGTCAG"})
    output.write({V1: "Dog",   V2: 244.1, V0: "AGCATGAC"})
    output.write({V1: "Mouse", V2: 234,   V0: "GACTG"})
    output.write({V1: "Cat",   V2: 2342,  V0: "AAATGCA"})

    output.close

    p = BioPieces::Pipeline.new

    result = capture_stdout { p.write_table.run(input: input) }
    expected = "ATACGTCAG\tHuman\t23524\nAGCATGAC\tDog\t244.1\nGACTG\tMouse\t234\nAAATGCA\tCat\t2342\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable to file outputs correctly" do
    @p.write_table(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "Human\t23524\tATACGTCAG\nDog\t2442\tAGCATGAC\nMouse\t234\tGACTG\nCat\t2342\tAAATGCA\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable to file with options[:first] outputs correctly" do
    @p.write_table(output: @file, first: 1).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "Human\t23524\tATACGTCAG\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable to file with options[:last] outputs correctly" do
    @p.write_table(output: @file, last: 1).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "Cat\t2342\tAAATGCA\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable to file with options[:pretty] outputs correctly" do
    @p.write_table(output: @file, pretty: true, header: true, commify: true).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = <<EOD
+----------+--------+-----------+
| ORGANISM | COUNT  | SEQ       |
+----------+--------+-----------+
| Human    | 23,524 | ATACGTCAG |
| Dog      |  2,442 | AGCATGAC  |
| Mouse    |    234 | GACTG     |
| Cat      |  2,342 | AAATGCA   |
+----------+--------+-----------+
EOD
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable to file with options[:pretty] and options[:first] outputs correctly" do
    @p.write_table(output: @file, pretty: true, header: true, commify: true, first: 1).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = <<EOD
+----------+--------+-----------+
| ORGANISM | COUNT  | SEQ       |
+----------+--------+-----------+
| Human    | 23,524 | ATACGTCAG |
+----------+--------+-----------+
EOD
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable to file with options[:pretty] and options[:last] outputs correctly" do
    @p.write_table(output: @file, pretty: true, header: true, commify: true, last: 1).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = <<EOD
+----------+-------+---------+
| ORGANISM | COUNT | SEQ     |
+----------+-------+---------+
| Cat      | 2,342 | AAATGCA |
+----------+-------+---------+
EOD
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable to existing file raises" do
    `touch #{@file}`
    assert_raise(BioPieces::OptionError) { @p.write_table(output: @file) }
  end

  test "BioPieces::Pipeline::WriteTable to existing file with options[:force] outputs correctly" do
    `touch #{@file}`
    @p.write_table(output: @file, force: true).run(input: @input)
    result = File.open(@file).read
    expected = "Human\t23524\tATACGTCAG\nDog\t2442\tAGCATGAC\nMouse\t234\tGACTG\nCat\t2342\tAAATGCA\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with gzipped data and no output file raises" do
    assert_raise(BioPieces::OptionError) { @p.write_table(gzip: true) }
  end

  test "BioPieces::Pipeline::WriteTable with bzip2'ed data and no output file raises" do
    assert_raise(BioPieces::OptionError) { @p.write_table(bzip2: true) }
  end

  test "BioPieces::Pipeline::WriteTable to file outputs gzipped data correctly" do
    @p.write_table(output: @file, gzip: true).run(input: @input)
    result = `#{@zcat} #{@file}`
    expected = "Human\t23524\tATACGTCAG\nDog\t2442\tAGCATGAC\nMouse\t234\tGACTG\nCat\t2342\tAAATGCA\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable to file outputs bzip2'ed data correctly" do
    @p.write_table(output: @file, bzip2: true).run(input: @input)
    result = `bzcat #{@file}`
    expected = "Human\t23524\tATACGTCAG\nDog\t2442\tAGCATGAC\nMouse\t234\tGACTG\nCat\t2342\tAAATGCA\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteTable with both gzip and bzip2 output raises" do
    assert_raise(BioPieces::OptionError) { @p.write_table(output: @file, gzip: true, bzip2: true) }
  end

  test "BioPieces::Pipeline::WriteTable with flux outputs correctly" do
    @p.write_table(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "Human\t23524\tATACGTCAG\nDog\t2442\tAGCATGAC\nMouse\t234\tGACTG\nCat\t2342\tAAATGCA\n"
    assert_equal(expected, result)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << %Q{{:ORGANISM=>"Human", :COUNT=>23524, :SEQ=>"ATACGTCAG"}}
    stream_expected << %Q{{:ORGANISM=>"Dog", :COUNT=>2442, :SEQ=>"AGCATGAC"}}
    stream_expected << %Q{{:ORGANISM=>"Mouse", :COUNT=>234, :SEQ=>"GACTG"}}
    stream_expected << %Q{{:ORGANISM=>"Cat", :COUNT=>2342, :SEQ=>"AAATGCA"}}
    assert_equal(stream_expected, stream_result)
  end
end
