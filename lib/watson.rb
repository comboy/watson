# Watson, almost as clever as Sherlock
class Watson
  DB_FILE = "#{RAILS_ROOT}/tmp/watson.db"
    
  class << self
    # That is a separete method for loading all needed files
    # That's because they are only needed for Watson's job, there's no point
    # in loading them when your rails app is starting.  
    def include
      require 'watson/log_entry'
      require 'watson/log_parser'
      require 'watson/helpers'
      require 'watson/generator'    
      require 'sqlite3'
      require 'gruff'
    end

    ## Create sqlite db schema used for logs
    def create_db
      File.delete Watson::DB_FILE if File.exists? Watson::DB_FILE
      db = SQLite3::Database.new Watson::DB_FILE
      db.close
      LogEntry.connection.create_table :log_entries, :force => true do |t|
        t.column :controller, :string
        t.column :action, :string
        t.column :requested_at, :timestamp
        t.column :remote_ip, :string
        t.column :db_time, :float
        t.column :render_time, :float
        t.column :remote_ip, :string
        t.column :time, :float
        t.column :http_code, :integer
        t.column :url, :strin
        t.column :completed, :boolean
        t.column :exception_class, :string
        t.column :full, :text
      end        
    end

    # OK, I guess this is not the best way to get plugin directory, 
    # I'd love to hear how to do it better
    def plugin_dir
      File.split(File.split(__FILE__)[0])[0]
    end
    
    def clean_up
      File.delete Watson::DB_FILE if File.exists? Watson::DB_FILE      
    end
  end
end

