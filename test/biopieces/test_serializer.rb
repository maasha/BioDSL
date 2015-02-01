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

class TestSerializer < Test::Unit::TestCase 
  def setup
    @records = [
      {"foo": 1},
      {"bar": 2}
    ]
  end

  test "BioPieces::Serializer with no block raises" do
    assert_raise(BioPieces::SerializerError) { BioPieces::Serializer.new("foo") }
  end

  test "BioPieces::Serializer returns correctly" do
    require 'tempfile'

    file = Tempfile.new("serializer")

    begin
      File.open(file, 'wb') do |io|
        BioPieces::Serializer.new(io) do |s|
          @records.each { |r| s << r }
        end
      end

      result = []

      File.open(file, 'rb') do |io|
        BioPieces::Serializer.new(io) do |s|
          s.each do |record|
            result << record
          end
        end
      end

      assert_equal(@records, result)
    ensure
      file.close
      file.unlink
    end
  end
end
