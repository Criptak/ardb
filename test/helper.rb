# this file is automatically required when you run `assert`
# put any test helpers here

# add the root dir to the load path
$LOAD_PATH.unshift(File.expand_path("../..", __FILE__))

# require pry for debugging (`binding.pry`)
require 'pry'
require 'test/support/factory'

ENV['ARDB_DB_FILE'] = 'tmp/testdb/config/db'
require 'ardb'
Ardb.init(false)
