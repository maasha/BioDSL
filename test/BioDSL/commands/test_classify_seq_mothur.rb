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

# Test class for ClassifySeqMothur.
class TestClassifySeqMothur < Test::Unit::TestCase
  def setup
    omit('mothur not found') unless BioPieces::Filesys.which('mothur')

    @p = BP.new
    @database = __FILE__
    @taxonomy = __FILE__
  end

  test 'BioPieces::Pipeline#classify_seq_mothur with disallowed option fail' do
    assert_raise(BioPieces::OptionError) do
      @p.classify_seq_mothur(database: @database, taxonomy: @taxonomy,
                             foo: 'bar')
    end
  end

  test 'BioPieces::Pipeline#classify_seq_mothur w. allowed option dont fail' do
    assert_nothing_raised do
      @p.classify_seq_mothur(database: @database, taxonomy: @taxonomy, cpus: 2)
    end
  end

  # test "BioPieces::Pipeline#classify_seq_mothur outputs correctly" do
  #   # TODO: mock this sucker.
  # end
end
