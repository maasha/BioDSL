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

class TestReadFastq < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.fq')

    File.open(@file, 'w') do |ios|
      ios.puts <<EOF
@base_33
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
+
!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
@base_64
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
+
;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
EOF
    end

    @file2 = File.join(@tmpdir, 'test2.fq')

    File.open(@file2, 'w') do |ios|
      ios.puts <<EOF
@M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14
TGGGGAATATTGGACAATGGGGGCAACCCTGATCCAGCA
+
<??????BDDDDDDDDGGGGGGGHHIIIEHIHHFGGHFH
@M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14
TAGGGAATCTTGCACAATGGAGGAAACTCTGATGCAGCG
+
<???9?BBBDBDDBDDFFFFFFHHHIFHFHHIHHFHHHH
EOF
    end

    @file3 = File.join(@tmpdir, 'test3.fq')

    File.open(@file3, 'w') do |ios|
      ios.puts <<EOF
@M01168:16:000000000-A1R9L:1:1101:14862:1868 2:N:0:14
CCTGTTTGCTACCCACGCTTTCGTACCTCAGCGTCAGTA
+
?????BB<-<BDDDDDFEEFFFHFFHI;F;EGHHDHEF9
@M01168:16:000000000-A1R9L:1:1101:13906:2139 2:N:0:14
ACTCTTCGCTACCCATGCTTTCGTTCCTCAGCGTCAGTA
+
,5<??BB?DDABDBDDFFFFFFHFHIHFHHIIHEHEHF?
EOF
    end

    @file4 = File.join(@tmpdir, 'base64.fastq')

    File.open(@file4, 'w') do |ios|
      ios.puts <<EOF
@base_64
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
+
;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
EOF
    end

    @file5 = File.join(@tmpdir, 'base64_2.fastq')

    File.open(@file5, 'w') do |ios|
      ios.puts <<EOF
@base_64_2
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
+
=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|
EOF
    end

    @file6 = File.join(@tmpdir, 'inconclusive.fastq')

    File.open(@file6, 'w') do |ios|
      ios.puts <<EOF
