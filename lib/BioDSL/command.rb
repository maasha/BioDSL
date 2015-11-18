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
module BioDSL
  # Command class for initiating and calling commands.
  class Command
    attr_reader :name, :status, :options
    attr_accessor :run_status

    # Constructor for Command objects.
    #
    # @param name    [Symbol] Name of command.
    # @param lmb     [Proc]   Lambda for command callback execution.
    # @param options [Hash]   Options hash.
    def initialize(name, lmb, options)
      @name       = name
      @lmb        = lmb
      @run_status = 'running'
      @options    = options
      @status     = {}
    end

    # Callback method for executing a Command lambda.
    #
    # @param args [Array] List of arguments used in the callback.
    def call(*args)
      @lmb.call(*args, @status)

      @run_status         = 'done'
      @status[:time_stop] = Time.now
      calc_time_elapsed
      calc_delta
    end

    # Return string representation of a Command object.
    #
    # @return [String] With formated command.
    def to_s
      options_list = []

      @options.each do |key, value|
        options_list << case value.class.to_s
                        when 'String'
                          value = Regexp.quote(value) if key == :delimiter
                          %(#{key}: "#{value}")
                        when 'Symbol'
                          "#{key}: :#{value}"
                        else
                          "#{key}: #{value}"
                        end
      end

      @options.empty? ? @name : "#{@name}(#{options_list.join(', ')})"
    end

    # Add a key with time_elapsed to the status.
    #
    # @return [BioDSL::Status] returns self.
    def calc_time_elapsed
      delta = @status[:time_stop] - @status[:time_start]
      @status[:time_elapsed] = (Time.mktime(0) + delta).strftime('%H:%M:%S')

      self
    end

    # Locate all status key pairs <foo>_in and <foo>_out and add a new status
    # key <foo>_delta with the numerical difference.
    #
    # @return [BioDSL::Status] returns self.
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

    private

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

      (100 * d.to_f / [@status[out_key], @status[in_key]].max).round(2)
    end
  end
end
