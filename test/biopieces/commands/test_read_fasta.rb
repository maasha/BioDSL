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
require 'tempfile'

class StreamIO
  def initialize(string = "", mode = 'r')
    case mode
    when 'r' then MessagePack::Unpacker.new(StringIO.new(string, mode), symbolize_keys: true)
    when 'w' then MessagePack::Packer.new(StringIO.new(string, mode))
    else
      raise ArgumentError, "unknown mode"
    end
  end
end

class TestReadFasta < Test::Unit::TestCase 
  def setup
    fasta_entries = <<EOF
>test1
atgcagcac
>test2
acagcactgA
EOF

    @file = Tempfile.new('foo')

    File.open(@file, 'w') do |ios|
      ios.puts fasta_entries
    end

    @input, @output = BioPieces::Pipeline::Stream.pipe
  end

  def teardown
    @file.close
    @file.unlink
  end

  test "BioPieces::Pipeline::ReadFasta returns correctly" do
    output = StringIO.new("", 'w')
    command = BioPieces::Pipeline::Command.new(:read_fasta, input: @file)
    command.run(nil, output)

    assert_equal('{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}', output.string)
  end

  test "BioPieces::Pipeline::ReadFasta with flux returns correctly" do
    command = BioPieces::Pipeline::Command.new(:read_fasta, input: @file)
    command.run(nil, @output)

    result = @input.map { |h| h.to_s }.reduce(:<<)

    assert_equal('{:SEQ_NAME=>"test1", :SEQ=>"atgcagcac", :SEQ_LEN=>9}{:SEQ_NAME=>"test2", :SEQ=>"acagcactgA", :SEQ_LEN=>10}', result)
  end
end
