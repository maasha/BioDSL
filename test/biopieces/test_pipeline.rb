#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

class PipelineTest < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @p = BioPieces::Pipeline.new
    @fasta_file  = File.join(@tmpdir, "test.fna")
    @fasta_file2 = File.join(@tmpdir, "test2.fna")

    File.open(@fasta_file, 'w') do |ios|
      ios.puts ">test1\natcg\n>test2\ntgac"
    end
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline#run with no commands raises" do
    assert_raise(BioPieces::PipelineError) { @p.run }
  end

  test "BioPieces::Pipeline#to_s with no commands raises" do
    assert_raise(BioPieces::PipelineError) { @p.to_s }
  end

  test "BioPieces::Pipeline#add with non-existing command raises" do
    assert_raise(BioPieces::PipelineError) { @p.add(:foo) }
  end

  test "BioPieces::Pipeline#to_s without .run() returns correctly" do
    expected = %{BioPieces::Pipeline.new.add(:read_fasta, input: ["#{@fasta_file}"])}
    assert_equal(expected, @p.add(:read_fasta, input: @fasta_file).to_s)
  end

  test "BioPieces::Pipeline#to_s with add without options and .run() returns correctly" do
    expected = %{BioPieces::Pipeline.new.add(:read_fasta, input: ["#{@fasta_file}"]).add(:dump).run}
    capture_stdout { @p.add(:read_fasta, input: @fasta_file).add(:dump).run }
    assert_equal(expected, @p.to_s)
  end

  test "BioPieces::Pipeline#to_s with grab strangeness correctly" do
    expected = %{BioPieces::Pipeline.new.add(:read_fasta, input: ["#{@fasta_file}"]).add(:grab, select: "foo").run}
    capture_stdout { @p.add(:read_fasta, input: @fasta_file).add(:grab, select: "foo").run }
    assert_equal(expected, @p.to_s)
  end

  test "BioPieces::Pipeline#to_s with .run() and options returns correctly" do
    expected = %{BioPieces::Pipeline.new.add(:read_fasta, input: ["#{@fasta_file}"]).run(verbose: false)}
    @p.expects(:status).returns(expected)
    assert_equal(expected, @p.add(:read_fasta, input: @fasta_file).run(verbose: false).to_s)
  end

  test "BioPieces::Pipeline#status without .run() returns correctly" do
    assert_equal({}, @p.add(:read_fasta, input: @fasta_file).status)
  end

  test "BioPieces::Pipeline#status with .run() returns correctly" do
    expected = %{BioPieces::Pipeline.new.add(:read_fasta, input: ["#{@fasta_file}"])}
    @p.expects(:status).returns(expected)
    assert_equal(expected, @p.add(:read_fasta, input: @fasta_file).run.status)
  end

  test "BioPieces::Pipeline#run with disallowed option raises" do
    assert_raise(BioPieces::OptionError) { @p.add(:read_fasta, input: @fasta_file).run(foo: "bar") }
  end

  test "BioPieces::Pipeline#run with verbose returns correctly" do
    stdout   = capture_stdout { @p.add(:read_fasta, input: @fasta_file).run(verbose: true) }
    expected = capture_stdout { pp @p.status } 
    assert_equal(expected, stdout)
  end

  test "BioPieces::Pipeline#run returns correctly" do
    @p.add(:read_fasta, input: @fasta_file).add(:write_fasta, output: @fasta_file2).run 

    result = nil

    File.open(@fasta_file2) do |ios|
      result = ios.read
    end

    assert_equal(">test1\natcg\n>test2\ntgac\n", result)
  end
end

