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

class TestReadFasta < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.fna')

    File.open(@file, 'w') do |ios|
      ios.puts <<EOF
>test1
atgcagcac
>test2
acagcactgA
EOF
    end

    @file2 = File.join(@tmpdir, 'test2.fna')

    File.open(@file2, 'w') do |ios|
      ios.puts <<EOF
>test3
acGTAagcac
>test4
aCCAgcactgA
EOF
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

  test "BioPieces::Pipeline::ReadFasta with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fasta(foo: "bar") }
  end

  test "BioPieces::Pipeline::ReadFasta without required options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fasta() }
  end

  test "BioPieces::Pipeline::ReadFasta with bad first raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fasta(input: @file, first: -1) }
  end

  test "BioPieces::Pipeline::ReadFasta with bad last raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fasta(input: @file, last: -1) }
  end

  test "BioPieces::Pipeline::ReadFasta with exclusive unique options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fasta(input: @file, first: 1, last: 1) }
  end

  test "BioPieces::Pipeline::ReadFasta with non-existing input file raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fasta(input: "___adsf") }
  end

  test "BioPieces::Pipeline::ReadFasta returns correctly" do
    @p.read_fasta(input: @file).run(output: @output2)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFasta status returns correctly" do
    @p.read_fasta(input: @file).run(output: @output2)

    assert_equal(2, @p.status[:status].first[:sequences_in])
    assert_equal(19, @p.status[:status].first[:residues_in])
  end

  test "BioPieces::Pipeline::ReadFasta with gzipped data returns correctly" do
    `gzip #{@file}`

    @p.read_fasta(input: "#{@file}.gz").run(output: @output2)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFasta with bzip2'ed data returns correctly" do
    `bzip2 #{@file}`

    @p.read_fasta(input: "#{@file}.bz2").run(output: @output2)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFasta with multiple files returns correctly" do
    @p.read_fasta(input: [@file, @file2]).run(output: @output2)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}'

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFasta with input glob returns correctly" do
    @p.read_fasta(input: File.join(@tmpdir, "test*.fna")).run(output: @output2)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}'

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFasta with options[:first] returns correctly" do
    @p.read_fasta(input: [@file, @file2], first: 3).run(output: @output2)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}'

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFasta#to_s with options[:first] returns correctly" do
    @p.read_fasta(input: @file, first: 3)

    expected = %{BP.new.read_fasta(input: "#{@file}", first: 3)}

    assert_equal(expected, @p.to_s)
  end

  test "BioPieces::Pipeline::ReadFasta with options[:last] returns correctly" do
    @p.read_fasta(input: [@file, @file2], last: 3).run(output: @output2)

    expected = ""
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}'

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFasta with flux returns correctly" do
    @p.read_fasta(input: @file2).run(input: @input, output: @output2)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}'

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end
end
