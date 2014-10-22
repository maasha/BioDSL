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

class TestClusterOtus < Test::Unit::TestCase 
  test "BioPieces::Pipeline#cluster_otus with disallowed option raises" do
    p = BioPieces::Pipeline.new
    assert_raise(BioPieces::OptionError) { p.cluster_otus(foo: "bar") }
  end

  test "BioPieces::Pipeline#cluster_otus with allowed option don't raise" do
    p = BioPieces::Pipeline.new
    assert_nothing_raised { p.cluster_otus(identity: 1) }
  end

  test "BioPieces::Pipeline#cluster_otus with SEQ and missing SEQ_COUNT raises" do
    input, output   = BioPieces::Stream.pipe
    input2, output2 = BioPieces::Stream.pipe

    output.write({one: 1, two: 2, three: 3})
    output.write({SEQ: "atcg"})
    output.write({SEQ: "atcg"})
    output.close

    p = BioPieces::Pipeline.new
    assert_raise(BioPieces::SeqError) { p.cluster_otus.run(input: input, output: output2) }

    input2.close
  end

  test "BioPieces::Pipeline#cluster_otus with SEQ and unsorted SEQ_COUNT raises" do
    input, output   = BioPieces::Stream.pipe
    input2, output2 = BioPieces::Stream.pipe

    output.write({one: 1, two: 2, three: 3})
    output.write({SEQ_COUNT: 3, SEQ: "atcgatcgatcgatcgatcgatcgatcgtacgacgtagct"})
    output.write({SEQ_COUNT: 4, SEQ: "atcgatcgatcgatcgatcgatcgatcgtacgacgtagct"})
    output.close

    p = BioPieces::Pipeline.new
    assert_raise(BioPieces::UsearchError) { p.cluster_otus.run(input: input, output: output2) }

    input2.close
  end

  test "BioPieces::Pipeline#cluster_otus outputs correctly" do
    input, output   = BioPieces::Stream.pipe
    input2, output2 = BioPieces::Stream.pipe

    output.write({one: 1, two: 2, three: 3})
    output.write({SEQ_COUNT: 5, SEQ: "atcgaAcgatcgatcgatcgatcgatcgtacgacgtagct"})
    output.write({SEQ_COUNT: 4, SEQ: "atcgatcgatcgatcgatcgatcgatcgtacgacgtagct"})
    output.close

    p = BioPieces::Pipeline.new
    p.cluster_otus.run(input: input, output: output2)
    result   = input2.map { |h| h.to_s }.reduce(:<<)
    expected = %Q{{:one=>1, :two=>2, :three=>3}{:SEQ_NAME=>"1", :SEQ=>"ATCGAACGATCGATCGATCGATCGATCGTACGACGTAGCT", :SEQ_LEN=>40, :SEQ_COUNT=>5}}

    assert_equal(expected, result)
  end
end
