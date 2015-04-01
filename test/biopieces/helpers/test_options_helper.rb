#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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

class TestOptionsHelper < Test::Unit::TestCase 
  include BioPieces::OptionsHelper

  test '#options_allowed with disallowed option raises' do
    options = {bar: 'foo'}
    assert_raise(BioPieces::OptionError) { options_allowed(options, :foo) }
  end

  test '#options_allowed with allowed option don\'t raise' do
    options = {foo: 'bar'}
    assert_nothing_raised { options_allowed(options, :foo) }
  end

  test '#options_allowed with no options don\'t raise' do
    options = {}
    assert_nothing_raised { options_allowed(options, :foo) }
  end

  test '#options_files_exist with no option don\'t raise' do
    options = {}
    assert_nothing_raised { options_files_exist(options, :foo) }
  end

  test '#options_files_exist with non-existing file raise' do
    options = {input: 'ljg34gj324'}
    assert_raise(BioPieces::OptionError) { options_files_exist(options, :input) }
  end

  test '#options_files_exist with non-existing files raise' do
    options = {input: __FILE__, input2: '32g4g24g23'}
    assert_raise(BioPieces::OptionError) { options_files_exist(options, :input, :input2) }
  end

  test '#options_files_exist with Array of non-existing files raise' do
    options = {input: [__FILE__, 'h23j42h34']}
    assert_raise(BioPieces::OptionError) { options_files_exist(options, :input) }
  end

  test '#options_files_exist with Arrays of non-existing files raise' do
    options = {input: [__FILE__], input2: ['h23j42h34']}
    assert_raise(BioPieces::OptionError) { options_files_exist(options, :input, :input2) }
  end

  test '#options_files_exist with existing file and glob don\'t raise' do
    glob = __FILE__.sub(/\.rb$/, '*')
    options = {input: glob}
    assert_nothing_raised { options_files_exist(options, :input) }
  end

  test '#options_files_exist with non-matching glob raises' do
    options = {input: 'f234rs*d32'}
    assert_raise(BioPieces::OptionError) { options_files_exist(options, :input) }
  end
end
