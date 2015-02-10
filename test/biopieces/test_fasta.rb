#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

class FastaTest < Test::Unit::TestCase
  def setup
    @file = Tempfile.new("fasta")
  end

  def teardown
    @file.close
    @file.unlink
  end

  test "BioPieces::Fasta#read with non-existing file raises" do
    assert_raise(Errno::ENOENT) { BioPieces::Fasta.read("dasf") }
  end

  test "BioPieces::Fasta#read with empty files return empty" do
    assert_equal([], BioPieces::Fasta.read(@file))
  end

  test "BioPieces::Fasta#read with two entries return correctly" do
    File.open(@file, 'w') do |ios|
ios.puts <<EOD
>test1
atcg
>test2
gtT
EOD
    end

    @file.close

    assert_equal([">test1\natcg\n", ">test2\ngtT\n"], BioPieces::Fasta.read(@file).map { |e| e.to_fasta } )
  end

  test "BioPieces::Fasta#read from gzip with two entries return correctly" do
    File.open(@file, 'w') do |ios|
ios.puts <<EOD
>test1
atcg
>test2
gtT
EOD
    end

    @file.close

    `gzip #{@file.path}`

    assert_equal([">test1\natcg\n", ">test2\ngtT\n"], BioPieces::Fasta.read("#{@file.path}.gz").map { |e| e.to_fasta } )
  end

  test "BioPieces::Fasta#read from bzip2 with two entries return correctly" do
    File.open(@file, 'w') do |ios|
ios.puts <<EOD
>test1
atcg
>test2
gtT
EOD
    end

    @file.close

    `bzip2 #{@file.path}`

    assert_equal([">test1\natcg\n", ">test2\ngtT\n"], BioPieces::Fasta.read("#{@file.path}.bz2").map { |e| e.to_fasta } )
  end

  test "BioPieces::Fasta#read with two entries and white space return correctly" do
    File.open(@file, 'w') do |ios|
ios.puts <<EOD

>test1

at

cg

>test2

gt

T

EOD
    end

    @file.close

    assert_equal([">test1\natcg\n", ">test2\ngtT\n"], BioPieces::Fasta.read(@file).map { |e| e.to_fasta } )
  end

  test "BioPieces::Fasta#read with content and missing seq_name raises" do
    File.open(@file, 'w') do |ios|
      ios.puts "tyt"
    end

    @file.close

    assert_raise(BioPieces::FastaError) { BioPieces::Fasta.read(@file) }
  end

  test "BioPieces::Fasta#read with content before first entry raises" do
    File.open(@file, 'w') do |ios|
      ios.puts "foo\n>bar\natcg"
    end

    @file.close

    assert_raise(BioPieces::FastaError) { BioPieces::Fasta.read(@file) }
  end

  test "BioPieces::Fasta#read with content and truncated seq_name raises" do
    File.open(@file, 'w') do |ios|
      ios.puts ">\ntyt"
    end

    @file.close

    assert_raise(BioPieces::FastaError) { BioPieces::Fasta.read(@file) }
  end
end