@base_base33
bbbbbbbbbbbbbbbb
+
;<=>?@ABCDEFGHIJ
EOF
    end

    hash1 = '{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}'
    hash2 = '{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}'

    @input, @output   = BioPieces::Pipeline::Stream.pipe
    @input2, @output2 = BioPieces::Pipeline::Stream.pipe

    @output.write hash1
    @output.write hash2
    @output.close

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::ReadFastq with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq(foo: "bar") }
  end

  test "BioPieces::Pipeline::ReadFastq without required options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq() }
  end

  test "BioPieces::Pipeline::ReadFastq with bad first raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq(input: @file, first: -1) }
  end

  test "BioPieces::Pipeline::ReadFastq with bad last raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq(input: @file, last: -1) }
  end

  test "BioPieces::Pipeline::ReadFastq with exclusive unique options raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq(input: @file, first: 1, last: 1) }
  end

  test "BioPieces::Pipeline::ReadFastq with non-existing input file raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq(input: "___adsf") }
  end

  test "BioPieces::Pipeline::ReadFastq with non-existing input2 file raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq(input: "___adsf", input2: "___xsdf") }
  end

  test "BioPieces::Pipeline::ReadFastq with uneven sized input and input2 raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq(input: [@file, @file2], input2: @file3).run }
  end

  test "BioPieces::Pipeline::ReadFastq with input and non-conclusive encoding raises" do
    assert_raise(BioPieces::SeqError) { @p.read_fastq(input: @file6).run }
  end

  test "BioPieces::Pipeline::ReadFastq with input and input2 and non-conclusive encoding raises" do
    assert_raise(BioPieces::SeqError) { @p.read_fastq(input: @file6, input2: @file6).run }
  end

  test "BioPieces::Pipeline::ReadFastq with encoding and bad value raises" do
    assert_raise(BioPieces::OptionError) { @p.read_fastq(input: @file6, encoding: :foo).run }
  end

  test "BioPieces::Pipeline::ReadFastq with encoding: :auto don't raise" do
    assert_nothing_raised { @p.read_fastq(input: @file, encoding: :auto).run }
  end

  test "BioPieces::Pipeline::ReadFastq with encoding: :base_33 don't raise" do
    assert_nothing_raised { @p.read_fastq(input: @file2, encoding: :base_33).run }
  end

  test "BioPieces::Pipeline::ReadFastq with encoding: :base_64 don't raise" do
    assert_nothing_raised { @p.read_fastq(input: @file4, encoding: :base_64).run }
  end

  test "BioPieces::Pipeline::ReadFastq returns correctly" do
    @p.read_fastq(input: @file).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"base_33", :SEQ=>"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", :SEQ_LEN=>94, :SCORES=>"!\\\"\\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>";<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq status returns correctly" do
    @p.read_fastq(input: @file).run(output: @output2)

    assert_equal(2,   @p.status[:status].first[:fastq_in])
    assert_equal(162, @p.status[:status].first[:residues_in])
  end

  test "BioPieces::Pipeline::ReadFastq with gzipped data returns correctly" do
    `gzip #{@file}`

    @p.read_fastq(input: "#{@file}.gz").run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"base_33", :SEQ=>"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", :SEQ_LEN=>94, :SCORES=>"!\\\"\\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>";<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with bzip2'ed data returns correctly" do
    `bzip2 #{@file}`

    @p.read_fastq(input: "#{@file}.bz2").run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"base_33", :SEQ=>"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", :SEQ_LEN=>94, :SCORES=>"!\\\"\\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>";<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with multiple files returns correctly" do
    @p.read_fastq(input: [@file, @file2]).run(output: @output2)

    expected = ""

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    expected << %Q{{:SEQ_NAME=>"base_33", :SEQ=>"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", :SEQ_LEN=>94, :SCORES=>"!\\\"\\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>";<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14", :SEQ=>"TGGGGAATATTGGACAATGGGGGCAACCCTGATCCAGCA", :SEQ_LEN=>39, :SCORES=>"<??????BDDDDDDDDGGGGGGGHHIIIEHIHHFGGHFH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14", :SEQ=>"TAGGGAATCTTGCACAATGGAGGAAACTCTGATGCAGCG", :SEQ_LEN=>39, :SCORES=>"<???9?BBBDBDDBDDFFFFFFHHHIFHFHHIHHFHHHH"}}

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with input glob returns correctly" do
    @p.read_fastq(input: File.join(@tmpdir, "test*.fq")).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"base_33", :SEQ=>"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", :SEQ_LEN=>94, :SCORES=>"!\\\"\\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>";<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14", :SEQ=>"TGGGGAATATTGGACAATGGGGGCAACCCTGATCCAGCA", :SEQ_LEN=>39, :SCORES=>"<??????BDDDDDDDDGGGGGGGHHIIIEHIHHFGGHFH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14", :SEQ=>"TAGGGAATCTTGCACAATGGAGGAAACTCTGATGCAGCG", :SEQ_LEN=>39, :SCORES=>"<???9?BBBDBDDBDDFFFFFFHHHIFHFHHIHHFHHHH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 2:N:0:14", :SEQ=>"CCTGTTTGCTACCCACGCTTTCGTACCTCAGCGTCAGTA", :SEQ_LEN=>39, :SCORES=>"?????BB<-<BDDDDDFEEFFFHFFHI;F;EGHHDHEF9"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 2:N:0:14", :SEQ=>"ACTCTTCGCTACCCATGCTTTCGTTCCTCAGCGTCAGTA", :SEQ_LEN=>39, :SCORES=>",5<??BB?DDABDBDDFFFFFFHFHIHFHHIIHEHEHF?"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with options[:first] returns correctly" do
    @p.read_fastq(input: [@file, @file2], first: 3).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"base_33", :SEQ=>"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", :SEQ_LEN=>94, :SCORES=>"!\\\"\\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>";<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14", :SEQ=>"TGGGGAATATTGGACAATGGGGGCAACCCTGATCCAGCA", :SEQ_LEN=>39, :SCORES=>"<??????BDDDDDDDDGGGGGGGHHIIIEHIHHFGGHFH"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq#to_s with options[:first] returns correctly" do
    @p.read_fastq(input: @file, first: 3)

    expected = %{BP.new.read_fastq(input: "#{@file}", first: 3)}

    assert_equal(expected, @p.to_s)
  end

  test "BioPieces::Pipeline::ReadFastq with options[:last] returns correctly" do
    @p.read_fastq(input: [@file, @file2], last: 3).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>";<=>?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14", :SEQ=>"TGGGGAATATTGGACAATGGGGGCAACCCTGATCCAGCA", :SEQ_LEN=>39, :SCORES=>"<??????BDDDDDDDDGGGGGGGHHIIIEHIHHFGGHFH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14", :SEQ=>"TAGGGAATCTTGCACAATGGAGGAAACTCTGATGCAGCG", :SEQ_LEN=>39, :SCORES=>"<???9?BBBDBDDBDDFFFFFFHHHIFHFHHIHHFHHHH"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with :input and :input2 returns correctly" do
    @p.read_fastq(input: @file2, input2: @file3).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14", :SEQ=>"TGGGGAATATTGGACAATGGGGGCAACCCTGATCCAGCA", :SEQ_LEN=>39, :SCORES=>"<??????BDDDDDDDDGGGGGGGHHIIIEHIHHFGGHFH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 2:N:0:14", :SEQ=>"CCTGTTTGCTACCCACGCTTTCGTACCTCAGCGTCAGTA", :SEQ_LEN=>39, :SCORES=>"?????BB<-<BDDDDDFEEFFFHFFHI;F;EGHHDHEF9"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14", :SEQ=>"TAGGGAATCTTGCACAATGGAGGAAACTCTGATGCAGCG", :SEQ_LEN=>39, :SCORES=>"<???9?BBBDBDDBDDFFFFFFHHHIFHFHHIHHFHHHH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 2:N:0:14", :SEQ=>"ACTCTTCGCTACCCATGCTTTCGTTCCTCAGCGTCAGTA", :SEQ_LEN=>39, :SCORES=>",5<??BB?DDABDBDDFFFFFFHFHIHFHHIIHEHEHF?"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq status with :input and :input2 returns correctly" do
    @p.read_fastq(input: @file2, input2: @file3).run(output: @output2)

    assert_equal(156, @p.status[:status].first[:residues_in])
  end

  test "BioPieces::Pipeline::ReadFastq with :input and :input2 and :first returns correctly" do
    @p.read_fastq(input: @file2, input2: @file3, first: 2).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14", :SEQ=>"TGGGGAATATTGGACAATGGGGGCAACCCTGATCCAGCA", :SEQ_LEN=>39, :SCORES=>"<??????BDDDDDDDDGGGGGGGHHIIIEHIHHFGGHFH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 2:N:0:14", :SEQ=>"CCTGTTTGCTACCCACGCTTTCGTACCTCAGCGTCAGTA", :SEQ_LEN=>39, :SCORES=>"?????BB<-<BDDDDDFEEFFFHFFHI;F;EGHHDHEF9"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with :input and :input2 and :last returns correctly" do
    @p.read_fastq(input: @file2, input2: @file3, last: 2).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14", :SEQ=>"TAGGGAATCTTGCACAATGGAGGAAACTCTGATGCAGCG", :SEQ_LEN=>39, :SCORES=>"<???9?BBBDBDDBDDFFFFFFHHHIFHFHHIHHFHHHH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 2:N:0:14", :SEQ=>"ACTCTTCGCTACCCATGCTTTCGTTCCTCAGCGTCAGTA", :SEQ_LEN=>39, :SCORES=>",5<??BB?DDABDBDDFFFFFFHFHIHFHHIIHEHEHF?"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with base_64 :input returns correctly" do
    @p.read_fastq(input: @file4).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>"!!!!!!\\\"\\\#$%&'()*+,-./0123456789:;!!?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIII\"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with base_64 :input and :input2 returns correctly" do
    @p.read_fastq(input: @file4, input2: @file5).run(output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"base_64", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>68, :SCORES=>"!!!!!!\\\"\\\#$%&'()*+,-./0123456789:;!!?@ABCDEFGHIIIIIIIIIIIIIIIIIIIIIII\"}}
    expected << %Q{{:SEQ_NAME=>"base_64_2", :SEQ=>"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", :SEQ_LEN=>64, :SCORES=>"!!!!\\\"\\\#$%&'()*+,-./0123456789:;!!?@ABCDEFGHIIIIIIIIIIIIIIIIIIIII\"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end

  test "BioPieces::Pipeline::ReadFastq with flux returns correctly" do
    @p.read_fastq(input: @file2, encoding: :base_33).run(input: @input, output: @output2)

    expected = ""
    expected << %Q{{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}}
    expected << %Q{{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14", :SEQ=>"TGGGGAATATTGGACAATGGGGGCAACCCTGATCCAGCA", :SEQ_LEN=>39, :SCORES=>"<??????BDDDDDDDDGGGGGGGHHIIIEHIHHFGGHFH"}}
    expected << %Q{{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14", :SEQ=>"TAGGGAATCTTGCACAATGGAGGAAACTCTGATGCAGCG", :SEQ_LEN=>39, :SCORES=>"<???9?BBBDBDDBDDFFFFFFHHHIFHFHHIHHFHHHH"}}

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    assert_equal(expected, stream_result)
  end
end
