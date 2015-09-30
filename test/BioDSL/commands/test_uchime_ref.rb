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

# Test class for UchimeRef.
class TestUchimeRef < Test::Unit::TestCase
  require 'tempfile'

  def setup
    omit('usearch not found') unless BioDSL::Filesys.which('usearch')

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

  test 'BioDSL::Pipeline#uchime_ref with disallowed option raises' do
    p = BioDSL::Pipeline.new
    assert_raise(BioDSL::OptionError) { p.uchime_ref(foo: 'bar') }
  end

  test 'BioDSL::Pipeline#uchime_ref with allowed option dont raise' do
    p = BioDSL::Pipeline.new
    assert_nothing_raised { p.uchime_ref(database: @db.path) }
  end

  test 'BioDSL::Pipeline#uchime_ref outputs correctly' do
    input, output   = BioDSL::Stream.pipe
    @input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ_COUNT: 5, SEQ: 'atcgaAcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.write(SEQ_COUNT: 4, SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioDSL::Pipeline.new
    p.uchime_ref(database: @db.path).run(input: input, output: output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:one=>1,
      | :two=>2,
      | :three=>3}
      |{:SEQ_NAME=>"1",
      | :SEQ=>"atcgaAcgatcgatcgatcgatcgatcgtacgacgtagct",
      | :SEQ_LEN=>40}
      |{:SEQ_NAME=>"2",
      | :SEQ=>"atcgatcgatcgatcgatcgatcgatcgtacgacgtagct",
      | :SEQ_LEN=>40}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline#uchime_ref status outputs correctly' do
    input, output   = BioDSL::Stream.pipe
    @input2, output2 = BioDSL::Stream.pipe

    output.write(one: 1, two: 2, three: 3)
    output.write(SEQ_COUNT: 5, SEQ: 'atcgaAcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.write(SEQ_COUNT: 4, SEQ: 'atcgatcgatcgatcgatcgatcgatcgtacgacgtagct')
    output.close

    p = BioDSL::Pipeline.new
    p.uchime_ref(database: @db.path).run(input: input, output: output2)

    assert_equal(3,  p.status.first[:records_in])
    assert_equal(3,  p.status.first[:records_out])
    assert_equal(2,  p.status.first[:sequences_in])
    assert_equal(2,  p.status.first[:sequences_out])
    assert_equal(80, p.status.first[:residues_in])
    assert_equal(80, p.status.first[:residues_out])
  end
end
