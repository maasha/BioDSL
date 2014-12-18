#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..')

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

class StringIO
  def get_entry
    self.gets
  end
end

class TestCSV < Test::Unit::TestCase 
  require 'stringio'
  require 'tempfile'

  def setup
    table = <<END
#Organism   Sequence    Count
Human       ATACGTCAG   23524
Dog         AGCATGAC    2442
Mouse       GACTG       234
Cat         AAATGCA     2342

END

    table2 = <<END

Human       ATACGTCAG   5.24
Dog         AGCATGAC    4.2
Mouse       GACTG       3.4
Cat         AAATGCA     3.42

END

    table3 = <<END

Human       ATACGTCAG   5.24
Dog         AGCATGAC    4.2
Mouse       GACTG       3.4
Mouse       GACTG       3.4
Mouse       GACTG       3.4
Mouse       GACTG       3.4
Mouse       GACTG       3.4
Mouse       GACTG       3.4
Mouse       GACTG       3.4
Mouse       GACTG       3.4
Mouse       GACTG       3.4
Cat         AAATGCA     3.42

END

    io    = StringIO.new(table)
    io2   = StringIO.new(table2)
    io3   = StringIO.new(table3)
    @csv  = BioPieces::CSV.new(io)
    @csv2 = BioPieces::CSV.new(io2)
    @csv3 = BioPieces::CSV.new(io3)

    @table = table
  end

  test "CSV.read returns correctly" do
    file = Tempfile.new('foo')

    begin
      file.write(@table)
      file.rewind
      result   = BioPieces::CSV.read(file.path)
      expected = [["Human", "ATACGTCAG", 23524],
                  ["Dog", "AGCATGAC", 2442],
                  ["Mouse", "GACTG", 234],
                  ["Cat", "AAATGCA", 2342]]

      assert_equal(expected, result)
    ensure
      file.close
      file.unlink
    end
  end

  test "CSV#each returns correctly" do
    result = []
    @csv.each { |line| result << line }

    expected = ["Human       ATACGTCAG   23524\n",
                "Dog         AGCATGAC    2442\n",
                "Mouse       GACTG       234\n",
                "Cat         AAATGCA     2342\n"]

    assert_equal(expected, result)
  end

  test "CSV#each_array returns correctly" do
    result = []
    @csv.each_array { |array| result << array }

    expected = [["Human", "ATACGTCAG", 23524],
                ["Dog", "AGCATGAC", 2442],
                ["Mouse", "GACTG", 234],
                ["Cat", "AAATGCA", 2342]]

    assert_equal(expected, result)
  end

  test "CSV#each_array with :delimiter returns correctly" do
    result = []
    @csv.each_array(delimiter: "foobar") { |array| result << array }

    expected = [["Human       ATACGTCAG   23524"],
                ["Dog         AGCATGAC    2442"],
                ["Mouse       GACTG       234"],
                ["Cat         AAATGCA     2342"]]

    assert_equal(expected, result)
  end

  test "CSV#each_array with :columns returns correctly" do
    result = []
    @csv.each_array(columns: [0, 2]) { |array| result << array }

    expected = [["Human", 23524], ["Dog", 2442], ["Mouse", 234], ["Cat", 2342]]

    assert_equal(expected, result)
  end

  test "CSV#header returns correctly" do
    assert_equal([:Organism, :Sequence, :Count], @csv.header)
    assert_equal([:Organism, :Sequence, :Count], @csv.header)
  end

  test "CSV#skip returns correctly" do
    @csv.skip(3)

    result = []
    @csv.each_array { |array| result << array }

    expected = [["Mouse", "GACTG", 234], ["Cat", "AAATGCA", 2342]]

    assert_equal(expected, result)
  end

  test "CSV#each_hash returns correctly" do
    result = []
    @csv.each_hash { |hash| result << hash }

    expected = [{:V0=>"Human", :V1=>"ATACGTCAG", :V2=>23524},
                {:V0=>"Dog", :V1=>"AGCATGAC", :V2=>2442},
                {:V0=>"Mouse", :V1=>"GACTG", :V2=>234},
                {:V0=>"Cat", :V1=>"AAATGCA", :V2=>2342}]

    assert_equal(expected, result)
  end

  test "CSV#each_hash with delimiter returns correctly" do
    result = []
    @csv.each_hash(delimiter: "foobar") { |hash| result << hash }

    expected = [{:V0=>"Human       ATACGTCAG   23524"},
                {:V0=>"Dog         AGCATGAC    2442"},
                {:V0=>"Mouse       GACTG       234"},
                {:V0=>"Cat         AAATGCA     2342"}]

    assert_equal(expected, result)
  end

  test "CSV#each_hash with :header returns correctly" do
    result = []

    @csv.each_hash(header: @csv.header) { |hash| result << hash }

    expected = [{:Organism=>"Human", :Sequence=>"ATACGTCAG", :Count=>23524},
                {:Organism=>"Dog", :Sequence=>"AGCATGAC", :Count=>2442},
                {:Organism=>"Mouse", :Sequence=>"GACTG", :Count=>234},
                {:Organism=>"Cat", :Sequence=>"AAATGCA", :Count=>2342}]

    assert_equal(expected, result)
  end

  test "CSV#each_hash with :columns returns correctly" do
    result = []

    @csv.each_hash(columns: [1]) { |hash| result << hash }

    expected = [{:V0=>"ATACGTCAG"},
                {:V0=>"AGCATGAC"},
                {:V0=>"GACTG"},
                {:V0=>"AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV#each_hash with :header and :columns returns correctly" do
    result = []

    @csv.each_hash(header: @csv.header(columns: [1]), columns: [1]) { |hash| result << hash }

    expected = [{:Sequence=>"ATACGTCAG"},
                {:Sequence=>"AGCATGAC"},
                {:Sequence=>"GACTG"},
                {:Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV#each_hash with floats returns correctly" do
    result = []

    @csv2.each_hash { |hash| result << hash }

    expected = [{:V0=>"Human", :V1=>"ATACGTCAG", :V2=>5.24},
                {:V0=>"Dog", :V1=>"AGCATGAC", :V2=>4.2},
                {:V0=>"Mouse", :V1=>"GACTG", :V2=>3.4},
                {:V0=>"Cat", :V1=>"AAATGCA", :V2=>3.42}]

    assert_equal(expected, result)
  end
end
