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
# This software is part of BioDSL (www.BioDSL.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

class FilesysTest < Test::Unit::TestCase
  def setup
    @zcat = BioDSL::Filesys::which('gzcat') || BioDSL::Filesys::which('zcat')

    @tmpdir     = Dir.mktmpdir("BioDSL")
    @file       = File.join(@tmpdir, 'test.txt')
    file_gzip   = File.join(@tmpdir, 'test_gzip.txt')
    file_bzip2  = File.join(@tmpdir, 'test_bzip2.txt')
    @file_gzip  = File.join(@tmpdir, 'test_gzip.txt.gz')
    @file_bzip2 = File.join(@tmpdir, 'test_bzip2.txt.bz2')

    File.open(@file, 'w')      { |ios| ios << "foobar" }
    File.open(file_gzip, 'w')  { |ios| ios << "foobar" }
    File.open(file_bzip2, 'w') { |ios| ios << "foobar" }

    `gzip #{file_gzip}`
    `bzip2 #{file_bzip2}`
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end


  test "#which with non-existing executable returns nil" do
    assert_nil(BioDSL::Filesys.which("__env__"))
  end

  test "#which with existing executable returns correctly" do
    assert_equal("/usr/bin/env", BioDSL::Filesys.which("env"))
  end

  test "#tmpfile returns correctly" do
    assert_equal(@tmpdir, BioDSL::Filesys.tmpfile(@tmpdir).match(/^#{@tmpdir}/).to_s)
  end

  test "#open in read mode returns correctly" do
    ios = BioDSL::Filesys.open(@file)
    assert_equal("foobar", ios.read)
    ios.close
  end

  test "#open in read mode with block context returns correctly" do
    BioDSL::Filesys.open(@file) { |ios| assert_equal("foobar", ios.read) }
  end

  test "#open in write mode outputs correctly" do
    ios = BioDSL::Filesys.open(@file, 'w')
    ios.write "foobar"
    ios.close
    File.open(@file) { |ios2| assert_equal("foobar", ios2.read) }
  end

  test "#open in write mode with block context outputs correctly" do
    BioDSL::Filesys.open(@file, 'w') { |ios| ios.write "foobar" }
    File.open(@file) { |ios| assert_equal("foobar", ios.read) }
  end

  test "#open gzip in read mode returns correctly" do
    ios = BioDSL::Filesys.open(@file_gzip)
    assert_equal("foobar", ios.read)
    ios.close
  end

  test "#open gzip in read mode with block context returns correctly" do
    BioDSL::Filesys.open(@file_gzip) { |ios| assert_equal("foobar", ios.read) }
  end

  test "#open gzip in write mode outputs correctly" do
    ios = BioDSL::Filesys.open(@file, 'w', compress: :gzip)
    ios.write "foobar"
    ios.close
    result = `#{@zcat} #{@file}`
    assert_equal("foobar", result)
  end

  test "#open gzip in write mode with block context outputs correctly" do
    BioDSL::Filesys.open(@file, 'w', compress: :gzip) { |ios| ios.write "foobar" }
    result = `#{@zcat} #{@file}`
    assert_equal("foobar", result)
  end

  test "#open bzip2 in read mode returns correctly" do
    ios = BioDSL::Filesys.open(@file_bzip2)
    assert_equal("foobar", ios.read)
    ios.close
  end

  test "#open bzip2 in read mode with block context returns correctly" do
    BioDSL::Filesys.open(@file_bzip2) { |ios| assert_equal("foobar", ios.read) }
  end

  test "#open bzip2 in write mode outputs correctly" do
    ios = BioDSL::Filesys.open(@file, 'w', compress: :bzip2)
    ios.write "foobar"
    ios.close
    result = `bzcat #{@file}`
    assert_equal("foobar", result)
  end

  test "#open bzip2 in write mode with block context outputs correctly" do
    BioDSL::Filesys.open(@file, 'w', compress: :bzip2) { |ios| ios.write "foobar" }
    result = `bzcat #{@file}`
    assert_equal("foobar", result)
  end

  test "#open if eof? returns correctly" do
    ios = BioDSL::Filesys.open(@file)
    assert_equal(false, ios.eof?)
    ios.read
    assert_equal(true, ios.eof?)
    ios.close
  end
end
