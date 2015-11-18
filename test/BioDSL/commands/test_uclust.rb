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

# Test class for Uclust.
class TestUclust < Test::Unit::TestCase
  def setup
    omit('usearch not found') unless BioDSL::Filesys.which('usearch')
  end

  test 'BioDSL::Pipeline#uclust with disallowed option raises' do
    p = BioDSL::Pipeline.new
    assert_raise(BioDSL::OptionError) { p.uclust(foo: 'bar') }
  end

  test 'BioDSL::Pipeline#uclust with allowed option dont raise' do
    p = BioDSL::Pipeline.new
    assert_nothing_raised { p.uclust(identity: 1, strand: :both) }
  end

  test 'BioDSL::Pipeline#uclust outputs correctly' do
    input, output   = BioDSL::Stream.pipe
    @input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ: 'gtgtgtagctacgatcagctagcgatcgagctatatgttt')
    output.write(SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioDSL::Pipeline.new
    p.uclust(identity: 0.97, strand: 'plus').run(input: input, output: output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"atcgatcgatcgatcgatcgatcgatcgtacgacgtagct",
      | :SEQ_NAME=>"2",
      | :TYPE=>"C",
      | :CLUSTER=>1,
      | :CLUSTER_SIZE=>1,
      | :STRAND=>"*",
      | :CIGAR=>"*",
      | :Q_ID=>"2",
      | :RECORD_TYPE=>"uclust"}
      |{:SEQ=>"gtgtgtagctacgatcagctagcgatcgagctatatgttt",
      | :SEQ_NAME=>"1",
      | :TYPE=>"C",
      | :CLUSTER=>0,
      | :CLUSTER_SIZE=>1,
      | :STRAND=>"*",
      | :CIGAR=>"*",
      | :Q_ID=>"1",
      | :RECORD_TYPE=>"uclust"}
      |{:one=>1,
      | :two=>2,
      | :three=>3}
    EXP

    assert_equal(expected.delete("\n"), collect_sorted_result.delete("\n"))
  end

  test 'BioDSL::Pipeline#uclust status outputs correctly' do
    input, output   = BioDSL::Stream.pipe
    @input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ: 'gtgtgtagctacgatcagctagcgatcgagctatatgttt')
    output.write(SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioDSL::Pipeline.new
    p.uclust(identity: 0.97, strand: 'plus').run(input: input, output: output2)

    assert_equal(3, p.status.first[:records_in])
    assert_equal(3, p.status.first[:records_out])
    assert_equal(2, p.status.first[:sequences_in])
    assert_equal(2, p.status.first[:sequences_out])
    assert_equal(80, p.status.first[:residues_in])
    assert_equal(80, p.status.first[:residues_out])
  end

  test 'BioDSL::Pipeline#uclust outputs msa correctly' do
    input, output   = BioDSL::Stream.pipe
    @input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ: 'gtgtgtagctacgatcagctagcgatcgagctatatgttt')
    output.write(SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioDSL::Pipeline.new
    p.uclust(identity: 0.97, strand: 'plus', align: true).
      run(input: input, output: output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:RECORD_TYPE=>"uclust",
      | :CLUSTER=>0,
      | :SEQ_NAME=>"*1",
      | :SEQ=>"GTgtgtAGCTACGATCAGCTAGCGATCGAGCTATATGTTT",
      | :SEQ_LEN=>40}
      |{:RECORD_TYPE=>"uclust",
      | :CLUSTER=>1,
      | :SEQ_NAME=>"*2",
      | :SEQ=>"ATCGATCGATCGATCGATCGATCGATCGTACGACGTAGCT",
      | :SEQ_LEN=>40}
      |{:one=>1,
      | :two=>2,
      | :three=>3}
    EXP

    assert_equal(expected.delete("\n"), collect_sorted_result.delete("\n"))
  end
end
