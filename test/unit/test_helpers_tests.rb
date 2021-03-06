require 'assert'
require 'ardb/adapter_spy'
require 'ardb/test_helpers'

module Ardb::TestHelpers

  class UnitTests < Assert::Context
    desc "Ardb test helpers"
    subject{ Ardb::TestHelpers }

    should have_imeths :drop_tables, :load_schema
    should have_imeths :create_db!, :create_db, :drop_db!, :drop_db
    should have_imeths :migrate_db!, :migrate_db, :reset_db, :reset_db!

  end

  class UsageTests < UnitTests
    setup do
      @adapter_spy_class = Ardb::AdapterSpy.new
      @orig_ardb_adapter = Ardb.adapter
      Ardb::Adapter.current = @adapter_spy = @adapter_spy_class.new
    end
    teardown do
      Ardb::Adapter.current = @orig_ardb_adapter
    end

  end

  class DropTablesTests < UsageTests
    desc "`drop_tables` method"

    should "tell the adapter to drop the tables" do
      assert_equal 0, @adapter_spy.drop_tables_called_count
      subject.drop_tables
      assert_equal 1, @adapter_spy.drop_tables_called_count
    end

  end

  class LoadSchemaTests < UsageTests
    desc "`load_schema` method"

    should "tell the adapter to load the schema" do
      assert_equal 0, @adapter_spy.load_schema_called_count
      subject.load_schema
      assert_equal 1, @adapter_spy.load_schema_called_count
    end

  end

  class CreateDbTests < UsageTests
    desc "create db method"

    should "tell the adapter to create the db only once" do
      assert_equal 0, @adapter_spy.create_db_called_count
      subject.create_db
      assert_equal 1, @adapter_spy.create_db_called_count
      subject.create_db
      assert_equal 1, @adapter_spy.create_db_called_count
    end

    should "force the adapter to create a db" do
      assert_equal 0, @adapter_spy.create_db_called_count
      subject.create_db!
      assert_equal 1, @adapter_spy.create_db_called_count
      subject.create_db!
      assert_equal 2, @adapter_spy.create_db_called_count
    end

  end

  class DropDbTests < UsageTests
    desc "drop db methods"

    should "tell the adapter to drop the db only once" do
      assert_equal 0, @adapter_spy.drop_db_called_count
      subject.drop_db
      assert_equal 1, @adapter_spy.drop_db_called_count
      subject.drop_db
      assert_equal 1, @adapter_spy.drop_db_called_count
    end

    should "force the adapter to drop a db" do
      assert_equal 0, @adapter_spy.drop_db_called_count
      subject.drop_db!
      assert_equal 1, @adapter_spy.drop_db_called_count
      subject.drop_db!
      assert_equal 2, @adapter_spy.drop_db_called_count
    end

  end

  class MigrateDbTests < UsageTests
    desc "migrate db methods"

    should "tell the adapter to migrate the db only once" do
      assert_equal 0, @adapter_spy.migrate_db_called_count
      subject.migrate_db
      assert_equal 1, @adapter_spy.migrate_db_called_count
      subject.migrate_db
      assert_equal 1, @adapter_spy.migrate_db_called_count
    end

    should "force the adapter to migrate a db" do
      assert_equal 0, @adapter_spy.migrate_db_called_count
      subject.migrate_db!
      assert_equal 1, @adapter_spy.migrate_db_called_count
      subject.migrate_db!
      assert_equal 2, @adapter_spy.migrate_db_called_count
    end

  end

  class ResetDbTests < UsageTests
    desc "reset db methods"

    should "tell the adapter to drop/create the db and load the schema only once" do
      assert_equal 0, @adapter_spy.drop_db_called_count
      assert_equal 0, @adapter_spy.create_db_called_count
      assert_equal 0, @adapter_spy.load_schema_called_count

      subject.reset_db

      assert_equal 1, @adapter_spy.drop_db_called_count
      assert_equal 1, @adapter_spy.create_db_called_count
      assert_equal 1, @adapter_spy.load_schema_called_count

      subject.reset_db

      assert_equal 1, @adapter_spy.drop_db_called_count
      assert_equal 1, @adapter_spy.create_db_called_count
      assert_equal 1, @adapter_spy.load_schema_called_count
    end

    should "force the adapter to drop/create the db and load the schema" do
      assert_equal 0, @adapter_spy.drop_db_called_count
      assert_equal 0, @adapter_spy.create_db_called_count
      assert_equal 0, @adapter_spy.load_schema_called_count

      subject.reset_db!

      assert_equal 1, @adapter_spy.drop_db_called_count
      assert_equal 1, @adapter_spy.create_db_called_count
      assert_equal 1, @adapter_spy.load_schema_called_count

      subject.reset_db!

      assert_equal 2, @adapter_spy.drop_db_called_count
      assert_equal 2, @adapter_spy.create_db_called_count
      assert_equal 2, @adapter_spy.load_schema_called_count
    end

  end

end
