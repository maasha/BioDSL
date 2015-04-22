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

# Test class for AnalyzeResidueDistribution.
class TestAnalyzeResidueDistribution < Test::Unit::TestCase
  def setup
    @tmpdir = Dir.mktmpdir('BioPieces')
    @file   = File.join(@tmpdir, 'test.plot')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    [{SEQ: 'AGCT'},
     {SEQ: 'AGCU'},
     {SEQ: 'FLS*'},
     {SEQ: '-.~'},
     {FOO: 'BAR'}].each do |record|
      @output.write(record)
    end

    @output.close

    @p = BP.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioPieces::Pipeline#analyze_residue_distribution with disallowed ' \
    'option raises' do
    assert_raise(BioPieces::OptionError) do
      @p.analyze_residue_distribution(foo: 'bar')
    end
  end

  test 'BioPieces::Pipeline#analyze_residue_distribution with allowed ' \
    'options don\'t raise' do
    assert_nothing_raised { @p.analyze_residue_distribution(percent: true) }
  end

  # rubocop:disable Metrics/LineLength
  test 'BioPieces::Pipeline#analyze_residue_distribution returns correctly' do
    @p.analyze_residue_distribution.run(input: @input, output: @output2)
    expected = <<-EOD.gsub(/^\s*\|/, '')
      |{:SEQ=>"AGCT"}
      |{:SEQ=>"AGCU"}
      |{:SEQ=>"FLS*"}
      |{:SEQ=>"-.~"}
      |{:FOO=>"BAR"}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"A", :V1=>2, :V2=>0, :V3=>0, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"G", :V1=>0, :V2=>2, :V3=>0, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"C", :V1=>0, :V2=>0, :V3=>2, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"T", :V1=>0, :V2=>0, :V3=>0, :V4=>1}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"U", :V1=>0, :V2=>0, :V3=>0, :V4=>1}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"F", :V1=>1, :V2=>0, :V3=>0, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"L", :V1=>0, :V2=>1, :V3=>0, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"S", :V1=>0, :V2=>0, :V3=>1, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"*", :V1=>0, :V2=>0, :V3=>0, :V4=>1}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"-", :V1=>1, :V2=>0, :V3=>0, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>".", :V1=>0, :V2=>1, :V3=>0, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"~", :V1=>0, :V2=>0, :V3=>1, :V4=>0}
    EOD
    assert_equal(expected, collect_result)
  end

  test 'BioPieces::Pipeline#analyze_residue_distribution with :precent returns correctly' do
    @p.analyze_residue_distribution(percent: true).run(input: @input, output: @output2)
    expected = <<-EOD.gsub(/^\s*\|/, '')
      |{:SEQ=>"AGCT"}
      |{:SEQ=>"AGCU"}
      |{:SEQ=>"FLS*"}
      |{:SEQ=>"-.~"}
      |{:FOO=>"BAR"}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"A", :V1=>50, :V2=>0,  :V3=>0,  :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"G", :V1=>0,  :V2=>50, :V3=>0,  :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"C", :V1=>0,  :V2=>0,  :V3=>50, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"T", :V1=>0,  :V2=>0,  :V3=>0,  :V4=>33}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"U", :V1=>0,  :V2=>0,  :V3=>0,  :V4=>33}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"F", :V1=>25, :V2=>0,  :V3=>0,  :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"L", :V1=>0,  :V2=>25, :V3=>0,  :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"S", :V1=>0,  :V2=>0,  :V3=>25, :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"*", :V1=>0,  :V2=>0,  :V3=>0,  :V4=>33}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"-", :V1=>25, :V2=>0,  :V3=>0,  :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>".", :V1=>0,  :V2=>25, :V3=>0,  :V4=>0}
      |{:RECORD_TYPE=>"residue distribution", :V0=>"~", :V1=>0,  :V2=>0,  :V3=>25, :V4=>0}
    EOD
    assert_equal(expected.gsub(/  /, ' '), collect_result)
  end
end
