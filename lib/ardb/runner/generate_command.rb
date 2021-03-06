require 'fileutils'
require 'active_support/core_ext/string'
require 'ardb/runner'

class Ardb::Runner::GenerateCommand

  def initialize(args)
    @item = args.shift
    @args = args
  end

  def run
    if @item.nil?
      raise Ardb::Runner::CmdError, "specify an item to generate"
    end
    if !self.respond_to?("#{@item}_cmd")
      raise Ardb::Runner::CmdError, "can't generate #{@item}"
    end

    begin
      self.send("#{@item}_cmd")
    rescue Ardb::Runner::CmdError => e
      raise e
    rescue Exception => e
      $stderr.puts e
      $stderr.puts "error generating #{@item}."
      raise Ardb::Runner::CmdFail
    end
  end

  def migration_cmd
    MigrationCommand.new(@args.first).run
  end

  class MigrationCommand
    attr_reader :identifier, :class_name, :file_name, :template

    def initialize(identifier)
      if identifier.nil?
        raise Ardb::Runner::CmdError, "specify a name for the migration"
      end

      @identifier = identifier
      @class_name = @identifier.classify.pluralize
      @file_name  = begin
        "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{@identifier.underscore}"
      end
      @template = "require 'ardb/migration_helpers'\n\n"\
                  "class #{@class_name} < ActiveRecord::Migration\n"\
                  "  include Ardb::MigrationHelpers\n\n"\
                  "  def change\n"\
                  "  end\n\n"\
                  "end\n"
    end

    def run
      FileUtils.mkdir_p Ardb.config.migrations_path
      file_path = File.join(Ardb.config.migrations_path, "#{@file_name}.rb")
      File.open(file_path, "w"){ |f| f.write(@template) }
      $stdout.puts file_path
    end
  end

end
