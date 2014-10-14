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

class TestWriteFastq < Test::Unit::TestCase 
  def setup
    @zcat = BioPieces::Filesys::which('gzcat') || BioPieces::Filesys::which('zcat')

    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.fq')
    @file2  = File.join(@tmpdir, 'test.fq')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    hash1 = {SEQ_NAME: "test1", SEQ: "atcg", SEQ_LEN: 4, SCORES: "!!II"}
    hash2 = {SEQ_NAME: "test2", SEQ: "gtac", SEQ_LEN: 4, SCORES: "!!II"}

    @output.write hash1
    @output.write hash2
    @output.close

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::WriteFastq with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.write_fastq(foo: "bar") }
  end

  test "BioPieces::Pipeline::WriteFastq with invalid encoding raises" do
    assert_raise(BioPieces::OptionError) { @p.write_fastq(encoding: "foo") }
  end

  test "BioPieces::Pipeline::WriteFastq with valid encoding don't raise" do
    assert_nothing_raised { @p.write_fastq(encoding: :base_33) }
    assert_nothing_raised { @p.write_fastq(encoding: :base_64) }
  end

  test "BioPieces::Pipeline::WriteFastq to stdout outputs correctly" do
    result = capture_stdout { @p.write_fastq.run(input: @input) }
    expected = "@test1\natcg\n+\n!!II\n@test2\ngtac\n+\n!!II\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFastq status outputs correctly" do
    capture_stdout { @p.write_fastq.run(input: @input) }
    assert_equal(2, @p.status[:status].first[:sequences_out])
    assert_equal(8, @p.status[:status].first[:residues_out])
  end

  test "BioPieces::Pipeline::WriteFastq to stdout with base 64 encoding outputs correctly" do
    result = capture_stdout { @p.write_fastq(encoding: :base_64).run(input: @input) }
    expected = "@test1\natcg\n+\n@@hh\n@test2\ngtac\n+\n@@hh\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFastq to file outputs correctly" do
    @p.write_fastq(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "@test1\natcg\n+\n!!II\n@test2\ngtac\n+\n!!II\n"
    assert_equal(expected, result)
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFastq to existing file raises" do
    `touch #{@file}`
    assert_raise(BioPieces::OptionError) { @p.write_fastq(output: @file) }
  end

  test "BioPieces::Pipeline::WriteFastq to existing file with options[:force] outputs correctly" do
    `touch #{@file}`
    @p.write_fastq(output: @file, force: true).run(input: @input)
    result = File.open(@file).read
    expected = "@test1\natcg\n+\n!!II\n@test2\ngtac\n+\n!!II\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFastq with gzipped data and no output file raises" do
    assert_raise(BioPieces::OptionError) { @p.write_fastq(gzip: true) }
  end

  test "BioPieces::Pipeline::WriteFastq with bzip2'ed data and no output file raises" do
    assert_raise(BioPieces::OptionError) { @p.write_fastq(bzip2: true) }
  end

  test "BioPieces::Pipeline::WriteFastq to file outputs gzipped data correctly" do
    @p.write_fastq(output: @file, gzip: true).run(input: @input)
    result = `#{@zcat} #{@file}`
    expected = "@test1\natcg\n+\n!!II\n@test2\ngtac\n+\n!!II\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFastq to file outputs bzip2'ed data correctly" do
    @p.write_fastq(output: @file, bzip2: true).run(input: @input)
    result = `bzcat #{@file}`
    expected = "@test1\natcg\n+\n!!II\n@test2\ngtac\n+\n!!II\n"
    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::WriteFastq with both gzip and bzip2 output raises" do
    assert_raise(BioPieces::OptionError) { @p.write_fastq(output: @file, gzip: true, bzip2: true) }
  end

  test "BioPieces::Pipeline::WriteFastq with flux outputs correctly" do
    @p.write_fastq(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = "@test1\natcg\n+\n!!II\n@test2\ngtac\n+\n!!II\n"
    assert_equal(expected, result)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4, :SCORES=>"!!II"}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"gtac", :SEQ_LEN=>4, :SCORES=>"!!II"}'
    assert_equal(stream_expected, stream_result)
  end
end
