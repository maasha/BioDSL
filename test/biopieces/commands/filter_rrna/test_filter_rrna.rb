#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', '..', '..')

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

class TestFilterRrna < Test::Unit::TestCase 
  def setup
    @tmp_dir   = Dir.mktmpdir('filter_rrna')

    omit("sortmerna not found")   unless BioPieces::Filesys.which("sortmerna")
    omit("indexdb_rna not found") unless BioPieces::Filesys.which("indexdb_rna")

    @ref_fasta = File.join(@tmp_dir, 'test.fna')
    @ref_index = "#{@ref_fasta}.idx"

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    hash1 = {
      SEQ_NAME: 'test1',
      SEQ: 'gatcagatcgtacgagcagcatctgacgtatcgatcgttgattagttgctagctatgcag',
      SEQ_LEN: 60,
    }

    hash2 = {
      SEQ_NAME: 'test2',
      SEQ: 'ggttagtcagcgactgactgactacgatatatatcgatacgcggaggtatatatagagag',
      SEQ_LEN: 60,
    }

    @output.write hash1
    @output.write hash2
    @output.close

    BioPieces::Fasta.open(@ref_fasta, 'w') do |ios|
      ios.puts BioPieces::Seq.new_bp(hash1).to_fasta
    end

    cmd = "indexdb_rna --ref #{@ref_fasta},#{@ref_index}"
    system(cmd)

    fail "Running command failed: #{cmd}" unless $?.success?

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_rf(@tmp_dir)
  end

  test "BioPieces::Pipeline::FilterRrna with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.filter_rrna(ref_fasta: __FILE__, ref_index: __FILE__, foo: "bar") }
  end

  test "BioPieces::Pipeline::FilterRrna with valid options don't raise" do
    assert_nothing_raised { @p.filter_rrna(ref_fasta: __FILE__, ref_index: __FILE__) }
  end

  test "BioPieces::Pipeline::FilterRrna returns correctly" do
    @p.filter_rrna(ref_fasta: @ref_fasta, ref_index: "#{@ref_index}*").run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = "{:SEQ_NAME=>\"test2\", :SEQ=>\"ggttagtcagcgactgactgactacgatatatatcgatacgcggaggtatatatagagag\", :SEQ_LEN=>60}"

    assert_equal(expected, result)
  end
end
