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

# Test class for OptionHelper.
# rubocop:disable Metrics/ClassLength,
class TestOptionsHelper < Test::Unit::TestCase
  include BioPieces::OptionsHelper

  def setup
    @err = BioPieces::OptionError
  end

  test '#options_allowed with disallowed option raises' do
    options = {bar: 'foo'}
    assert_raise(@err) { options_allowed(options, :foo) }
  end

  test '#options_allowed with allowed option dont raise' do
    options = {foo: 'bar'}
    assert_nothing_raised { options_allowed(options, :foo) }
  end

  test '#options_allowed with no options dont raise' do
    options = {}
    assert_nothing_raised { options_allowed(options, :foo) }
  end

  test '#options_allowed_values with disallowed value raises' do
    options = {bar: 'foo'}
    assert_raise(@err) { options_allowed_values(options, bar: [1]) }
  end

  test '#options_allowed_values with allowed value dont raise' do
    options = {bar: 'foo'}
    assert_nothing_raised { options_allowed_values(options, bar: ['foo']) }
  end

  test '#options_required w/o required options raises' do
    options = {bar: 'foo'}
    assert_raise(@err) { options_required(options, :foo) }
  end

  test '#options_required with required options dont raise' do
    options = {bar: 'foo', one: 'two'}
    assert_nothing_raised { options_required(options, :bar, :one) }
  end

  test '#options_required_unique with non-unique required options raises' do
    options = {bar: 'foo', one: 'two'}
    assert_raise(@err) { options_required_unique(options, :bar, :one) }
  end

  test '#options_required_unique with unique required options dont raise' do
    options = {bar: 'foo', one: 'two'}
    assert_nothing_raised { options_required_unique(options, :one) }
  end

  test '#options_unique with non-unique options raises' do
    options = {bar: 'foo', one: 'two'}
    assert_raise(@err) { options_unique(options, :bar, :one) }
  end

  test '#options_unique with unique options dont raise' do
    options = {bar: 'foo', one: 'two'}
    assert_nothing_raised { options_unique(options, :one) }
  end

  test '#options_unique with no options dont raise' do
    options = {}
    assert_nothing_raised { options_unique(options, :one) }
  end

  test '#options_list_unique with duplicate elements raise' do
    options = {foo: [0, 0]}

    assert_raise(@err) { options_list_unique(options, :foo) }
  end

  test '#options_list_unique with unique elements dont raise' do
    options = {foo: [0, 1]}
    assert_nothing_raised { options_list_unique(options, :foo) }
  end

  test '#options_tie w/o tie option raises' do
    options = {gzip: true}

    assert_raise(@err) { options_tie(options, gzip: :output) }
  end

  test '#options_tie with tie option dont raise' do
    options = {gzip: true, output: 'foo'}
    assert_nothing_raised { options_tie(options, gzip: :output) }
  end

  test '#options_tie with reverse tie option dont raise' do
    options = {gzip: true, output: 'foo'}
    assert_nothing_raised { options_tie(options, output: :gzip) }
  end

  test '#options_conflict with conflicting options raise' do
    options = {select: true, reject: true}
    assert_raise(@err) { options_conflict(options, select: :reject) }
  end

  test '#options_conflict with non-conflicting options dont raise' do
    options = {select: true}
    assert_nothing_raised { options_conflict(options, select: :reject) }
  end

  test '#options_files_exist w/o options dont raise' do
    options = {}
    assert_nothing_raised { options_files_exist(options, :foo) }
  end

  test '#options_files_exist with file dont raise' do
    options = {input: __FILE__}
    assert_nothing_raised { options_files_exist(options, :input) }
  end

  test '#options_files_exist with non-existing file raise' do
    options = {input: 'ljg34gj324'}
    assert_raise(@err) { options_files_exist(options, :input) }
  end

  test '#options_files_exist with one non-existing file raise' do
    options = {input: __FILE__, input2: '32g4g24g23'}
    assert_raise(@err) { options_files_exist(options, :input, :input2) }
  end

  test '#options_files_exist with Array of non-existing files raise' do
    options = {input: %w(__FILE__ h23j42h34)}
    assert_raise(@err) { options_files_exist(options, :input) }
  end

  test '#options_files_exist with Arrays of non-existing files raise' do
    options = {input: [__FILE__], input2: ['h23j42h34']}
    assert_raise(@err) { options_files_exist(options, :input, :input2) }
  end

  test '#options_files_exist with existing file and glob don\'t raise' do
    glob = __FILE__.sub(/\.rb$/, '*')
    options = {input: glob}
    assert_nothing_raised { options_files_exist(options, :input) }
  end

  test '#options_files_exist with non-matching glob raises' do
    options = {input: 'f234rs*d32'}
    assert_raise(@err) { options_files_exist(options, :input) }
  end

  test '#options_files_exist_force w/o options dont raise' do
    options = {}
    assert_nothing_raised { options_files_exist_force(options, :input) }
  end

  test '#options_files_exist_force with force dont raise' do
    options = {input: __FILE__, force: true}
    assert_nothing_raised { options_files_exist_force(options, :input) }
  end

  test '#options_files_exist_force w/o force raise' do
    options = {input: __FILE__}
    assert_raise(@err) { options_files_exist_force(options, :input) }
  end

  test '#options_dirs_exist w/o options dont raise' do
    options = {}
    assert_nothing_raised { options_dirs_exist(options, :foo) }
  end

  test '#options_dirs_exist with dir dont raise' do
    options = {input: __dir__}
    assert_nothing_raised { options_dirs_exist(options, :input) }
  end

  test '#options_dirs_exist with non-existing dir raise' do
    options = {input: 'ljg34gj324'}
    assert_raise(@err) { options_dirs_exist(options, :input) }
  end

  test '#options_dirs_exist with one non-existing dir raise' do
    options = {input: __dir__, input2: '32g4g24g23'}
    assert_raise(@err) { options_dirs_exist(options, :input, :input2) }
  end

  test '#options_dirs_exist with Array of non-existing dirs raise' do
    options = {input: [__dir__, 'h23j42h34']}
    assert_raise(@err) { options_dirs_exist(options, :input) }
  end

  test '#options_dirs_exist with Arrays of non-existing dirs raise' do
    options = {input: [__dir__], input2: ['h23j42h34']}
    assert_raise(@err) { options_dirs_exist(options, :input, :input2) }
  end

  test '#options_assert with false statement raise' do
    options = {min: 0}
    assert_raise(@err) { options_assert(options, ':min > 0') }
  end

  test '#options_assert with true statement dont raise' do
    options = {min: 0}
    assert_nothing_raised { options_assert(options, ':min == 0') }
  end

  test '#options_glob returns correctly' do
    glob    = __FILE__[0..-3] + '*'
    assert_equal([__FILE__], options_glob(glob))
  end

  test 'options_load_rc with existing option returns correctly' do
    file = Tempfile.new('rc_file')
    BioPieces::Config::RC_FILE = file.path

    begin
      File.write(file, 'test foo bar')
      options = {foo: 123}
      options_load_rc(options, :test)
      assert_equal({foo: 123}, options)
    ensure
      file.unlink
      file.close
    end
  end

  test 'options_load_rc w/o existing option returns correctly' do
    file = Tempfile.new('rc_file')
    BioPieces::Config::RC_FILE = file.path

    begin
      File.write(file, 'test foo bar')
      options = {}
      options_load_rc(options, :test)
      assert_equal({foo: 'bar'}, options)
    ensure
      file.unlink
      file.close
    end
  end
end
