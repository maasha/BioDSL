module BioPieces
  # Status class
  class Status
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

    # @return [Hash] the status hash.
    # @todo remove this and rely on proper methods.
    attr_accessor :status

    # Constructor method for Status objects.
    def initialize
      @status = {}   # Status hash.
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
    def calc_time_elapsed
      @status[:time_elapsed] = @status[:time_stop] - @status[:time_start]
    end

    # Locate all status key pairs <foo>_in and <foo>_out and add a new status
    # key <foo>_delta with the numerical difference.
    def calc_delta
      in_keys = @status.keys.select { |s| s[-3..-1] == '_in' }

      in_keys.each do |in_key|
        base    = in_key[0...-3]
        out_key = "#{base}_out".to_sym

        if @status.key? out_key
          delta_key = "#{base}_delta".to_sym
          @status[delta_key] = @status[out_key] - @status[in_key]
        end
      end
    end
  end
end
