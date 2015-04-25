module BioPieces
  # Module to provide a temporary directory.
  module TmpDir
    require 'tempfile'

    # Create a temporary directory in block context. The directory is deleted
    # when the TmpDir object is garbage collected or the Ruby intepreter exits.
    # If called with a list of filenames, these are provided as block arguments
    # such that the files parent are the temporary directory. However, the last
    # block argument is always the path to the temporary directory.
    #
    # @param files [Array] List of file names.
    #
    # @example
    #   BioPieces::TmpDir.create do |dir|
    #     puts dir
    #       # => "<tmp_dir>"
    #   end
    #
    # @example
    #   BioPieces::TmpDir.create("foo", "bar") do |foo, bar, dir|
    #     puts foo
    #       # => "<tmp_dir>/foo"
    #     puts bar
    #       # => "<tmp_dir>/foo"
    #     puts dir
    #       # => "<tmp_dir>"
    #   end
    def self.create(*files, &block)
      fail 'no block given' unless block

      Dir.mktmpdir do |dir|
        paths = files.each_with_object([]) { |e, a| a << File.join(dir, e) }

        if paths.empty?
          block.call(dir)
        else
          block.call(paths << dir)
        end
      end
    end
  end
end
