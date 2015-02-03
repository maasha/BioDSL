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

    @table  = table
    @table2 = table2
    @table3 = table3

    @file = Tempfile.new('foo')
  end

  def teardown
    @file.close
    @file.unlink
  end

  test "CSV.read_array returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path)
    expected = [["Human", "ATACGTCAG", 23524],
                ["Dog", "AGCATGAC", 2442],
                ["Mouse", "GACTG", 234],
                ["Cat", "AAATGCA", 2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with include_header: true returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, include_header: true)
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
    result   = BioPieces::CSV.read_array(@file.path, delimiter: ";")
    expected = [["Human", "ATACGTCAG", 23524],
                ["Dog", "AGCATGAC", 2442],
                ["Mouse", "GACTG", 234],
                ["Cat", "AAATGCA", 2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :delimiter and :include_header returns correctly" do
    @file.write(@table2)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, delimiter: ";", include_header: true)
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
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_array(@file.path, select: [3]) }
  end

  test "CSV.read_array with :select of numerical values return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, select: [2, 0])
    expected = [[23524, "Human"],
                [2442,  "Dog"],
                [234,   "Mouse"],
                [2342,  "Cat"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select of numerical values and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, select: [2, 0], include_header: true)
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
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_array(@file.path, select: 1 .. 3) }
  end

  test "CSV.read_array with :select of range return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, select: 0 .. 1)
    expected = [["Human", "ATACGTCAG"],
                ["Dog", "AGCATGAC"],
                ["Mouse", "GACTG"],
                ["Cat", "AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select of range and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, select: 0 .. 1, include_header: true)
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
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_array(@file.path, select: ["Organism"]) }
  end

  test "CSV.read_array with :select of non-numerical values not matching header raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_array(@file.path, select: ["ount"]) }
  end

  test "CSV.read_array with :select of non-numerical values returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, select: ["Count", :Organism])
    expected = [[23524, "Human"],
                [2442,  "Dog"],
                [234,   "Mouse"],
                [2342,  "Cat"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :select of non-numerical values and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, select: ["Count", :Organism], include_header: true)
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
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_array(@file.path, reject: [3]) }
  end

  test "CSV.read_array with :reject of numerical values return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, reject: [2, 0])
    expected = [["ATACGTCAG"],
                ["AGCATGAC"],
                ["GACTG"],
                ["AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject of numerical values and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, reject: [2, 0], include_header: true)
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
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_array(@file.path, reject: 1 .. 3) }
  end

  test "CSV.read_array with :reject of range return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, reject: 0 .. 1)
    expected = [[23524],
                [2442],
                [234],
                [2342]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject of range and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, reject: 0 .. 1, include_header: true)
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
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_array(@file.path, reject: ["Organism"]) }
  end

  test "CSV.read_array with :reject of non-numerical values not matching header raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_array(@file.path, reject: ["ount"]) }
  end

  test "CSV.read_array with :reject of non-numerical values returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, reject: ["Count", :Organism])
    expected = [["ATACGTCAG"],
                ["AGCATGAC"],
                ["GACTG"],
                ["AAATGCA"]]

    assert_equal(expected, result)
  end

  test "CSV.read_array with :reject of non-numerical values and :include_header returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_array(@file.path, reject: ["Count", :Organism], include_header: true)
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
    result   = BioPieces::CSV.read_hash(@file.path)
    expected = [{Count: 23524, Organism: "Human", Sequence: "ATACGTCAG"},
                {Count: 2442,  Organism: "Dog",   Sequence: "AGCATGAC"},
                {Count: 234,   Organism: "Mouse", Sequence: "GACTG"},
                {Count: 2342,  Organism: "Cat",   Sequence: "AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :delimiter returns correctly" do
    @file.write(@table2)
    @file.rewind
    result   = BioPieces::CSV.read_hash(@file.path, delimiter: ";")
    expected = [{:Count=>23524, :Organism=>"Human", :Sequence=>"ATACGTCAG"},
                {:Count=>2442,  :Organism=>"Dog",   :Sequence=>"AGCATGAC"},
                {:Count=>234,   :Organism=>"Mouse", :Sequence=>"GACTG"},
                {:Count=>2342,  :Organism=>"Cat",   :Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :select and out-of-bounds numerical value raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_hash(@file.path, select: [3]) }
  end

  test "CSV.read_hash with :select of numerical values return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_hash(@file.path, select: [2, 0])
    expected = [{:Count=>23524, :Organism=>"Human"},
                {:Count=>2442,  :Organism=>"Dog"},
                {:Count=>234,   :Organism=>"Mouse"},
                {:Count=>2342,  :Organism=>"Cat"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :select and out-of-bounds range raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_hash(@file.path, select: 1 .. 3) }
  end

  test "CSV.read_hash with :select of range return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_hash(@file.path, select: 0 .. 1)
    expected = [{:Organism=>"Human", :Sequence=>"ATACGTCAG"},
                {:Organism=>"Dog",   :Sequence=>"AGCATGAC"},
                {:Organism=>"Mouse", :Sequence=>"GACTG"},
                {:Organism=>"Cat",   :Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :select of non-numerical values and no header raises" do
    @file.write(@table3)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_hash(@file.path, select: ["Organism"]) }
  end

  test "CSV.read_hash with :select of non-numerical values not matching header raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_hash(@file.path, select: ["ount"]) }
  end

  test "CSV.read_hash with :select of non-numerical values returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_hash(@file.path, select: ["Count", :Organism])
    expected = [{:Count=>23524, :Organism=>"Human"},
                {:Count=>2442,  :Organism=>"Dog"},
                {:Count=>234,   :Organism=>"Mouse"},
                {:Count=>2342,  :Organism=>"Cat"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :reject and out-of-bounds numerical value raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_hash(@file.path, reject: [3]) }
  end

  test "CSV.read_hash with :reject of numerical values return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_hash(@file.path, reject: [2, 0])
    expected = [{:Sequence=>"ATACGTCAG"},
                {:Sequence=>"AGCATGAC"},
                {:Sequence=>"GACTG"},
                {:Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :reject and out-of-bounds range raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_hash(@file.path, reject: 1 .. 3) }
  end

  test "CSV.read_hash with :reject of range return correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_hash(@file.path, reject: 0 .. 1)
    expected = [{:Count=>23524},
                {:Count=>2442},
                {:Count=>234},
                {:Count=>2342}]

    assert_equal(expected, result)
  end

  test "CSV.read_hash with :reject of non-numerical values and no header raises" do
    @file.write(@table3)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_hash(@file.path, reject: ["Organism"]) }
  end

  test "CSV.read_hash with :reject of non-numerical values not matching header raises" do
    @file.write(@table)
    @file.rewind
    assert_raise(BioPieces::CSVError) { BioPieces::CSV.read_hash(@file.path, reject: ["ount"]) }
  end

  test "CSV.read_hash with :reject of non-numerical values returns correctly" do
    @file.write(@table)
    @file.rewind
    result   = BioPieces::CSV.read_hash(@file.path, reject: ["Count", :Organism])
    expected = [{:Sequence=>"ATACGTCAG"},
                {:Sequence=>"AGCATGAC"},
                {:Sequence=>"GACTG"},
                {:Sequence=>"AAATGCA"}]

    assert_equal(expected, result)
  end





#  test "CSV#each_array with :columns returns correctly" do
#    result = []
#    @csv.each_array(columns: [0, 2]) { |array| result << array }
#
#    expected = [["Human", 23524], ["Dog", 2442], ["Mouse", 234], ["Cat", 2342]]
#
#    assert_equal(expected, result)
#  end
#

#  test "CSV.read_array with select option and bad Array values raises" do
#    @file.write(@table)
#    @file.rewind
#    assert_nothing_raised { BioPieces::CSV.read_array(@file.path, select: [3]) }
#  end

#  test "CSV#each returns correctly" do
#    result = []
#    @csv.each { |line| result << line }
#
#    expected = ["Human       ATACGTCAG   23524\n",
#                "Dog         AGCATGAC    2442\n",
#                "Mouse       GACTG       234\n",
#                "Cat         AAATGCA     2342\n"]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each with include_header: true returns correctly" do
#    result = []
#    @csv.each(include_header: true) { |line| result << line }
#
#    expected = ["Organism   Sequence    Count\n",
#                "Human       ATACGTCAG   23524\n",
#                "Dog         AGCATGAC    2442\n",
#                "Mouse       GACTG       234\n",
#                "Cat         AAATGCA     2342\n"]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_array returns correctly" do
#    result = []
#    @csv.each_array { |array| result << array }
#
#    expected = [["Human", "ATACGTCAG", 23524],
#                ["Dog", "AGCATGAC", 2442],
#                ["Mouse", "GACTG", 234],
#                ["Cat", "AAATGCA", 2342]]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_array with :delimiter returns correctly" do
#    result = []
#    @csv.each_array(delimiter: "foobar") { |array| result << array }
#
#    expected = [["Human       ATACGTCAG   23524"],
#                ["Dog         AGCATGAC    2442"],
#                ["Mouse       GACTG       234"],
#                ["Cat         AAATGCA     2342"]]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_array with bad :columns raises" do
#    assert_raise(BioPieces::CSVError) { @csv.each_array(columns: [0, 2, 5]) {} }
#  end
#
#  test "CSV#each_array with :select and no header raises" do
#    assert_raise(BioPieces::CSVError) { @csv2.each_array(select: :Count) {} }
#  end
#
#  test "CSV#each_array with :select and no such column raises" do
#    assert_raise(BioPieces::CSVError) { @csv.each_array(select: :Foo) {} }
#  end
#
#  test "CSV#each_array with :select returns correctly" do
#    result = []
#    @csv.each_array(select: [:Count, :Organism]) { |array| result << array }
#
#    expected = [[23524, "Human"],
#                [2442,  "Dog"],
#                [234,   "Mouse"],
#                [2342,  "Cat"]]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_array with :reject and no header raises" do
#    assert_raise(BioPieces::CSVError) { @csv2.each_array(reject: :Count) {} }
#  end
#
#  test "CSV#each_array with :reject and no such column raises" do
#    assert_raise(BioPieces::CSVError) { @csv.each_array(reject: :Foo) {} }
#  end
#
#  test "CSV#each_array with :reject returns correctly" do
#    result = []
#    @csv.each_array(reject: [:Count, :Organism]) { |array| result << array }
#
#    expected = [["ATACGTCAG"],
#                ["AGCATGAC"],
#                ["GACTG"],
#                ["AAATGCA"]]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_hash returns correctly" do
#    result = []
#    @csv.each_hash { |hash| result << hash }
#
#    expected = [{:V0=>"Human", :V1=>"ATACGTCAG", :V2=>23524},
#                {:V0=>"Dog", :V1=>"AGCATGAC", :V2=>2442},
#                {:V0=>"Mouse", :V1=>"GACTG", :V2=>234},
#                {:V0=>"Cat", :V1=>"AAATGCA", :V2=>2342}]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_hash with delimiter returns correctly" do
#    result = []
#    @csv.each_hash(delimiter: "foobar") { |hash| result << hash }
#
#    expected = [{:V0=>"Human       ATACGTCAG   23524"},
#                {:V0=>"Dog         AGCATGAC    2442"},
#                {:V0=>"Mouse       GACTG       234"},
#                {:V0=>"Cat         AAATGCA     2342"}]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_hash with bad :header raises" do
#    assert_raise(BioPieces::CSVError) { @csv.each_hash(header: [:Organism, "Sequence", :Count, :BadColumn]) {} }
#  end
#
#  test "CSV#each_hash with :header returns correctly" do
#    result = []
#
#    @csv.each_hash(header: @csv.header) { |hash| result << hash }
#
#    expected = [{:Organism=>"Human", :Sequence=>"ATACGTCAG", :Count=>23524},
#                {:Organism=>"Dog", :Sequence=>"AGCATGAC", :Count=>2442},
#                {:Organism=>"Mouse", :Sequence=>"GACTG", :Count=>234},
#                {:Organism=>"Cat", :Sequence=>"AAATGCA", :Count=>2342}]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_hash with bad :columns raises" do
#    assert_raise(BioPieces::CSVError) { @csv.each_hash(columns: [5, 2]) {} }
#  end
#
#  test "CSV#each_hash with :columns returns correctly" do
#    result = []
#
#    @csv.each_hash(columns: [1]) { |hash| result << hash }
#
#    expected = [{:V0=>"ATACGTCAG"},
#                {:V0=>"AGCATGAC"},
#                {:V0=>"GACTG"},
#                {:V0=>"AAATGCA"}]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_hash with bad :header and :columns raises" do
#    assert_raise(BioPieces::CSVError) { @csv.each_hash(header: [:foo, :bar], columns: [1]) {} }
#  end
#
#  test "CSV#each_hash with :header and :columns returns correctly" do
#    result = []
#
#    @csv.each_hash(header: @csv.header(columns: [1]), columns: [1]) { |hash| result << hash }
#
#    expected = [{:Sequence=>"ATACGTCAG"},
#                {:Sequence=>"AGCATGAC"},
#                {:Sequence=>"GACTG"},
#                {:Sequence=>"AAATGCA"}]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_hash with floats returns correctly" do
#    result = []
#
#    @csv2.each_hash { |hash| result << hash }
#
#    expected = [{:V0=>"Human", :V1=>"ATACGTCAG", :V2=>5.24},
#                {:V0=>"Dog", :V1=>"AGCATGAC", :V2=>4.2},
#                {:V0=>"Mouse", :V1=>"GACTG", :V2=>3.4},
#                {:V0=>"Cat", :V1=>"AAATGCA", :V2=>3.42}]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_hash with :select and no header raises" do
#    assert_raise(BioPieces::CSVError) { @csv2.each_hash(select: :Count) {} }
#  end
#
#  test "CSV#each_hash with :select and no such column raises" do
#    assert_raise(BioPieces::CSVError) { @csv.each_hash(select: :Foo) {} }
#  end
#
#  test "CSV#each_hash with :select returns correctly" do
#    result = []
#    @csv.each_hash(select: [:Count, :Organism]) { |hash| result << hash }
#
#    expected = [{:Count=>23524, :Organism=>"Human"},
#                {:Count=>2442, :Organism=>"Dog"},
#                {:Count=>234, :Organism=>"Mouse"},
#                {:Count=>2342, :Organism=>"Cat"}]
#
#    assert_equal(expected, result)
#  end
#
#  test "CSV#each_hash with :reject and no header raises" do
#    assert_raise(BioPieces::CSVError) { @csv2.each_hash(reject: :Count) {} }
#  end
#
#  test "CSV#each_hash with :reject and no such column raises" do
#    assert_raise(BioPieces::CSVError) { @csv.each_hash(reject: :Foo) {} }
#  end
#
#  test "CSV#each_hash with :reject returns correctly" do
#    result = []
#    @csv.each_hash(reject: [:Count, :Organism]) { |hash| result << hash }
#
#    expected = [{:Sequence=>"ATACGTCAG"},
#                {:Sequence=>"AGCATGAC"},
#                {:Sequence=>"GACTG"},
#                {:Sequence=>"AAATGCA"}]
#
#    assert_equal(expected, result)
#  end
end
