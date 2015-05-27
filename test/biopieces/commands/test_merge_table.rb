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

# Test class for MergeTable.
class TestMergeTable < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('BioPieces')

    @file = File.join(@tmpdir, 'test.tab')

    setup_data_file

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write(ID: 1, COUNT: 5423)
    @output.write(ID: 2, COUNT: 34)
    @output.write(ID: 3, COUNT: 2423)
    @output.write(ID: 4, COUNT: 234)
    @output.write(ID: 5, COUNT: 2334)

    @output.close

    @p = BioPieces::Pipeline.new
  end

  def setup_data_file
    data = <<-EOF.gsub(/^\s+\|/, '')
      |#ID ORGANISM
      |1   parrot
      |2   eel
      |3   platypus
      |4   beetle
    EOF

    File.open(@file, 'w') do |ios|
      ios.puts data
    end
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioPieces::Pipeline::MergeTable with invalid options raises' do
    assert_raise(BioPieces::OptionError) { @p.merge_table(foo: 'bar') }
  end

  test 'BioPieces::Pipeline::MergeTable without required options raises' do
    assert_raise(BioPieces::OptionError) { @p.merge_table }
  end

  test 'BioPieces::Pipeline::MergeTable with non-existing input file raises' do
    assert_raise(BioPieces::OptionError) do
      @p.merge_table(input: '___adsf', key: :ID)
    end
  end

  test 'BioPieces::Pipeline::MergeTable with bad skip value file raises' do
    assert_raise(BioPieces::OptionError) do
      @p.merge_table(input: @file, key: :ID, skip: -1)
    end
  end

  test 'BioPieces::Pipeline::MergeTable with duplicate keys raises' do
    assert_raise(BioPieces::OptionError) do
      @p.merge_table(input: @file, key: :ID, keys: [:a, :a])
    end
  end

  test 'BioPieces::Pipeline::MergeTable with duplicate columns raises' do
    assert_raise(BioPieces::OptionError) do
      @p.merge_table(input: @file, key: :ID, columns: [1, 1])
    end
  end

  test 'BioPieces::Pipeline::MergeTable returns correctly' do
    @p.merge_table(input: @file, key: :ID).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>1, :COUNT=>5423, :ORGANISM=>"parrot"}
      |{:ID=>2, :COUNT=>34, :ORGANISM=>"eel"}
      |{:ID=>3, :COUNT=>2423, :ORGANISM=>"platypus"}
      |{:ID=>4, :COUNT=>234, :ORGANISM=>"beetle"}
      |{:ID=>5, :COUNT=>2334}
    EXP

    assert_equal(expected, collect_result)
  end
end
