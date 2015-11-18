#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..')

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

# Patching StingIO class.
class StringIO
  def get_entry
    self.gets
  end
end

# Test class for CSV.
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

#Organism;Sequence;Count
Human;ATACGTCAG;23524
Dog;AGCATGAC;2442
Mouse;GACTG;234
Cat;AAATGCA;2342

END

    table3 = <<END

Human       ATACGTCAG   5.24
Dog         AGCATGAC    4.2
Mouse       GACTG       3.4
Cat         AAATGCA     3.42

END

    io   = StringIO.new(table)
    @csv = BioDSL::CSV.new(io)

    @table  = table
    @table2 = table2
    @table3 = table3

    @file = Tempfile.new('foo')
  end

  def teardown
    @file.close
    @file.unlink
  end

  test 'CSV#skip returns correctly' do
    @csv.skip(3)

    result = []
    @csv.each_array { |array| result << array }

    expected = [['Mouse', 'GACTG', 234],
                ['Cat', 'AAATGCA', 2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path)
    expected = [["Human", "ATACGTCAG", 23524],
                ["Dog", "AGCATGAC", 2442],
                ["Mouse", "GACTG", 234],
                ["Cat", "AAATGCA", 2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with floats returns correctly" do
    @file.write(@table3)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path)
    expected = [["Human", "ATACGTCAG", 5.24],
                ["Dog", "AGCATGAC", 4.2],
                ["Mouse", "GACTG", 3.4],
                ["Cat", "AAATGCA", 3.42]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with include_header: true returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, include_header: true)
    expected = [["Organism", "Sequence", "Count"],
                ["Human", "ATACGTCAG", 23524],
                ["Dog", "AGCATGAC", 2442],
                ["Mouse", "GACTG", 234],
                ["Cat", "AAATGCA", 2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :delimiter returns correctly" do
    @file.write(@table2)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, delimiter: ";")
    expected = [["Human", "ATACGTCAG", 23524],
                ["Dog", "AGCATGAC", 2442],
                ["Mouse", "GACTG", 234],
                ["Cat", "AAATGCA", 2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :delimiter and :include_header returns correctly" do
    @file.write(@table2)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, delimiter: ";", include_header: true)
    expected = [["Organism", "Sequence", "Count"],
                ["Human", "ATACGTCAG", 23524],
                ["Dog", "AGCATGAC", 2442],
                ["Mouse", "GACTG", 234],
                ["Cat", "AAATGCA", 2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select and out-of-bounds numerical value raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_array(@file.path, select: [3]) }
  end

  test "CSV.read_array with :select of numerical values return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, select: [2, 0])
    expected = [[23524, "Human"],
                [2442,  "Dog"],
                [234,   "Mouse"],
                [2342,  "Cat"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select of numerical values and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, select: [2, 0], include_header: true)
    expected = [["Count", "Organism"],
                [23524, "Human"],
                [2442,  "Dog"],
                [234,   "Mouse"],
                [2342,  "Cat"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select and out-of-bounds range raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_array(@file.path, select: 1 .. 3) }
  end

  test "CSV.read_array with :select of range return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, select: 0 .. 1)
    expected = [["Human", "ATACGTCAG"],
                ["Dog", "AGCATGAC"],
                ["Mouse", "GACTG"],
                ["Cat", "AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select of range and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, select: 0 .. 1, include_header: true)
    expected = [["Organism", "Sequence"],
                ["Human", "ATACGTCAG"],
                ["Dog", "AGCATGAC"],
                ["Mouse", "GACTG"],
                ["Cat", "AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select of non-numerical values and no header raises" do
    @file.write(@table3)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_array(@file.path, select: ["Organism"]) }
  end

  test "CSV.read_array with :select of non-numerical values not matching header raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_array(@file.path, select: ["ount"]) }
  end

  test "CSV.read_array with :select of non-numerical values returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, select: ["Count", :Organism])
    expected = [[23524, "Human"],
                [2442,  "Dog"],
                [234,   "Mouse"],
                [2342,  "Cat"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select of non-numerical values and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, select: ["Count", :Organism], include_header: true)
    expected = [["Count", "Organism"],
                [23524,   "Human"],
                [2442,    "Dog"],
                [234,     "Mouse"],
                [2342,    "Cat"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject and out-of-bounds numerical value raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_array(@file.path, reject: [3]) }
  end

  test "CSV.read_array with :reject of numerical values return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, reject: [2, 0])
    expected = [["ATACGTCAG"],
                ["AGCATGAC"],
                ["GACTG"],
                ["AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject of numerical values and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, reject: [2, 0], include_header: true)
    expected = [["Sequence"],
                ["ATACGTCAG"],
                ["AGCATGAC"],
                ["GACTG"],
                ["AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject and out-of-bounds range raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_array(@file.path, reject: 1 .. 3) }
  end

  test "CSV.read_array with :reject of range return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, reject: 0 .. 1)
    expected = [[23524],
                [2442],
                [234],
                [2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject of range and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, reject: 0 .. 1, include_header: true)
    expected = [["Count"],
                [23524],
                [2442],
                [234],
                [2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject of non-numerical values and no header raises" do
    @file.write(@table3)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_array(@file.path, reject: ["Organism"]) }
  end

  test "CSV.read_array with :reject of non-numerical values not matching header raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_array(@file.path, reject: ["ount"]) }
  end

  test "CSV.read_array with :reject of non-numerical values returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, reject: ["Count", :Organism])
    expected = [["ATACGTCAG"],
                ["AGCATGAC"],
                ["GACTG"],
                ["AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject of non-numerical values and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_array(@file.path, reject: ["Count", :Organism], include_header: true)
    expected = [["Sequence"],
                ["ATACGTCAG"],
                ["AGCATGAC"],
                ["GACTG"],
                ["AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_hash returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path)
    expected = [{Count: 23524, Organism: "Human", Sequence: "ATACGTCAG"},
                {Count: 2442,  Organism: "Dog",   Sequence: "AGCATGAC"},
                {Count: 234,   Organism: "Mouse", Sequence: "GACTG"},
                {Count: 2342,  Organism: "Cat",   Sequence: "AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with no header returns correctly" do
    @file.write(@table3)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path)
    expected = [{V0: "Human", V1: "ATACGTCAG", V2: 5.24},
                {V0: "Dog",   V1: "AGCATGAC",  V2: 4.2},
                {V0: "Mouse", V1: "GACTG",     V2: 3.4},
                {V0: "Cat",   V1: "AAATGCA",   V2: 3.42}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :delimiter returns correctly" do
    @file.write(@table2)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path, delimiter: ";")
    expected = [{:Count=>23524, :Organism=>"Human", :Sequence=>"ATACGTCAG"},
                {:Count=>2442,  :Organism=>"Dog",   :Sequence=>"AGCATGAC"},
                {:Count=>234,   :Organism=>"Mouse", :Sequence=>"GACTG"},
                {:Count=>2342,  :Organism=>"Cat",   :Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :select and out-of-bounds numerical value raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_hash(@file.path, select: [3]) }
  end

  test "CSV.read_hash with :select of numerical values return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path, select: [2, 0])
    expected = [{:Count=>23524, :Organism=>"Human"},
                {:Count=>2442,  :Organism=>"Dog"},
                {:Count=>234,   :Organism=>"Mouse"},
                {:Count=>2342,  :Organism=>"Cat"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :select and out-of-bounds range raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_hash(@file.path, select: 1 .. 3) }
  end

  test "CSV.read_hash with :select of range return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path, select: 0 .. 1)
    expected = [{:Organism=>"Human", :Sequence=>"ATACGTCAG"},
                {:Organism=>"Dog",   :Sequence=>"AGCATGAC"},
                {:Organism=>"Mouse", :Sequence=>"GACTG"},
                {:Organism=>"Cat",   :Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :select of non-numerical values and no header raises" do
    @file.write(@table3)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_hash(@file.path, select: ["Organism"]) }
  end

  test "CSV.read_hash with :select of non-numerical values not matching header raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_hash(@file.path, select: ["ount"]) }
  end

  test "CSV.read_hash with :select of non-numerical values returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path, select: ["Count", :Organism])
    expected = [{:Count=>23524, :Organism=>"Human"},
                {:Count=>2442,  :Organism=>"Dog"},
                {:Count=>234,   :Organism=>"Mouse"},
                {:Count=>2342,  :Organism=>"Cat"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :reject and out-of-bounds numerical value raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_hash(@file.path, reject: [3]) }
  end

  test "CSV.read_hash with :reject of numerical values return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path, reject: [2, 0])
    expected = [{:Sequence=>"ATACGTCAG"},
                {:Sequence=>"AGCATGAC"},
                {:Sequence=>"GACTG"},
                {:Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :reject and out-of-bounds range raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_hash(@file.path, reject: 1 .. 3) }
  end

  test "CSV.read_hash with :reject of range return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path, reject: 0 .. 1)
    expected = [{:Count=>23524},
                {:Count=>2442},
                {:Count=>234},
                {:Count=>2342}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :reject of non-numerical values and no header raises" do
    @file.write(@table3)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_hash(@file.path, reject: ["Organism"]) }
  end

  test "CSV.read_hash with :reject of non-numerical values not matching header raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioDSL::CSVError) { BioDSL::CSV.read_hash(@file.path, reject: ["ount"]) }
  end

  test "CSV.read_hash with :reject of non-numerical values returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioDSL::CSV.read_hash(@file.path, reject: ["Count", :Organism])
    expected = [{:Sequence=>"ATACGTCAG"},
                {:Sequence=>"AGCATGAC"},
                {:Sequence=>"GACTG"},
                {:Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end
end
