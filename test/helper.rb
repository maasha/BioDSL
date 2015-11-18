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

require 'simplecov'
require 'English'

if ENV['SIMPLECOV']
  SimpleCov.start do
    add_filter '/test/'
  end

  SimpleCov.command_name 'test:units'
end

require 'pp'
require 'tempfile'
require 'fileutils'
require 'BioDSL'
require 'test/unit'
require 'mocha/test_unit'

ENV['BD_TEST'] = 'true'

# Kernel namespace
module Kernel
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out.string
  ensure
    $stdout = STDOUT
  end

  def capture_stderr
    out = StringIO.new
    $stderr = out
    yield
    return out.string
  ensure
    $stderr = STDERR
  end
end

# Patching TestCase
class Test::Unit::TestCase
  # Ruby 2.2 have omit, < 2.2 have skip
  alias_method :omit, :skip unless instance_methods.include? :omit

  def self.test(desc, &impl)
    define_method("test #{desc}", &impl)
  end

  def collect_result
    @input2.each_with_object('') { |e, a| a << "#{e}#{$RS}" }
  end

  def collect_sorted_result
    @input2.sort_by(&:to_s).each_with_object('') { |e, a| a << "#{e}#{$RS}" }
  end
end
