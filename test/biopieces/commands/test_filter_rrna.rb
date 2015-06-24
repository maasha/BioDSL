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
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for FilterRrna.
class TestFilterRrna < Test::Unit::TestCase
  def setup
    @tmp_dir = Dir.mktmpdir('filter_rrna')

    omit('sortmerna not found')   unless BioPieces::Filesys.which('sortmerna')
    omit('indexdb_rna not found') unless BioPieces::Filesys.which('indexdb_rna')

    setup_test_streams
    setup_test_data
    setup_fasta_file
    setup_indexdb

    @p = BioPieces::Pipeline.new
  end

  def setup_test_streams
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe
  end

  def setup_test_data
    @hash1 = {
      SEQ_NAME: 'test1',
      SEQ: 'gatcagatcgtacgagcagcatctgacgtatcgatcgttgattagttgctagctatgcag',
      SEQ_LEN: 60
    }

    @hash2 = {
      SEQ_NAME: 'test2',
      SEQ: 'ggttagtcagcgactgactgactacgatatatatcgatacgcggaggtatatatagagag',
      SEQ_LEN: 60
    }

    @output.write @hash1
    @output.write @hash2
    @output.close
  end

  def setup_fasta_file
    @ref_fasta = File.join(@tmp_dir, 'test.fna')
    @ref_index = "#{@ref_fasta}.idx"

    BioPieces::Fasta.open(@ref_fasta, 'w') do |ios|
      ios.puts BioPieces::Seq.new_bp(@hash1).to_fasta
    end
  end

  def setup_indexdb
    cmd = "indexdb_rna --ref #{@ref_fasta},#{@ref_index}"
    system(cmd)

    fail "Running command failed: #{cmd}" unless $CHILD_STATUS.success?
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  test 'BioPieces::Pipeline::FilterRrna with invalid options raises' do
    assert_raise(BioPieces::OptionError) do
      @p.filter_rrna(ref_fasta: __FILE__, ref_index: __FILE__, foo: 'bar')
    end
  end

  test 'BioPieces::Pipeline::FilterRrna with valid options don\'t raise' do
    assert_nothing_raised do
      @p.filter_rrna(ref_fasta: __FILE__, ref_index: __FILE__)
    end
  end

  test 'BioPieces::Pipeline::FilterRrna returns correctly' do
    @p.filter_rrna(ref_fasta: @ref_fasta, ref_index: "#{@ref_index}*").
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+|\|/, '').delete("\n")
      |{:SEQ_NAME=>"test2",
      | :SEQ=>"ggttagtcagcgactgactgactacgatatatatcgatacgcggaggtatatatagagag",
      | :SEQ_LEN=>60}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioPieces::Pipeline::FilterRrna status returns correctly' do
    @p.filter_rrna(ref_fasta: @ref_fasta, ref_index: "#{@ref_index}*").
      run(input: @input, output: @output2)

    assert_equal(2,   @p.status.first[:records_in])
    assert_equal(1,   @p.status.first[:records_out])
    assert_equal(2,   @p.status.first[:sequences_in])
    assert_equal(1,   @p.status.first[:sequences_out])
    assert_equal(120, @p.status.first[:residues_in])
    assert_equal(60,  @p.status.first[:residues_out])
  end
end
