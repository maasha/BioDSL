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

# Test class for ReadTable.
#
# rubocop: disable ClassLength
class TestReadTable < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('BioDSL')

    @data = <<-EOF.gsub(/^\s+\|/, '')
      |#ID COUNT
      |# 2014-10-14
      |TCMID104 12
      |TCMID105 123
      |TCMID106 1231
      |
    EOF

    setup_file1
    setup_file2
    setup_data

    @p = BioDSL::Pipeline.new
  end

  def setup_file1
    @file = File.join(@tmpdir, 'test.tab')

    File.open(@file, 'w') do |ios|
      ios.puts @data
    end
  end

  def setup_file2
    @file2  = File.join(@tmpdir, 'test2.tab')

    File.open(@file2, 'w') do |ios|
      ios.puts @data
    end
  end

  def setup_data
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(SEQ_NAME: 'test1', SEQ: 'atgcagcac', SEQ_LEN: 9)
    @output.write(SEQ_NAME: 'test2', SEQ: 'acagcactgA', SEQ_LEN: 10)
    @output.close
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::ReadTable with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.read_table(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::ReadTable without required options raises' do
    assert_raise(BioDSL::OptionError) { @p.read_table }
  end

  test 'BioDSL::Pipeline::ReadTable with bad first raises' do
    assert_raise(BioDSL::OptionError) do
      @p.read_table(input: @file, first: -1)
    end
  end

  test 'BioDSL::Pipeline::ReadTable with bad last raises' do
    assert_raise(BioDSL::OptionError) do
      @p.read_table(input: @file, last: -1)
    end
  end

  test 'BioDSL::Pipeline::ReadTable with exclusive unique options raises' do
    assert_raise(BioDSL::OptionError) do
      @p.read_table(input: @file, first: 1, last: 1)
    end
  end

  test 'BioDSL::Pipeline::ReadTable with non-existing input file raises' do
    assert_raise(BioDSL::OptionError) { @p.read_table(input: '___adsf') }
  end

  test 'BioDSL::Pipeline::ReadTable with duplicate keys raises' do
    assert_raise(BioDSL::OptionError) do
      @p.read_table(input: @file, keys: [:a, :a])
    end
  end

  test 'BioDSL::Pipeline::ReadTable with duplicate select raises' do
    assert_raise(BioDSL::OptionError) do
      @p.read_table(input: @file, select: [1, 1])
    end
  end

  test 'BioDSL::Pipeline::ReadTable with duplicate reject raises' do
    assert_raise(BioDSL::OptionError) do
      @p.read_table(input: @file, reject: [1, 1])
    end
  end

  test 'BioDSL::Pipeline::ReadTable returns correctly' do
    @p.read_table(input: @file).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable status returns correctly' do
    @p.read_table(input: @file).run(output: @output2)

    assert_equal(0, @p.status.first[:records_in])
    assert_equal(3, @p.status.first[:records_out])
  end

  test 'BioDSL::Pipeline::ReadTable with :skip returns correctly' do
    @p.read_table(input: @file, skip: 2).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:V0=>"TCMID104", :V1=>12}
      |{:V0=>"TCMID105", :V1=>123}
      |{:V0=>"TCMID106", :V1=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with :delimeter returns correctly' do
    @p.read_table(input: @file, skip: 2, delimiter: 'ID').run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:V0=>"TCM", :V1=>"104 12"}
      |{:V0=>"TCM", :V1=>"105 123"}
      |{:V0=>"TCM", :V1=>"106 1231"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with :select returns correctly' do
    @p.read_table(input: @file, select: [:COUNT]).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:COUNT=>12}
      |{:COUNT=>123}
      |{:COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with :reject returns correctly' do
    @p.read_table(input: @file, reject: [:COUNT]).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"TCMID104"}
      |{:ID=>"TCMID105"}
      |{:ID=>"TCMID106"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with :keys returns correctly' do
    @p.read_table(input: @file, keys: ['FOO', :BAR]).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FOO=>"TCMID104", :BAR=>12}
      |{:FOO=>"TCMID105", :BAR=>123}
      |{:FOO=>"TCMID106", :BAR=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with :skip and :keys returns OK' do
    @p.read_table(input: @file, skip: 2, keys: ['FOO', :BAR]).
      run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FOO=>"TCMID104", :BAR=>12}
      |{:FOO=>"TCMID105", :BAR=>123}
      |{:FOO=>"TCMID106", :BAR=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with gzipped data returns correctly' do
    `gzip #{@file}`

    @p.read_table(input: "#{@file}.gz").run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with bzip2\'ed data returns correctly' do
    `bzip2 #{@file}`

    @p.read_table(input: "#{@file}.bz2").run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with multiple files returns correctly' do
    @p.read_table(input: [@file, @file2]).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with input glob returns correctly' do
    @p.read_table(input: File.join(@tmpdir, 'test*.tab')).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with :first returns correctly' do
    @p.read_table(input: [@file, @file2], first: 3).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable#to_s with :first returns correctly' do
    @p.read_table(input: @file, first: 3)

    expected = %{BP.new.read_table(input: "#{@file}", first: 3)}

    assert_equal(expected, @p.to_s)
  end

  test 'BioDSL::Pipeline::ReadTable with :last returns correctly' do
    @p.read_table(input: [@file, @file2], last: 2).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadTable with flux returns correctly' do
    @p.read_table(input: @file2).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}
      |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
      |{:ID=>"TCMID104", :COUNT=>12}
      |{:ID=>"TCMID105", :COUNT=>123}
      |{:ID=>"TCMID106", :COUNT=>1231}
    EXP

    assert_equal(expected, collect_result)
  end
end
