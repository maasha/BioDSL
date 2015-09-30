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

# Test class for Count.
class TestCount < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('BioDSL')
    @file   = File.join(@tmpdir, 'test.txt')
    @file2  = File.join(@tmpdir, 'test.txt')

    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(SEQ_NAME: 'test1', SEQ: 'atcg', SEQ_LEN: 4)
    @output.write(SEQ_NAME: 'test2', SEQ: 'gtac', SEQ_LEN: 4)
    @output.close

    @p = BioDSL::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::Count with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.count(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::Count with valid options don\'t raise' do
    assert_nothing_raised { @p.count(output: @file) }
  end

  test 'BioDSL::Pipeline::Count to file outputs correctly' do
    @p.count(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "#RECORD_TYPE\tCOUNT\ncount\t2\n"
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::Count to existing file raises' do
    `touch #{@file}`
    assert_raise(BioDSL::OptionError) { @p.count(output: @file) }
  end

  test 'BioDSL::Pipeline::Count to existing file with :force outputs OK' do
    `touch #{@file}`
    @p.count(output: @file, force: true).run(input: @input)
    result = File.open(@file).read
    expected = "#RECORD_TYPE\tCOUNT\ncount\t2\n"
    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::Count with flux outputs correctly' do
    @p.count(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "#RECORD_TYPE\tCOUNT\ncount\t2\n"
    assert_equal(expected, result)

    stream_expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"test2", :SEQ=>"gtac", :SEQ_LEN=>4}
      |{:RECORD_TYPE=>"count", :COUNT=>2}
    EXP

    assert_equal(stream_expected, collect_result)
  end

  test 'BioDSL::Pipeline::Count status outputs correctly' do
    @p.count.run(input: @input, output: @output2)

    assert_equal(2, @p.status.first[:records_in])
    assert_equal(3, @p.status.first[:records_out])
  end
end
