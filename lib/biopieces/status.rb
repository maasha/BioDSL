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
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Status class
  class Status
    require 'yaml'

    # Track the status of a running command in a seperate thread and output
    # the status at speficied intervals.
    #
    # @param commands [Array] List of commands whos status should be output.
    # @param block    [Proc]  Track the command in the given block.
    #
    # @raise [RunTimeError] If no block is given.
    def self.track(commands, &block)
      fail 'No block given' unless block

      thread = Thread.new do
        loop do
          commands.map(&:status) # FIXME

          sleep 0.5 # FIXME
        end
      end

      block.call

      thread.terminate
    end

    attr_accessor :name, :options, :status   # FIXME: remove name and options

    # Constructor method for Status objects.
    #
    # @param name    [Symbol] Command name.
    # @param options [Hash]   Options hash.
    def initialize(name, options)
      @status  = {}   # Status hash.
    end

    # Return string representation of Status object in YAML.
    #
    # @return [String] YAML hash.
    def to_s
      {command: @name,
       options: @options,
       status:  @status
      }.to_yaml
    end

    # Index getter method returning the value from the symbol hash of a given
    # key.
    #
    # @param key [Symbol] The key for the symbol hash.
    #
    # @return value or nil.
    def [](key)
      @status[key]
    end

    # Index setter method allowing a value to be set for a given key of the
    # status.
    #
    # @param key [Symbol] The key for the symbol hash.
    # @param value which can be anything.
    def []=(key, value)
      @status[key] = value
    end

    # Add a time stamp to the status when a Command finishes.
    def terminate
      @status[:time_stop] = Time.now
    end

    # Add a key with time_elapsed to the status.
    #
    # @return [BioPieces::Status] returns self.
    def calc_time_elapsed
      @status[:time_elapsed] = @status[:time_stop] - @status[:time_start]

      self
    rescue
      pp @status
      exit
    end

    # Locate all status key pairs <foo>_in and <foo>_out and add a new status
    # key <foo>_delta with the numerical difference.
    #
    # @return [BioPieces::Status] returns self.
    def calc_delta
      @status.keys.select { |s| s[-3..-1] == '_in' }.each do |in_key|
        base    = in_key[0...-3]
        out_key = "#{base}_out".to_sym

        next unless @status.key? out_key

        @status["#{base}_delta".to_sym]         = delta(in_key, out_key)
        @status["#{base}_delta_percent".to_sym] = delta_percent(in_key, out_key)
      end

      self
    end

    # Calculate the difference between status values given two status keys.
    #
    # @param in_key  [Symbol] Status hash key.
    # @param out_key [Symbol] Status hash key.
    #
    # @return [Fixnum] Difference.
    def delta(in_key, out_key)
      @status[out_key] - @status[in_key]
    end

    # Calculate the percent difference between status values given two status
    # keys.
    #
    # @param in_key  [Symbol] Status hash key.
    # @param out_key [Symbol] Status hash key.
    #
    # @return [Float] Percentage rounded to 2 decimals.
    def delta_percent(in_key, out_key)
      d = @status[out_key] - @status[in_key]

      return 0.0 if d == 0

      (100 * d.to_f / [@status[out_key] - @status[in_key]].max).round(2)
    end
  end
end
