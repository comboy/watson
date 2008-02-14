namespace :watson do
  desc 'Setup sqlite database for Watson'
  task :setup => :environment do           
    print "Creating sqlite database in tmp/watson.db ... "; STDOUT.flush
    Watson.include
    Watson.create_db
    puts "DONE"
  end
  desc 'Parse production.log and put data into my db'
  task :prepare => :environment do
    puts "Parsing your production log (coffee time!) ..."
    Watson.include
    LogParser.parse_file
  end
  desc 'Generate raports'
  task :generate => :environment do
    puts "Generating log reports ..."
    Watson.include
    generate = Generator.new
    generate.all_pages
  end  
  desc 'Remove temporary database'
  task :clear => :environment do
    puts "Cleaning... I love it..."
    Watson.clean_up
  end
  desc 'Does everything that is needed to get reports'
  task :go => :environment do 
    Watson.include
    puts "Creating database ..."
    Watson.create_db
    puts "Paring logs ..."
    LogParser.parse_file
    puts "Generating reports ..."
    generate = Generator.new
    generate.all_pages
    puts "Cleaning up .."
    Watson.clean_up
    puts "Check log/watson/index.html for reports :-)"
  end
  
 end