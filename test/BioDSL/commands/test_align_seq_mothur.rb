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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for AlignSeqMothur.
class TestAlignSeqMothur < Test::Unit::TestCase
  def setup
    require 'tempfile'

    omit('mothur not found') unless BioDSL::Filesys.which('mothur')

    @template = Tempfile.new('template')

    write_template

    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(SEQ_NAME: 'test', SEQ: 'gattccgatcgatcgatcga')
    @output.close

    @p = BD.new
  end

  def write_template
    seq_name = 'ref'
    seq      = '--a-ttc--c-a-tcga----Ttcg-at---cCa---'
    BioDSL::Fasta.open(@template, 'w') do |ios|
      ios.puts BioDSL::Seq.new(seq_name: seq_name, seq: seq).to_fasta
    end
  end

  def teardown
    @template.close
    @template.unlink
  end

  test 'BioDSL::Pipeline#align_seq_mothur with disallowed option raises' do
    assert_raise(BioDSL::OptionError) do
      @p.align_seq_mothur(template_file: @template, foo: 'bar')
    end
  end

  test 'BioDSL::Pipeline#align_seq_mothur w. allowed option don\'t raise' do
    assert_nothing_raised do
      @p.align_seq_mothur(template_file: @template, cpus: 2)
    end
  end

  test 'BioDSL::Pipeline#align_seq_mothur outputs correctly' do
    @p.align_seq_mothur(template_file: @template.path).
      run(input: @input, output: @output2)

    expected = '{:SEQ_NAME=>"test", ' \
      ':SEQ=>"..A-TTC--CGA-TCGA-----TCG-AT---CGA...", :SEQ_LEN=>37}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline#align_seq_mothur status returns correctly' do
    @p.align_seq_mothur(template_file: @template.path).
      run(input: @input, output: @output2)

    assert_equal(1, @p.status.first[:records_in])
    assert_equal(1, @p.status.first[:records_out])
    assert_equal(1, @p.status.first[:sequences_in])
    assert_equal(1, @p.status.first[:sequences_in])
    assert_equal(20, @p.status.first[:residues_in])
    assert_equal(20, @p.status.first[:residues_in])
  end
end
