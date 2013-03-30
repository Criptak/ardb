require 'ardb'

module Ardb; end
class Ardb::Runner
  UnknownCmdError = Class.new(ArgumentError)

  attr_reader :cmd_name, :cmd_args, :opts, :root_path

  def initialize(args, opts)
    @opts = opts
    @cmd_name = args.shift || ""
    @cmd_args = args
    @root_path = @opts.delete('root_path') || Dir.pwd
  end

  def run
    Ardb.config.root_path = @root_path
    # TODO: require in a standard file, like config/db.rb??? (for initialization purposes)
    case @cmd_name
    when 'migrate'
      require 'ardb/runner/migrate_command'
      MigrateCommand.new.run
    when 'create'
      require 'ardb/runner/create_command'
      CreateCommand.new.run
    when 'drop'
      require 'ardb/runner/drop_command'
      DropCommand.new.run
    when 'null'
      NullCommand.new.run
    else
      raise UnknownCmdError, "Unknown command `#{@cmd_name}`"
    end
  end

  class NullCommand
    def run
      # if this was a real command it would do something here
    end
  end

end
