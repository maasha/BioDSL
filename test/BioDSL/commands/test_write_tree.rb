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

# Test class for WriteTree.
class TestWriteTree < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('BioDSL')

    omit('FastTree not found') unless BioDSL::Filesys.which('FastTree')

    setup_data

    @file = File.join(@tmpdir, 'test.tree')
    @p    = BioDSL::Pipeline.new
  end

  def setup_data
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(SEQ: 'attgactgacg--')
    @output.write(SEQ: 'attgactaagacg')
    @output.write(SEQ: 'a---actgacg--')
    @output.write(SEQ: 'a---actaagacg')
    @output.write(SEQ: 'a---actaagacg')
    @output.write(FOO: 'BAR')
    @output.close
  end

  def teardown
    FileUtils.rm_r @tmpdir if @tmpdir
  end

  test 'BioDSL::Pipeline::WriteTree with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.write_tree(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::WriteTree to stdout outputs correctly' do
    result = capture_stdout { @p.write_tree.run(input: @input) }
    expected = '(1:0.00055,(3:0.0,4:0.0):0.00054,' \
      '(0:0.00055,2:0.00054)0.996:0.34079);'
    assert_equal(expected, result.chomp)
  end

  test 'BioDSL::Pipeline::WriteTree to file outputs correctly' do
    @p.write_tree(output: @file).run(input: @input, output: @output2)
    result = File.read(@file)
    expected = '(1:0.00055,(3:0.0,4:0.0):0.00054,' \
      '(0:0.00055,2:0.00054)0.996:0.34079);'
    assert_equal(expected, result.chomp)
  end

  test 'BioDSL::Pipeline::WriteTree to existing file raises' do
    `touch #{@file}`
    assert_raise(BioDSL::OptionError) { @p.write_tree(output: @file) }
  end

  test 'BioDSL::Pipeline::WriteTree to existing file w. :force outputs OK' do
    `touch #{@file}`
    @p.write_tree(output: @file, force: true).run(input: @input)
    result = File.open(@file).read
    expected = '(1:0.00055,(3:0.0,4:0.0):0.00054,' \
      '(0:0.00055,2:0.00054)0.996:0.34079);'
    assert_equal(expected, result.chomp)
  end

  test 'BioDSL::Pipeline::WriteTree with flux outputs correctly' do
    @p.write_tree(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    expected = '(1:0.00055,(3:0.0,4:0.0):0.00054,' \
      '(0:0.00055,2:0.00054)0.996:0.34079);'
    assert_equal(expected, result.chomp)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"attgactgacg--"}
      |{:SEQ=>"attgactaagacg"}
      |{:SEQ=>"a---actgacg--"}
      |{:SEQ=>"a---actaagacg"}
      |{:SEQ=>"a---actaagacg"}
      |{:FOO=>"BAR"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::WriteTree status outputs correctly' do
    @p.write_tree(output: @file).run(input: @input, output: @output2)
    assert_equal(6,  @p.status.first[:records_in])
    assert_equal(6,  @p.status.first[:records_out])
    assert_equal(5,  @p.status.first[:sequences_in])
    assert_equal(65, @p.status.first[:residues_in])
  end
end
