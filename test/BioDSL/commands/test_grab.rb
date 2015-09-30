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

# Test class for the grab command.
# rubocop:disable ClassLength
class TestGrab < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('BioDSL')

    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    write_stream
    write_test_file1
    write_test_file2

    @p = BioDSL::Pipeline.new
    @e = BioDSL::OptionError
  end

  def write_stream
    @output.write(SEQ_NAME: 'test1', SEQ: 'atcg', SEQ_LEN: 4)
    @output.write(SEQ_NAME: 'test2', SEQ: 'DSEQM', SEQ_LEN: 5)
    @output.write(FOO: 'SEQ')
    @output.close
  end

  def write_test_file1
    @pattern_file  = File.join(@tmpdir, 'patterns.txt')

    File.open(@pattern_file, 'w') do |ios|
      ios.puts 'test'
      ios.puts 'seq'
    end
  end

  def write_test_file2
    @pattern_file2 = File.join(@tmpdir, 'patterns2.txt')

    File.open(@pattern_file2, 'w') do |ios|
      ios.puts 4
      ios.puts 'SEQ'
    end
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::Grab with invalid options raises' do
    assert_raise(@e) { @p.grab(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::Grab with select and reject raises' do
    assert_raise(@e) { @p.grab(select: 'foo', reject: 'bar') }
  end

  test 'BioDSL::Pipeline::Grab with keys_only and values_only raises' do
    assert_raise(@e) do
      @p.grab(select: 'foo', keys_only: true, values_only: true)
    end
  end

  test 'BioDSL::Pipeline::Grab with evaluate and conflicting keys raises' do
    assert_raise(@e) { @p.grab(evaluate: 0, select: 'foo') }
    assert_raise(@e) { @p.grab(evaluate: 0, reject: 'foo') }
    assert_raise(@e) { @p.grab(evaluate: 0, keys: 'foo') }
    assert_raise(@e) { @p.grab(evaluate: 0, keys_only: true) }
    assert_raise(@e) { @p.grab(evaluate: 0, values_only: true) }
    assert_raise(@e) { @p.grab(evaluate: 0, ignore_case: true) }
    assert_raise(@e) { @p.grab(evaluate: 0, exact: true) }
  end

  test 'BioDSL::Pipeline::Grab with missing select_file raises' do
    assert_raise(@e) { @p.grab(select_file: '___select') }
  end

  test 'BioDSL::Pipeline::Grab with missing reject_file raises' do
    assert_raise(@e) { @p.grab(reject_file: '___reject') }
  end

  test 'BioDSL::Pipeline::Grab#to_s with select and symbol key return OK' do
    @p.grab(select: :SEQ_NAME)
    expected = 'BP.new.grab(select: :SEQ_NAME)'
    assert_equal(expected, @p.to_s)
  end

  test 'BioDSL::Pipeline::Grab with no hits return OK' do
    @p.grab(select: 'fish').run(input: @input, output: @output2)
    assert_equal('', collect_result)
  end

  test 'BioDSL::Pipeline::Grab with select and key hit return OK' do
    @p.grab(select: 'SEQ_NAME').run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
    EXP
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab status returns correctly' do
    @p.grab(select: 'SEQ_NAME').run(input: @input, output: @output2)

    assert_equal(3, @p.status.first[:records_in])
    assert_equal(2, @p.status.first[:records_out])
  end

  test 'BioDSL::Pipeline::Grab with multiple select patterns return OK' do
    @p.grab(select: %w(est1 QM)).run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
    EXP
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with multiple reject patterns return OK' do
    @p.grab(reject: %w(est QM)).run(input: @input, output: @output2)
    expected = %({:FOO=>"SEQ"}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with reject and key hit return OK' do
    @p.grab(reject: 'SEQ_NAME').run(input: @input, output: @output2)
    expected = %({:FOO=>"SEQ"}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with reject with symbol return OK' do
    @p.grab(reject: :SEQ_NAME).run(input: @input, output: @output2)
    expected = %({:FOO=>"SEQ"}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with select and value hit return OK' do
    @p.grab(select: 'test1').run(input: @input, output: @output2)
    expected = %({:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with reject and value hit return OK' do
    @p.grab(reject: 'test1').run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
      |{:FOO=>"SEQ"}
    EXP
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with select and keys_only return OK' do
    @p.grab(select: 'SEQ', keys_only: true).run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
    EXP
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with reject and keys_only return OK' do
    @p.grab(reject: 'SEQ', keys_only: true).run(input: @input, output: @output2)
    expected = %({:FOO=>"SEQ"}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with select and values_only return OK' do
    @p.grab(select: 'SEQ', values_only: true).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
      |{:FOO=>"SEQ"}
    EXP
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with reject and values_only return OK' do
    @p.grab(reject: 'SEQ', values_only: true).
      run(input: @input, output: @output2)

    expected = %({:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select and values_only and ^ return OK' do
    @p.grab(select: '^SEQ', values_only: true).
      run(input: @input, output: @output2)

    expected = %({:FOO=>"SEQ"}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. reject and values_only and ^ return OK' do
    @p.grab(reject: '^SEQ', values_only: true).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
    EXP
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with select and ignore_case return OK' do
    @p.grab(select: 'ATCG', ignore_case: true).
      run(input: @input, output: @output2)

    expected = %({:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with reject and ignore_case return OK' do
    @p.grab(reject: 'ATCG', ignore_case: true).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
      |{:FOO=>"SEQ"}
    EXP
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with select and specified keys return OK' do
    @p.grab(select: 'SEQ', keys: :FOO).run(input: @input, output: @output2)
    expected = %({:FOO=>"SEQ"}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select and keys in Array return OK' do
    @p.grab(select: 'SEQ', values_only: true, keys: [:FOO, :SEQ]).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with select and keys in String return OK' do
    @p.grab(select: 'SEQ', values_only: true, keys: ':FOO, :SEQ').
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with reject and specified keys return OK' do
    @p.grab(reject: 'SEQ', keys: :FOO).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with evaluate return OK' do
    @p.grab(evaluate: ':SEQ_LEN > 4').run(input: @input, output: @output2)

    expected = %({:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with select_file return OK' do
    @p.grab(select_file: @pattern_file).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select and exact w/o match return OK' do
    @p.grab(select: 'tcg', exact: true).run(input: @input, output: @output2)

    assert_equal('', collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select and exact match return OK' do
    @p.grab(select: 'atcg', exact: true).run(input: @input, output: @output2)

    expected = %({:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select and exact number match return OK' do
    @p.grab(select: 4, exact: true).run(input: @input, output: @output2)

    expected = %({:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select, exact number and keys_only OK' do
    @p.grab(select: 4, exact: true, keys_only: true).
      run(input: @input, output: @output2)

    assert_equal('', collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select, exact number and values_only OK' do
    @p.grab(select: 4, exact: true, values_only: true).
      run(input: @input, output: @output2)

    expected = %({:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select, exact, keys and no match OK' do
    @p.grab(select: 'atcg', exact: true, keys: :SEQ_LEN).
      run(input: @input, output: @output2)

    assert_equal('', collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select, exact, keys and match return OK' do
    @p.grab(select: 'atcg', exact: true, keys: :SEQ).
      run(input: @input, output: @output2)

    expected = %({:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select, exact, keys_only and no match ' \
       'return OK' do
    @p.grab(select: 'atcg', exact: true, keys_only: true).
      run(input: @input, output: @output2)

    assert_equal('', collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select, exact, keys_only and String ' \
       'match return OK' do
    @p.grab(select: 'FOO', exact: true, keys_only: true).
      run(input: @input, output: @output2)

    expected = %({:FOO=>"SEQ"}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab w. select, exact, keys_only and Symbol ' \
       'match return OK' do
    @p.grab(select: :FOO, exact: true, keys_only: true).
      run(input: @input, output: @output2)

    expected = %({:FOO=>"SEQ"}\n)
    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::Grab with reject_file return OK' do
    @p.grab(reject_file: @pattern_file2, values_only: true, keys: :SEQ).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected, collect_result)
  end
end
