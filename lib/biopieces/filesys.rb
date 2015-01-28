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

module BioPieces
  # Error class for all exceptions to do with Filesys.
  class FilesysError < StandardError; end

  class Filesys
    require 'open3'

    include Enumerable

    # Class method that returns a path to a unique temporary file.
    # If no directory is specified reverts to the systems tmp directory.
    def self.tmpfile(tmp_dir = ENV["TMPDIR"])
      time = Time.now.to_i
      user = ENV["USER"]
      pid  = $$
      path = tmp_dir + [user, time + pid, pid].join("_") + ".tmp"
      path
    end

    def self.open(*args)
      file    = args.shift
      mode    = args.shift
      options = args.shift || {}

      if mode == 'w'
        case options[:compress]
        when :gzip
          ios, = Open3.pipeline_w("gzip -f", out: file)
        when :bzip, :bzip2
          ios, = Open3.pipeline_w("bzip2 -c", out: file)
        else 
          ios = File.open(file, mode, options)
        end
      else
        type = (file.respond_to? :path) ? `file -Lk #{file.path}` : `file -Lk #{file}`
        case type
        when /gzip/
          ios = IO.popen("gzip -cd #{file}")
        when /bzip/
          ios = IO.popen("bzcat #{file}")
        else
          ios = File.open(file, mode, options)
        end
      end

      if block_given?
        begin
          yield self.new(ios)
        ensure
          ios.close
        end
      else
        return self.new(ios)
      end
    end

    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def self.which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']

      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        }
      end

      nil
    end

    def initialize(ios)
      @io = ios
    end

    def puts(*args)
      @io.puts(*args)
    end

    def read
      @io.read
    end

    def write(arg)
      @io.write arg
    end

    def close
      @io.close
    end

    def eof?
      @io.eof?
    end

    # Iterator method for parsing entries.
    def each
      return to_enum :each unless block_given?

      while entry = get_entry do
        yield entry
      end
    end

    def get_entry
      @io.gets
    end
  end
end

