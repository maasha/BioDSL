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

# rubocop: disable ClassLength

# Test class for WriteTable.
class TestWriteTable < Test::Unit::TestCase
  def setup
    @zcat = BioDSL::Filesys.which('gzcat') ||
            BioDSL::Filesys.which('zcat')

    @tmpdir = Dir.mktmpdir('BioDSL')
    @file   = File.join(@tmpdir, 'test.fna')
    @file2  = File.join(@tmpdir, 'test.fna')

    setup_data

    @p = BioDSL::Pipeline.new
  end

  def setup_data
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(ORGANISM: 'Human', COUNT: 23_524, SEQ: 'ATACGTCAG')
    @output.write(ORGANISM: 'Dog',   COUNT: 2442,   SEQ: 'AGCATGAC')
    @output.write(ORGANISM: 'Mouse', COUNT: 234,    SEQ: 'GACTG')
    @output.write(ORGANISM: 'Cat',   COUNT: 2_342,  SEQ: 'AAATGCA')

    @output.close
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::WriteTable with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.write_table(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::WriteTable with valid options dont raise' do
    assert_nothing_raised { @p.write_table(keys: [:SEQ]) }
  end

  test 'BioDSL::Pipeline::WriteTable to stdout outputs correctly' do
    result = capture_stdout { @p.write_table.run(input: @input) }
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |Human\t23524\tATACGTCAG
      |Dog\t2442\tAGCATGAC
      |Mouse\t234\tGACTG
      |Cat\t2342\tAAATGCA
    EXP

    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable status outputs correctly' do
    capture_stdout { @p.write_table.run(input: @input) }

    assert_equal(4, @p.status.first[:records_in])
    assert_equal(4, @p.status.first[:records_out])
  end

  test 'BioDSL::Pipeline::WriteTable with :keys outputs correctly' do
    result = capture_stdout do
      @p.write_table(keys: [:SEQ, 'COUNT']).run(input: @input)
    end

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |ATACGTCAG\t23524
      |AGCATGAC\t2442
      |GACTG\t234
      |AAATGCA\t2342
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable with :skip outputs correctly' do
    result = capture_stdout do
      @p.write_table(skip: [:SEQ, 'COUNT']).run(input: @input)
    end

    expected = "Human\nDog\nMouse\nCat\n"
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable with :header outputs correctly' do
    result = capture_stdout { @p.write_table(header: true).run(input: @input) }
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |#ORGANISM\tCOUNT\tSEQ
      |Human\t23524\tATACGTCAG
      |Dog\t2442\tAGCATGAC
      |Mouse\t234\tGACTG
      |Cat\t2342\tAAATGCA
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable with :delimiter outputs correctly' do
    result = capture_stdout do
      @p.write_table(delimiter: ';').run(input: @input)
    end

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |Human;23524;ATACGTCAG
      |Dog;2442;AGCATGAC
      |Mouse;234;GACTG
      |Cat;2342;AAATGCA
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable w. :delimiter and :pretty raises' do
    assert_raise(BioDSL::OptionError) do
      @p.write_table(delimiter: ';', pretty: true)
    end
  end

  test 'BioDSL::Pipeline::WriteTable with :commify and :pretty raises' do
    assert_raise(BioDSL::OptionError) { @p.write_table(commify: true) }
  end

  test 'BioDSL::Pipeline::WriteTable with :pretty outputs correctly' do
    result = capture_stdout { @p.write_table(pretty: true).run(input: @input) }
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |+-------+-------+-----------+
      || Human | 23524 | ATACGTCAG |
      || Dog   |  2442 | AGCATGAC  |
      || Mouse |   234 | GACTG     |
      || Cat   |  2342 | AAATGCA   |
      |+-------+-------+-----------+
    EXP

    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable with :pretty and :header outputs OK' do
    result = capture_stdout do
      @p.write_table(pretty: true, header: true).run(input: @input)
    end

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |+----------+-------+-----------+
      || ORGANISM | COUNT | SEQ       |
      |+----------+-------+-----------+
      || Human    | 23524 | ATACGTCAG |
      || Dog      |  2442 | AGCATGAC  |
      || Mouse    |   234 | GACTG     |
      || Cat      |  2342 | AAATGCA   |
      |+----------+-------+-----------+
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable w. :pretty and :commify outputs OK' do
    result = capture_stdout do
      @p.write_table(pretty: true, commify: true).run(input: @input)
    end
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |+-------+--------+-----------+
      || Human | 23,524 | ATACGTCAG |
      || Dog   |  2,442 | AGCATGAC  |
      || Mouse |    234 | GACTG     |
      || Cat   |  2,342 | AAATGCA   |
      |+-------+--------+-----------+
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable w. :pretty and :commify and floats ' \
    'outputs correctly' do
    input, output   = BioDSL::Stream.pipe

    output.write(ORGANISM: 'Human', COUNT: 23_524, SEQ: 'ATACGTCAG')
    output.write(ORGANISM: 'Dog',   COUNT: 244.1,  SEQ: 'AGCATGAC')
    output.write(ORGANISM: 'Mouse', COUNT: 234,    SEQ: 'GACTG')
    output.write(ORGANISM: 'Cat',   COUNT: 2_342,  SEQ: 'AAATGCA')

    output.close

    p = BioDSL::Pipeline.new

    result = capture_stdout do
      p.write_table(pretty: true, commify: true).run(input: input)
    end

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |+-------+--------+-----------+
      || Human | 23,524 | ATACGTCAG |
      || Dog   |  244.1 | AGCATGAC  |
      || Mouse |    234 | GACTG     |
      || Cat   |  2,342 | AAATGCA   |
      |+-------+--------+-----------+
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable with V<num> keys are output OK' do
    input, output   = BioDSL::Stream.pipe

    output.write(V1: 'Human', V2: 23_524, V0: 'ATACGTCAG')
    output.write(V1: 'Dog',   V2: 244.1,  V0: 'AGCATGAC')
    output.write(V1: 'Mouse', V2: 234,    V0: 'GACTG')
    output.write(V1: 'Cat',   V2: 2_342,  V0: 'AAATGCA')

    output.close

    p = BioDSL::Pipeline.new

    result = capture_stdout { p.write_table.run(input: input) }
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |ATACGTCAG\tHuman\t23524
      |AGCATGAC\tDog\t244.1
      |GACTG\tMouse\t234
      |AAATGCA\tCat\t2342
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable to file outputs correctly' do
    @p.write_table(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |Human\t23524\tATACGTCAG
      |Dog\t2442\tAGCATGAC
      |Mouse\t234\tGACTG
      |Cat\t2342\tAAATGCA
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable to file with :first outputs OK' do
    @p.write_table(output: @file, first: 1).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "Human\t23524\tATACGTCAG\n"
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable to file with :last outputs correctly' do
    @p.write_table(output: @file, last: 1).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "Cat\t2342\tAAATGCA\n"
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable to file with :pretty outputs OK' do
    @p.write_table(output: @file, pretty: true, header: true, commify: true).
      run(input: @input, output: @output2)

    result = File.open(@file).read
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |+----------+--------+-----------+
      || ORGANISM | COUNT  | SEQ       |
      |+----------+--------+-----------+
      || Human    | 23,524 | ATACGTCAG |
      || Dog      |  2,442 | AGCATGAC  |
      || Mouse    |    234 | GACTG     |
      || Cat      |  2,342 | AAATGCA   |
      |+----------+--------+-----------+
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable to file with :pretty and :first ' \
    'outputs correctly' do
    @p.write_table(output: @file, pretty: true, header: true,
                   commify: true, first: 1).run(input: @input, output: @output2)

    result = File.open(@file).read
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |+----------+--------+-----------+
      || ORGANISM | COUNT  | SEQ       |
      |+----------+--------+-----------+
      || Human    | 23,524 | ATACGTCAG |
      |+----------+--------+-----------+
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable to file with :pretty and :last ' \
    'outputs correctly' do
    @p.write_table(output: @file, pretty: true, header: true,
                   commify: true, last: 1).run(input: @input, output: @output2)

    result = File.open(@file).read
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |+----------+-------+---------+
      || ORGANISM | COUNT | SEQ     |
      |+----------+-------+---------+
      || Cat      | 2,342 | AAATGCA |
      |+----------+-------+---------+
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable to existing file raises' do
    `touch #{@file}`
    assert_raise(BioDSL::OptionError) { @p.write_table(output: @file) }
  end

  test 'BioDSL::Pipeline::WriteTable to existing file w. :force outputs ' \
    'OK' do
    `touch #{@file}`
    @p.write_table(output: @file, force: true).run(input: @input)
    result = File.open(@file).read
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |Human\t23524\tATACGTCAG
      |Dog\t2442\tAGCATGAC
      |Mouse\t234\tGACTG
      |Cat\t2342\tAAATGCA
    EXP
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable with gzipped data and no output ' \
    ' file raises' do
    assert_raise(BioDSL::OptionError) { @p.write_table(gzip: true) }
  end

  test 'BioDSL::Pipeline::WriteTable with bzip2ed data and no output ' \
    'file raises' do
    assert_raise(BioDSL::OptionError) { @p.write_table(bzip2: true) }
  end

  test 'BioDSL::Pipeline::WriteTable to file outputs gzipped data OK' do
    @p.write_table(output: @file, gzip: true).run(input: @input)
    result = `#{@zcat} #{@file}`

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |Human\t23524\tATACGTCAG
      |Dog\t2442\tAGCATGAC
      |Mouse\t234\tGACTG
      |Cat\t2342\tAAATGCA
    EXP

    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable to file outputs bzip2ed data OK' do
    @p.write_table(output: @file, bzip2: true).run(input: @input)
    result = `bzcat #{@file}`

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |Human\t23524\tATACGTCAG
      |Dog\t2442\tAGCATGAC
      |Mouse\t234\tGACTG
      |Cat\t2342\tAAATGCA
    EXP

    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteTable with both gzip and bzip2 output ' \
    'raises' do
    assert_raise(BioDSL::OptionError) do
      @p.write_table(output: @file, gzip: true, bzip2: true)
    end
  end

  test 'BioDSL::Pipeline::WriteTable with flux outputs correctly' do
    @p.write_table(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |Human\t23524\tATACGTCAG
      |Dog\t2442\tAGCATGAC
      |Mouse\t234\tGACTG
      |Cat\t2342\tAAATGCA
    EXP

    assert_equal(expected, result)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ORGANISM=>"Human", :COUNT=>23524, :SEQ=>"ATACGTCAG"}
      |{:ORGANISM=>"Dog", :COUNT=>2442, :SEQ=>"AGCATGAC"}
      |{:ORGANISM=>"Mouse", :COUNT=>234, :SEQ=>"GACTG"}
      |{:ORGANISM=>"Cat", :COUNT=>2342, :SEQ=>"AAATGCA"}
    EXP

    assert_equal(expected, collect_result)
  end
end
