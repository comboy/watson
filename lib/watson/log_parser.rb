
# Class used for parsing log files
class LogParser
  
  class << self
    # Parse log file and put data into the temporary sqlite db
    # you can find it in tmp/watson.db
    # 
    # Right now it only supports default format of the rails production env logs.  
    # AcriveRecord was way too slow so I'm generating SQL queries manually
    def parse_file()
      
      logfile=RAILS_ROOT+'/log/production.log'
      # buffer stores lines associated with a single request
      buffer = ''
      start_time = Time.now
      count = 0
      db = SQLite3::Database.new(Watson::DB_FILE)
      go_sql = ''
      File.open(logfile,'r') do |f|
        until f.eof?
          line = f.readline
          line.strip!
          if line.starts_with? 'Processing'
            log_item = parse_entry buffer
            if log_item
              values = log_item.values.map { |v| "'#{v.to_s.gsub("'","''")}'"}
              go_sql += "INSERT INTO log_entries (#{log_item.keys.join(',')}) VALUES(#{values.join(',')});\n"
              count += 1
              if (count % 10 == 0)     
                db.execute_batch go_sql
                go_sql = ''
                if (count % 100 == 0) 
                  print "."; STDOUT.flush
                end
                puts "\n#{count} entries done (#{(count/(Time.now - start_time)).round} / sec)"  if (count % 3000 == 0)
              end
            end
            buffer = line
          else
            buffer << "#{line}\n"
          end
        end
      end  
      puts ""
    end
      
     Regexp_first_line = /Processing (.+?)#(.+?) \(for (.+?) at (.+?)\) \[(.+?)\]/
     Regexp_completed = /Completed in (.+?) \((.+?)\) \| (.+?) \| (\d+?) (.+?) \[(.+?)\]/
     Regexp_db_time = /DB\: (.+?) \((.+?)\)/
     Regexp_render_time = /Rendering\: (.+?) \((.+?)\)/
    
    # Parse log lines for a single request  
    def parse_entry(buffer)
      buffer.strip!      
      item = {}    
    
      # First line parsing
    
      match = Regexp_first_line.match buffer 
      return false unless match
      item[:controller] = match[1]
      item[:action] = match[2]
      item[:remote_ip] = match[3]
      item[:requested_at] = Time.parse match[4]
    
    
      # Last line with request times, if this line is not present it means
      # that request ended up with some error
      # Completed in 0.56642 (1 reqs/sec) | DB: 0.00000 (0%) | 302 Found [http://codingbitch.tu/main/log_out]
    
      match = Regexp_completed.match buffer
      if match
        item[:completed] = 1
        item[:time] = match[1].to_f 
        item[:http_code] = match[4]
        item[:url] = match[6]

        # This is a match for something like this: Rendering: 0.05938 (43%) | DB: 0.00000 (0%)
        times_match = match[3]      
      
        # Let's check if database time is included in log
        db_match = Regexp_db_time.match times_match
        item[:db_time] = db_match[1].to_f if db_match
      
        # Rendering time
        render_match = Regexp_render_time.match times_match
        item[:render_time] = render_match[1].to_f if render_match
      else
        item[:completed] = 0      
        # I'm not sure if it's a good way, but let's try to get exception class
        error_part = buffer.split("\n\n")[1]      
        item[:exception_class] = error_part.split[0] if error_part      
        item[:full] = buffer
        
      end
      item
    end
  end
end
