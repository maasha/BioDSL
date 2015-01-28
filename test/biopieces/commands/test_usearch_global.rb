#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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

class TestUsearchGlobal < Test::Unit::TestCase 
  def setup
    @db = File.join(File.dirname(__FILE__), '..', '..', '..', 'data', 'chimera_db.fna')
  end

  test "BioPieces::Pipeline#usearch_global with disallowed option raises" do
    p = BioPieces::Pipeline.new
    assert_raise(BioPieces::OptionError) { p.usearch_global(foo: "bar") }
  end

  test "BioPieces::Pipeline#usearch_global with allowed option don't raise" do
    p = BioPieces::Pipeline.new
    assert_nothing_raised { p.usearch_global(database: @db, identity: 1) }
  end

  test "BioPieces::Pipeline#usearch_global outputs correctly" do
    input, output   = BioPieces::Stream.pipe
    input2, output2 = BioPieces::Stream.pipe

    output.write({one: 1, two: 2, three: 3})
    output.write({SEQ: "gtgtgtagctacgatcagctagcgatcgagctatatgttt"})
    output.write({SEQ: "atcgatcgatcgatcgatcgatcgatcgtacgacgtagct"})
    output.close

    p = BioPieces::Pipeline.new
    p.usearch_global(database: @db, identity: 0.97, strand: "plus").run(input: input, output: output2)
    result   = input2.map { |h| h.to_s }.sort_by { |a| a.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:SEQ=>"atcgatcgatcgatcgatcgatcgatcgtacgacgtagct"}}
    expected << %Q{{:SEQ=>"gtgtgtagctacgatcagctagcgatcgagctatatgttt"}}
    expected << %Q{{:TYPE=>"H", :CLUSTER=>0, :SEQ_LEN=>40, :IDENT=>100.0, :STRAND=>"+", :CIGAR=>"40M", :Q_ID=>"1", :S_ID=>"test1", :RECORD_TYPE=>"usearch"}}
    expected << %Q{{:TYPE=>"N", :CLUSTER=>0, :SEQ_LEN=>0, :STRAND=>".", :CIGAR=>"*", :Q_ID=>"2", :RECORD_TYPE=>"usearch"}}
    expected << %Q{{:one=>1, :two=>2, :three=>3}}

    assert_equal(expected, result)
  end
end
