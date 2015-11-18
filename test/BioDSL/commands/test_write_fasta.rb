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

# Test class for WriteFasta.
class TestWriteFasta < Test::Unit::TestCase
  def setup
    @zcat = BioDSL::Filesys.which('gzcat') ||
            BioDSL::Filesys.which('zcat')

    init_test_files
    init_data_streams

    @expected = <<-EXP.gsub(/^\s+\|/, '')
      |>test1
      |atcg
      |>test2
      |gtac
    EXP

    @p = BioDSL::Pipeline.new
    @e = BioDSL::OptionError
  end

  def init_test_files
    @tmpdir = Dir.mktmpdir('BioDSL')
    @file   = File.join(@tmpdir, 'test.fna')
    @file2  = File.join(@tmpdir, 'test.fna')
  end

  def init_data_streams
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(SEQ_NAME: 'test1', SEQ: 'atcg', SEQ_LEN: 4)
    @output.write(SEQ_NAME: 'test2', SEQ: 'gtac', SEQ_LEN: 4)
    @output.close
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::WriteFasta with invalid options raises' do
    assert_raise(@e) { @p.write_fasta(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::WriteFasta to stdout outputs correctly' do
    result = capture_stdout { @p.write_fasta.run(input: @input) }
    assert_equal(@expected, result)
  end

  test 'BioDSL::Pipeline::WriteFasta status outputs correctly' do
    capture_stdout { @p.write_fasta.run(input: @input) }
    assert_equal(2, @p.status.first[:records_in])
    assert_equal(2, @p.status.first[:records_out])
    assert_equal(2, @p.status.first[:sequences_in])
    assert_equal(2, @p.status.first[:sequences_out])
    assert_equal(8, @p.status.first[:residues_in])
    assert_equal(8, @p.status.first[:residues_out])
  end

  test 'BioDSL::Pipeline::WriteFasta with :wrap outputs correctly' do
    result = capture_stdout { @p.write_fasta(wrap: 2).run(input: @input) }

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |>test1
      |at
      |cg
      |>test2
      |gt
      |ac
    EXP

    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline::WriteFasta to file outputs correctly' do
    @p.write_fasta(output: @file).run(input: @input, output: @output2)

    assert_equal(@expected, File.read(@file))
  end

  test 'BioDSL::Pipeline::WriteFasta to existing file raises' do
    `touch #{@file}`
    assert_raise(@e) { @p.write_fasta(output: @file) }
  end

  test 'BioDSL::Pipeline::WriteFasta to file with :force outputs OK' do
    `touch #{@file}`
    @p.write_fasta(output: @file, force: true).run(input: @input)

    assert_equal(@expected, File.open(@file).read)
  end

  test 'BioDSL::Pipeline::WriteFasta with gzipdata and w/o file raises' do
    assert_raise(@e) { @p.write_fasta(gzip: true) }
  end

  test 'BioDSL::Pipeline::WriteFasta with bzip2 data w/o file raises' do
    assert_raise(@e) { @p.write_fasta(bzip2: true) }
  end

  test 'BioDSL::Pipeline::WriteFasta to file outputs gzipped data OK' do
    @p.write_fasta(output: @file, gzip: true).run(input: @input)

    assert_equal(@expected, `#{@zcat} #{@file}`)
  end

  test 'BioDSL::Pipeline::WriteFasta to file outputs bzip2\'ed data OK' do
    @p.write_fasta(output: @file, bzip2: true).run(input: @input)

    assert_equal(@expected, `bzcat #{@file}`)
  end

  test 'BioDSL::Pipeline::WriteFasta with gzip and bzip2 output raises' do
    assert_raise(@e) { @p.write_fasta(output: @file, gzip: true, bzip2: true) }
  end

  test 'BioDSL::Pipeline::WriteFasta with flux outputs correctly' do
    @p.write_fasta(output: @file).run(input: @input, output: @output2)

    expected2 = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"test2", :SEQ=>"gtac", :SEQ_LEN=>4}
    EXP

    assert_equal(@expected, File.open(@file).read)
    assert_equal(expected2, collect_result)
  end
end
