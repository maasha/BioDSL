module BioPieces
  # Command class for initiating and calling commands.
  class Command
    attr_reader :name, :type, :status

    # Constructor for Command objects.
    #
    # @param name    [Symbol] Name of command.
    # @param type    [Symbol] Command type.
    # @param lmb     [Proc]   Lambda for command callback execution.
    # @param options [Hash]   Options hash.
    def initialize(name, type, lmb, options)
      @name    = name
      @type    = type
      @lmb     = lmb
      @options = options
      @status = Status.new
    end

    # Callback method for executing a Command lambda which returns a status
    # information which is added to the Status hash.
    #
    # @param args [Array] List of arguments used in the callback.
    def call(*args)
      @status.status.merge! @lmb.call(*args, @status)
    end

    # Terminate the status.
    def terminate
      @status.terminate
    end

    def to_s
      options_list = []

      @options.each do |key, value|
        if value.is_a? String
          value = Regexp::quote(value) if key == :delimiter
          options_list << %{#{key}: "#{value}"}
        elsif value.is_a? Symbol
          options_list << "#{key}: :#{value}"
        else
          options_list << "#{key}: #{value}"
        end
      end

      if @options.empty?
        ".#{@name}"
      else
        ".#{@name}(#{options_list.join(", ")})"
      end
    end
  end
end
