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
# This software is part of BioDSL (http://maasha.github.io/BioDSL).            #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for the read_fasta command.
# rubocop:disable ClassLength
class TestReadFasta < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('BioDSL')

    write_fasta_data1
    write_fasta_data2

    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    write_stream_data

    @p = BioDSL::Pipeline.new
    @err = BioDSL::OptionError
  end

  def write_fasta_data1
    @file = File.join(@tmpdir, 'test.fna')

    File.open(@file, 'w') do |ios|
      ios.puts <<-EOF.gsub(/^\s+\|/, '')
        |>test1
        |atgcagcac
        |>test2
        |acagcactgA
      EOF
    end
  end

  def write_fasta_data2
    @file2 = File.join(@tmpdir, 'test2.fna')

    File.open(@file2, 'w') do |ios|
      ios.puts <<-EOF.gsub(/^\s+\|/, '')
        |>test3
        |acGTAagcac
        |>test4
        |aCCAgcactgA
      EOF
    end
  end

  def write_stream_data
    @output.write(SEQ_NAME: 'test1', SEQ: 'atgcagcac',  SEQ_LEN: 9)
    @output.write(SEQ_NAME: 'test2', SEQ: 'acagcactgA', SEQ_LEN: 10)
    @output.close
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::ReadFasta with invalid options raises' do
    assert_raise(@err) { @p.read_fasta(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::ReadFasta without required options raises' do
    assert_raise(@err) { @p.read_fasta }
  end

  test 'BioDSL::Pipeline::ReadFasta with bad first raises' do
    assert_raise(@err) { @p.read_fasta(input: @file, first: -1) }
  end

  test 'BioDSL::Pipeline::ReadFasta with bad last raises' do
    assert_raise(@err) { @p.read_fasta(input: @file, last: -1) }
  end

  test 'BioDSL::Pipeline::ReadFasta with exclusive unique options raises' do
    assert_raise(@err) { @p.read_fasta(input: @file, first: 1, last: 1) }
  end

  test 'BioDSL::Pipeline::ReadFasta with non-existing input file raises' do
    assert_raise(@err) { @p.read_fasta(input: '___adsf') }
  end

  test 'BioDSL::Pipeline::ReadFasta returns correctly' do
    @p.read_fasta(input: @file).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
       |{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}
       |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadFasta status returns correctly' do
    @p.read_fasta(input: @file).run(output: @output2)

    assert_equal(0, @p.status.first[:records_in])
    assert_equal(2, @p.status.first[:records_out])
    assert_equal(0, @p.status.first[:sequences_in])
    assert_equal(2, @p.status.first[:sequences_out])
    assert_equal(0, @p.status.first[:residues_in])
    assert_equal(19, @p.status.first[:residues_out])
  end

  test 'BioDSL::Pipeline::ReadFasta with gzipped data returns correctly' do
    `gzip #{@file}`

    @p.read_fasta(input: "#{@file}.gz").run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}
      |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadFasta with bzip2\'ed data returns correctly' do
    `bzip2 #{@file}`

    @p.read_fasta(input: "#{@file}.bz2").run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}
      |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadFasta with multiple files returns correctly' do
    @p.read_fasta(input: [@file, @file2]).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}
      |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadFasta with input glob returns correctly' do
    @p.read_fasta(input: File.join(@tmpdir, 'test*.fna')).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}
      |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadFasta with :first returns correctly' do
    @p.read_fasta(input: [@file, @file2], first: 3).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}
      |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadFasta#to_s with :first returns correctly' do
    @p.read_fasta(input: @file, first: 3)

    expected = %{BD.new.read_fasta(input: "#{@file}", first: 3)}

    assert_equal(expected, @p.to_s)
  end

  test 'BioDSL::Pipeline::ReadFasta with :last returns correctly' do
    @p.read_fasta(input: [@file, @file2], last: 3).run(output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::ReadFasta with flux returns correctly' do
    @p.read_fasta(input: @file2).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}
      |{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}
      |{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}
    EXP

    assert_equal(expected, collect_result)
  end
end
