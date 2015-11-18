require 'bundler'
require 'English'
require 'rake/testtask'
require 'pp'

Bundler::GemHelper.install_tasks

task default: 'test'

Rake::TestTask.new do |t|
  t.description = 'Run test suite'
  t.test_files  = Dir['test/**/*'].select { |f| f.match(/\.rb$/) }
  t.warning     = true
end

desc 'Run test suite with simplecov'
task :simplecov do
  ENV['SIMPLECOV'] = 'true'
  Rake::Task['test'].invoke
end

desc 'Add or update yardoc'
task :doc do
  run_docgen
end

task build: :boilerplate

desc 'Add or update license boilerplate in source files'
task :boilerplate do
  run_boilerplate
end

def run_docgen
  $stderr.puts 'Building docs'
  `yardoc lib/`
  $stderr.puts 'Docs done'
end

def run_boilerplate
  boilerplate = <<END
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# Copyright (C) 2007-#{Time.now.year} Martin Asser Hansen (mail@maasha.dk).                #
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
END

  files = Rake::FileList.new('bin/**/*', 'lib/**/*.rb', 'test/**/*.rb')

  files.each do |file|
    body = ''

    File.open(file) do |ios|
      body = ios.read
    end

    if body.match(/Copyright \(C\) 2007-(\d{4}) Martin Asser Hansen/) &&
       Regexp.last_match[1].to_i != Time.now.year
      STDERR.puts "Updating boilerplate: #{file}"

      body.sub!(/Copyright \(C\) 2007-(\d{4}) Martin Asser Hansen/,
                "Copyright (C) 2007-#{Time.now.year} Martin Asser Hansen")

      File.open(file, 'w') do |ios|
        ios.puts body
      end
    end

    next unless body.match('Copyright')
    STDERR.puts "Warning: missing boilerplate in #{file}"
    STDERR.puts body.split($RS).first(10).join($RS)
    exit
  end
end
