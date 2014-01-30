require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

task :default => "test"

Rake::TestTask.new do |t|
  t.test_files = Dir['test/**/*'].select { |f| f.match(/\.rb$/) }
  t.warning    = true
end

task :boilerplate do
  STDERR.puts "Fixing boilerplates"

  boilerplate = <<END
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-#{Time.now.year} Martin Asser Hansen (mail@maasha.dk).                  #
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
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
END

  files  = Dir['bin/**/*'].select  { |f| File.file? f }
  files += Dir['lib/**/*'].select  { |f| File.file? f }
  files += Dir['test/**/*'].select { |f| File.file? f }

  files.each do |file|
    body = ""

    File.open(file) do |ios|
      body = ios.read
    end

    if body.sub!("# =BOILERPLATE=" + $/, boilerplate)
      STDERR.puts "Adding boilerplate: #{file}"

      File.open(file, 'w') do |ios|
        ios.puts body
      end
    end

    if body.match(/Copyright \(C\) 2007-(\d{4}) Martin Asser Hansen/) and $1.to_i != Time.now.year
      STDERR.puts "Updating boilerplate: #{file}"

      body.sub!(/Copyright \(C\) 2007-(\d{4}) Martin Asser Hansen/, "Copyright (C) 2007-#{Time.now.year} Martin Asser Hansen")

      File.open(file, 'w') do |ios|
        ios.puts body
      end
    end

    unless body.match('Copyright')
      STDERR.puts "Warning: missing boilerplate in #{file}"
      STDERR.puts body
      exit
    end
  end

  STDERR.puts "done."
end
