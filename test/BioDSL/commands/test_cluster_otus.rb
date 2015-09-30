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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for ClusterOtus.
class TestClusterOtus < Test::Unit::TestCase
  def setup
    omit('usearch not found') unless BioDSL::Filesys.which('usearch')
  end

  test 'BioDSL::Pipeline#cluster_otus with disallowed option raises' do
    p = BioDSL::Pipeline.new
    assert_raise(BioDSL::OptionError) { p.cluster_otus(foo: 'bar') }
  end

  test 'BioDSL::Pipeline#cluster_otus with allowed option dont raise' do
    p = BioDSL::Pipeline.new
    assert_nothing_raised { p.cluster_otus(identity: 1) }
  end

  test 'BioDSL::Pipeline#cluster_otus with SEQ and no SEQ_COUNT raises' do
    input, output   = BioDSL::Stream.pipe
    input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ: 'atcg')
    output.write(SEQ: 'atcg')
    output.close

    p = BioDSL::Pipeline.new

    assert_raise(BioDSL::SeqError) do
      p.cluster_otus.run(input: input, output: output2)
    end

    input2.close
  end

  test 'BioDSL::Pipeline#cluster_otus with SEQ and unsorted SEQ_COUNT ' \
    'raises' do
    input, output   = BioDSL::Stream.pipe
    input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ_COUNT: 3, SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.write(SEQ_COUNT: 4, SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioDSL::Pipeline.new

    assert_raise(BioDSL::UsearchError) do
      p.cluster_otus.run(input: input, output: output2)
    end

    input2.close
  end

  test 'BioDSL::Pipeline#cluster_otus outputs correctly' do
    input, output   = BioDSL::Stream.pipe
    @input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ_COUNT: 5, SEQ: 'atcgaAcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.write(SEQ_COUNT: 4, SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioDSL::Pipeline.new.cluster_otus.run(input: input, output: output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:one=>1,
      | :two=>2,
      | :three=>3}
      |{:SEQ_NAME=>"1",
      | :SEQ=>"ATCGAACGATCGATCGATCGATCGATCGTACGACGTAGCT",
      | :SEQ_LEN=>40,
      | :SEQ_COUNT=>5}
    EXP

    assert_equal(expected, collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline#cluster_otus status outputs correctly' do
    input, output   = BioDSL::Stream.pipe
    input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ_COUNT: 5, SEQ: 'atcgaAcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.write(SEQ_COUNT: 4, SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioDSL::Pipeline.new.cluster_otus.run(input: input, output: output2)

    assert_equal(3,  p.status.first[:records_in])
    assert_equal(2,  p.status.first[:records_out])
    assert_equal(2,  p.status.first[:sequences_in])
    assert_equal(1,  p.status.first[:sequences_out])
    assert_equal(80, p.status.first[:residues_in])
    assert_equal(40, p.status.first[:residues_out])
  end
end
