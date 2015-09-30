#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..')

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
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

# rubocop: disable ClassLength

# Test class for Pipeline.
class PipelineTest < Test::Unit::TestCase
  require 'yaml'

  def setup
    @tmpdir = Dir.mktmpdir('BioDSL')

    setup_fasta_files

    Mail.defaults do
      delivery_method :test
    end

    @p = BP.new
  end

  def setup_fasta_files
    @fasta_file  = File.join(@tmpdir, 'test.fna')
    @fasta_file2 = File.join(@tmpdir, 'test2.fna')

    File.open(@fasta_file, 'w') do |ios|
      ios.puts <<-DATA.gsub(/^\s+\|/, '')
        |>test1
        |atcg
        |>test2
        |tgac
      DATA
    end
  end

  def teardown
    FileUtils.rm_r @tmpdir

    Mail::TestMailer.deliveries.clear
  end

  test 'BioDSL::Pipeline#to_s w/o options and w/o .run() returns OK' do
    @p.commands << BioDSL::Command.new('dump', nil, {})
    expected = %(BP.new.dump)
    assert_equal(expected, @p.to_s)
  end

  test 'BioDSL::Pipeline#to_s with options and w/o .run() returns OK' do
    @p.commands << BioDSL::Command.new('read_fasta', nil, input: 'test.fna')
    expected = %(BP.new.read_fasta(input: "test.fna"))
    assert_equal(expected, @p.to_s)
  end

  test 'BioDSL::Pipeline#to_s w/o options and .run() returns OK' do
    @p.commands << BioDSL::Command.new('dump', nil, {})
    @p.complete = true
    expected = %(BP.new.dump.run)
    assert_equal(expected, @p.run.to_s)
  end

  test 'BioDSL::Pipeline#to_s with options and .run() returns OK' do
    @p.commands << BioDSL::Command.new('read_fasta', nil, input: 'test.fna')
    @p.complete = true
    expected = %{BP.new.read_fasta(input: "test.fna").run}
    assert_equal(expected, @p.run.to_s)
  end

  test 'BioDSL::Pipeline#run with no commands raises' do
    assert_raise(BioDSL::PipelineError) { @p.run }
  end

  test 'BioDSL::Pipeline#size returns correctly' do
    assert_equal(0, @p.size)
    @p.dump
    assert_equal(1, @p.size)
  end

  test 'BioDSL::Pipeline#+ with non-Pipeline object raises' do
    assert_raise(BioDSL::PipelineError) { @p + 'foo' }
  end

  test 'BioDSL::Pipeline#+ with Pipeline object dont raise' do
    assert_nothing_raised { @p + @p }
  end

  test 'BioDSL::Pipeline#+ of two Pipelines return correctly' do
    p = BioDSL::Pipeline.new.dump(first: 2)
    assert_equal('BP.new.dump(first: 2)', (@p + p).to_s)
  end

  test 'BioDSL::Pipeline#+ of three Pipelines return correctly' do
    p1 = BioDSL::Pipeline.new.dump(first: 2)
    p2 = BioDSL::Pipeline.new.dump(last: 3)
    assert_equal('BP.new.dump(first: 2).dump(last: 3)', (@p + p1 + p2).to_s)
  end

  test 'BioDSL::Pipeline#pop decreases size' do
    @p.dump
    assert_equal(1, @p.size)
    @p.pop
    assert_equal(0, @p.size)
    @p.pop
    assert_equal(0, @p.size)
  end

  test 'BioDSL::Pipeline#pop returns correctly' do
    @p.dump
    assert_equal(BioDSL::Pipeline.new.dump.to_s, @p.pop.to_s)
    assert_equal(BioDSL::Pipeline.new.to_s, @p.to_s)
  end

  test 'BioDSL::Pipeline#status without .run() returns correctly' do
    status = @p.read_fasta(input: __FILE__).status
    assert_equal({}, status.first)
  end

  test 'BioDSL::Pipeline#status with .run() returns correctly' do
    expected = %{BioDSL::Pipeline.new.read_fasta(input: "#{@fasta_file}")}
    @p.expects(:status).returns(expected)
    assert_equal(expected, @p.read_fasta(input: @fasta_file).run.status)
  end

  test 'BioDSL::Pipeline#run with disallowed option raises' do
    assert_raise(BioDSL::OptionError) do
      @p.read_fasta(input: @fasta_file).run(foo: 'bar')
    end
  end

  test 'BioDSL::Pipeline#run returns correctly' do
    @p.read_fasta(input: @fasta_file).write_fasta(output: @fasta_file2).run

    expected = File.read(@fasta_file)
    result   = File.read(@fasta_file2)

    assert_equal(expected, result)
  end

  test 'BioDSL::Pipeline#run with subject but no email raises' do
    assert_raise(BioDSL::OptionError) do
      @p.read_fasta(input: @fasta_file).run(subject: 'foobar')
    end
  end

  test 'BioDSL::Pipeline#run with email sends mail correctly' do
    omit
    @p.read_fasta(input: @fasta_file).run(email: 'test@foobar.com')
    assert_equal(1, Mail::TestMailer.deliveries.length)
    assert_equal(@p.to_s, Mail::TestMailer.deliveries.first.subject)
  end

  test 'BioDSL::Pipeline#run with email and subject sends correctly' do
    omit
    @p.read_fasta(input: @fasta_file).
      run(email: 'test@foobar.com', subject: 'foobar')

    assert_equal(1, Mail::TestMailer.deliveries.length)
    assert_equal('foobar', Mail::TestMailer.deliveries.first.subject)
  end
end
