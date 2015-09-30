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

# Test class for SliceAlign
# rubocop: disable ClassLength
class TestSliceAlign < Test::Unit::TestCase
  def setup
    require 'tempfile'

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write(SEQ_NAME: 'ID0', SEQ: 'CCGCATACG-------CCCTGAGGGG----')
    @output.write(SEQ_NAME: 'ID1', SEQ: 'CCGCATGAT-------ACCTGAGGGT----')
    @output.write(SEQ_NAME: 'ID2', SEQ: 'CCGCATATACTCTTGACGCTAAAGCGTAGT')
    @output.write(SEQ_NAME: 'ID3', SEQ: 'CCGTATGTG-------CCCTTCGGGG----')
    @output.write(SEQ_NAME: 'ID4', SEQ: 'CCGGATAAG-------CCCTTACGGG----')
    @output.write(SEQ_NAME: 'ID5', SEQ: 'CCGGATAAG-------CCCTTACGGG----')
    @output.write(FOO: 'BAR')
    @output.close

    setup_template_file

    @p = BioPieces::Pipeline.new
  end

  def setup_template_file
    @template_file = Tempfile.new('slice_align')

    File.open(@template_file, 'w') do |ios|
      ios.puts '>template'
      ios.puts 'CTGAATACG-------CCATTCGATGG---'
    end
  end

  def teardown
    @template_file.close
    @template_file.unlink
  end

  test 'BioPieces::Pipeline::SliceAlign with invalid options raises' do
    assert_raise(BioPieces::OptionError) do
      @p.slice_align(slice: 1, foo: 'bar')
    end
  end

  test 'BioPieces::Pipeline::SliceAlign with valid options don\'t raise' do
    assert_nothing_raised { @p.slice_align(slice: 1) }
  end

  test 'BioPieces::Pipeline::SliceAlign with slice and primers raises' do
    assert_raise(BioPieces::OptionError) do
      @p.slice_align(slice: 1, forward: 'foo', reverse: 'bar')
    end
  end

  test 'BioPieces::Pipeline::SliceAlign with index returns correctly' do
    @p.slice_align(slice: 14..27).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"ID0", :SEQ=>"--CCCTGAGGGG--", :SEQ_LEN=>14}
      |{:SEQ_NAME=>"ID1", :SEQ=>"--ACCTGAGGGT--", :SEQ_LEN=>14}
      |{:SEQ_NAME=>"ID2", :SEQ=>"GACGCTAAAGCGTA", :SEQ_LEN=>14}
      |{:SEQ_NAME=>"ID3", :SEQ=>"--CCCTTCGGGG--", :SEQ_LEN=>14}
      |{:SEQ_NAME=>"ID4", :SEQ=>"--CCCTTACGGG--", :SEQ_LEN=>14}
      |{:SEQ_NAME=>"ID5", :SEQ=>"--CCCTTACGGG--", :SEQ_LEN=>14}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioPieces::Pipeline::SliceAlign status returns correctly' do
    @p.slice_align(slice: 14..27).run(input: @input, output: @output2)

    assert_equal(7,   @p.status.first[:records_in])
    assert_equal(7,   @p.status.first[:records_out])
    assert_equal(6,   @p.status.first[:sequences_in])
    assert_equal(6,   @p.status.first[:sequences_out])
    assert_equal(180, @p.status.first[:residues_in])
    assert_equal(84,  @p.status.first[:residues_out])
  end

  test 'BioPieces::Pipeline::SliceAlign with forward primer miss raises' do
    assert_raise(BioPieces::SeqError) do
      @p.slice_align(forward: 'AAAAAAA', reverse: 'GAGGGG').
        run(input: @input, output: @output2)
    end
  end

  test 'BioPieces::Pipeline::SliceAlign with reverse primer miss raises' do
    assert_raise(BioPieces::SeqError) do
      @p.slice_align(forward: 'CGCATACG', reverse: 'AAAAAAA').
        run(input: @input, output: @output2)
    end
  end

  test 'BioPieces::Pipeline::SliceAlign with primers returns correctly' do
    @p.slice_align(forward: 'CGCATACG', reverse: 'GAGGGG', max_mismatches: 0,
                   max_insertions: 0, max_deletions: 0).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"ID0", :SEQ=>"CGCATACG-------CCCTGAGGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID1", :SEQ=>"CGCATGAT-------ACCTGAGGGT", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID2", :SEQ=>"CGCATATACTCTTGACGCTAAAGCG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID3", :SEQ=>"CGTATGTG-------CCCTTCGGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID4", :SEQ=>"CGGATAAG-------CCCTTACGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID5", :SEQ=>"CGGATAAG-------CCCTTACGGG", :SEQ_LEN=>25}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioPieces::Pipeline::SliceAlign with forward_rc primer returns OK' do
    @p.slice_align(forward_rc: 'cgtatgcg', reverse: 'GAGGGG', max_mismatches: 0,
                   max_insertions: 0, max_deletions: 0).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"ID0", :SEQ=>"CGCATACG-------CCCTGAGGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID1", :SEQ=>"CGCATGAT-------ACCTGAGGGT", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID2", :SEQ=>"CGCATATACTCTTGACGCTAAAGCG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID3", :SEQ=>"CGTATGTG-------CCCTTCGGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID4", :SEQ=>"CGGATAAG-------CCCTTACGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID5", :SEQ=>"CGGATAAG-------CCCTTACGGG", :SEQ_LEN=>25}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioPieces::Pipeline::SliceAlign with reverse_rc primer returns OK' do
    @p.slice_align(forward: 'CGCATACG', reverse_rc: 'cccctc', max_mismatches: 0,
                   max_insertions: 0, max_deletions: 0).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"ID0", :SEQ=>"CGCATACG-------CCCTGAGGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID1", :SEQ=>"CGCATGAT-------ACCTGAGGGT", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID2", :SEQ=>"CGCATATACTCTTGACGCTAAAGCG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID3", :SEQ=>"CGTATGTG-------CCCTTCGGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID4", :SEQ=>"CGGATAAG-------CCCTTACGGG", :SEQ_LEN=>25}
      |{:SEQ_NAME=>"ID5", :SEQ=>"CGGATAAG-------CCCTTACGGG", :SEQ_LEN=>25}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioPieces::Pipeline::SliceAlign with primers and template_file ' \
    'returns correctly' do
    @p.slice_align(forward: 'GAATACG', reverse: 'ATTCGAT',
                   template_file: @template_file, max_mismatches: 0,
                   max_insertions: 0, max_deletions: 0).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"ID0", :SEQ=>"GCATACG-------CCCTGAGGG", :SEQ_LEN=>23}
      |{:SEQ_NAME=>"ID1", :SEQ=>"GCATGAT-------ACCTGAGGG", :SEQ_LEN=>23}
      |{:SEQ_NAME=>"ID2", :SEQ=>"GCATATACTCTTGACGCTAAAGC", :SEQ_LEN=>23}
      |{:SEQ_NAME=>"ID3", :SEQ=>"GTATGTG-------CCCTTCGGG", :SEQ_LEN=>23}
      |{:SEQ_NAME=>"ID4", :SEQ=>"GGATAAG-------CCCTTACGG", :SEQ_LEN=>23}
      |{:SEQ_NAME=>"ID5", :SEQ=>"GGATAAG-------CCCTTACGG", :SEQ_LEN=>23}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioPieces::Pipeline::SliceAlign with template_file and slice ' \
    'returns correctly' do
    @p.slice_align(template_file: @template_file, slice: 4..14).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"ID0", :SEQ=>"ATACG-------CCCTGA", :SEQ_LEN=>18}
      |{:SEQ_NAME=>"ID1", :SEQ=>"ATGAT-------ACCTGA", :SEQ_LEN=>18}
      |{:SEQ_NAME=>"ID2", :SEQ=>"ATATACTCTTGACGCTAA", :SEQ_LEN=>18}
      |{:SEQ_NAME=>"ID3", :SEQ=>"ATGTG-------CCCTTC", :SEQ_LEN=>18}
      |{:SEQ_NAME=>"ID4", :SEQ=>"ATAAG-------CCCTTA", :SEQ_LEN=>18}
      |{:SEQ_NAME=>"ID5", :SEQ=>"ATAAG-------CCCTTA", :SEQ_LEN=>18}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end
end
