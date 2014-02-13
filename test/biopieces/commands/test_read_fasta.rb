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
require 'tempfile'

class TestReadFasta < Test::Unit::TestCase 
  def setup
    @file = Tempfile.new('test')

    File.open(@file, 'w') do |ios|
      ios.puts <<EOF
>test1
atgcagcac
>test2
acagcactgA
EOF
    end

    @file2 = Tempfile.new('test2')

    File.open(@file2, 'w') do |ios|
      ios.puts <<EOF
>test3
acGTAagcac
>test4
aCCAgcactgA
EOF
    end

    @input, @output = BioPieces::Pipeline::Stream.pipe
  end

  def teardown
    @file.close
    @file.unlink
    @file2.close
    @file2.unlink
  end

  test "BioPieces::Pipeline::ReadFasta with invalid option raises" do
    command = BioPieces::Pipeline::Command.new(:read_fasta, foo: "bar")
    assert_raise(BioPieces::OptionError) { command.run(nil, nil) }
  end

  test "BioPieces::Pipeline::ReadFasta without required option raises" do
    command = BioPieces::Pipeline::Command.new(:read_fasta)
    assert_raise(BioPieces::OptionError) { command.run(nil, nil) }
  end

  test "BioPieces::Pipeline::ReadFasta returns correctly" do
    output = StringIO.new("", 'w')
    command = BioPieces::Pipeline::Command.new(:read_fasta, input: @file)
    command.run(nil, output)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'

    assert_equal(expected, output.string)
  end

  test "BioPieces::Pipeline::ReadFasta with multiple files returns correctly" do
    output = StringIO.new("", 'w')
    command = BioPieces::Pipeline::Command.new(:read_fasta, input: [@file, @file2])
    command.run(nil, output)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}'

    assert_equal(expected, output.string)
  end

  test "BioPieces::Pipeline::ReadFasta with options[:first] returns correctly" do
    output = StringIO.new("", 'w')
    command = BioPieces::Pipeline::Command.new(:read_fasta, input: [@file, @file2], first: 3)
    command.run(nil, output)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}'

    assert_equal(expected, output.string)
  end

  test "BioPieces::Pipeline::ReadFasta with options[:last] returns correctly" do
    output = StringIO.new("", 'w')
    command = BioPieces::Pipeline::Command.new(:read_fasta, input: [@file, @file2], last: 3)
    command.run(nil, output)

    expected = ""
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test3", :SEQ=>"acGTAagcac", :SEQ_LEN=>10}'
    expected << '{:SEQ_NAME=>"test4", :SEQ=>"aCCAgcactgA", :SEQ_LEN=>11}'

    assert_equal(expected, output.string)
  end

  test "BioPieces::Pipeline::ReadFasta with flux returns correctly" do
    command = BioPieces::Pipeline::Command.new(:read_fasta, input: @file)
    command.run(nil, @output)

    result = @input.map { |h| h.to_s }.reduce(:<<)

    expected = ""
    expected << '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    expected << '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'

    assert_equal(expected, result)
  end
end