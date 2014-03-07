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

class TestWriteFasta < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.fna')
    @file2  = File.join(@tmpdir, 'test.fna')

    @input, @output   = BioPieces::Pipeline::Stream.pipe
    @input2, @output2 = BioPieces::Pipeline::Stream.pipe

    hash1 = {SEQ_NAME: "test1", SEQ: "atcg", SEQ_LEN: 4}
    hash2 = {SEQ_NAME: "test2", SEQ: "gtac", SEQ_LEN: 4}

    @output.write hash1
    @output.write hash2
    @output.close
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::WriteFasta with invalid options raises" do
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:write_fasta, foo: "bar") }
  end

  test "BioPieces::Pipeline::WriteFasta to stdout outputs correctly" do
    command = BioPieces::Pipeline::Command.new(:write_fasta)
    result = capture_stdout { command.run(@input, nil) }
    expected = ">test1\natcg\n>test2\ngtac\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFasta with options[:wrap] outputs correctly" do
    command = BioPieces::Pipeline::Command.new(:write_fasta, wrap: 2)
    result = capture_stdout { command.run(@input, nil) }
    expected = ">test1\nat\ncg\n>test2\ngt\nac\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFasta to file outputs correctly" do
    command = BioPieces::Pipeline::Command.new(:write_fasta, output: @file)
    command.run(@input, nil)
    result = File.open(@file).read
    expected = ">test1\natcg\n>test2\ngtac\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFasta to existing file raises" do
    `touch #{@file}`
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:write_fasta, output: @file) }
  end

  test "BioPieces::Pipeline::WriteFasta to existing file with options[:force] outputs correctly" do
    `touch #{@file}`
    command = BioPieces::Pipeline::Command.new(:write_fasta, output: @file, force: true)
    command.run(@input, nil)
    result = File.open(@file).read
    expected = ">test1\natcg\n>test2\ngtac\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFasta with gzipped data and no output file raises" do
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:write_fasta, gzip: true) }
  end

  test "BioPieces::Pipeline::WriteFasta with bzip2'ed data and no output file raises" do
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:write_fasta, bzip2: true) }
  end

  test "BioPieces::Pipeline::WriteFasta to file outputs gzipped data correctly" do
    command = BioPieces::Pipeline::Command.new(:write_fasta, output: @file, gzip: true)
    command.run(@input, nil)
    result = `zcat #{@file}`
    expected = ">test1\natcg\n>test2\ngtac\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFasta to file outputs bzip2'ed data correctly" do
    command = BioPieces::Pipeline::Command.new(:write_fasta, output: @file, bzip2: true)
    command.run(@input, nil)
    result = `bzcat #{@file}`
    expected = ">test1\natcg\n>test2\ngtac\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFasta with both gzip and bzip2 output raises" do
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:write_fasta, output: @file, gzip: true, bzip2: true) }
  end

  test "BioPieces::Pipeline::WriteFasta with flux outputs correctly" do
    command = BioPieces::Pipeline::Command.new(:write_fasta, output: @file)
    command.run(@input, @output2)
    result = File.open(@file).read
    expected = ">test1\natcg\n>test2\ngtac\n"
    assert_equal(expected, result)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"gtac", :SEQ_LEN=>4}'
    assert_equal(stream_expected, stream_result)
  end
end
