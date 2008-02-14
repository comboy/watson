
# Log entry model, you can find how model looks in Watson.create_db
class LogEntry < ActiveRecord::Base    
  establish_connection(
    :adapter  => 'sqlite3',
    :dbfile => Watson::DB_FILE)    
end