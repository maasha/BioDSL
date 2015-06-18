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

# Test class for UsearchLocal.
class TestUsearchLocal < Test::Unit::TestCase
  require 'tempfile'

  def setup
    omit('usearch not found') unless BioPieces::Filesys.which('usearch')

    data = <<-DAT.gsub(/^\s+\|/, '')
      |>test1
      |gtgtgtagctacgatcagctagcgatcgagctatatgttt
    DAT

    @db = Tempfile.new('database')

    File.open(@db, 'w') do |ios|
      ios << data
    end
  end

  def teardown
    @db.close
    @db.unlink
  end

  test 'BioPieces::Pipeline#usearch_local with disallowed option raises' do
    p = BioPieces::Pipeline.new
    assert_raise(BioPieces::OptionError) { p.usearch_local(foo: 'bar') }
  end

  test 'BioPieces::Pipeline#usearch_local with allowed option dont raise' do
    p = BioPieces::Pipeline.new
    assert_nothing_raised { p.usearch_local(database: @db.path, identity: 1) }
  end

  test 'BioPieces::Pipeline#usearch_local outputs correctly' do
    input, output   = BioPieces::Stream.pipe
    @input2, output2 = BioPieces::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ: 'gtgtgtagctacgatcagctagcgatcgagctatatgttt')
    output.write(SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioPieces::Pipeline.new
    p.usearch_local(database: @db.path, identity: 0.97, strand: 'plus').
      run(input: input, output: output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"atcgatcgatcgatcgatcgatcgatcgtacgacgtagct"}
      |{:SEQ=>"gtgtgtagctacgatcagctagcgatcgagctatatgttt"}
      |{:TYPE=>"H",
      | :CLUSTER=>0,
      | :SEQ_LEN=>40,
      | :IDENT=>100.0,
      | :STRAND=>"+",
      | :CIGAR=>"40M",
      | :Q_ID=>"1",
      | :S_ID=>"test1",
      | :RECORD_TYPE=>"usearch"}
      |{:TYPE=>"N",
      | :CLUSTER=>0,
      | :SEQ_LEN=>0,
      | :STRAND=>".",
      | :CIGAR=>"*",
      | :Q_ID=>"2",
      | :RECORD_TYPE=>"usearch"}
      |{:one=>1,
      | :two=>2,
      | :three=>3}
    EXP

    assert_equal(expected.delete("\n"), collect_sorted_result.delete("\n"))
  end

  test 'BioPieces::Pipeline#usearch_local status outputs correctly' do
    input, output   = BioPieces::Stream.pipe
    @input2, output2 = BioPieces::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ: 'gtgtgtagctacgatcagctagcgatcgagctatatgttt')
    output.write(SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioPieces::Pipeline.new
    p.usearch_local(database: @db.path, identity: 0.97, strand: 'plus').
      run(input: input, output: output2)

    assert_equal(3, p.status.first[:records_in])
    assert_equal(5, p.status.first[:records_out])
    assert_equal(2, p.status.first[:sequences_in])
    assert_equal(2, p.status.first[:hits_out])
  end
end
