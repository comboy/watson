
# Main class doing the Watson's job. It gets data from sqlite db and 
# generate html pages
class Generator

  include WatsonHelpers
  
  # Creates watson directory inside logs
  # TODO:I guess it should be possible to change dir using some config file
  def initialize
    @watson_dir = RAILS_ROOT+'/log/watson/'
    FileUtils.mkdir_p @watson_dir
    FileUtils.mkdir_p @watson_dir+'images'    
    FileUtils.cp "#{Watson.plugin_dir}/templates/images/watson.gif", @watson_dir+'images/watson.gif'
  end
  
  # Runs ERB parser on the template, then put it into the layout and saves
  def generate(name,b,output=nil)    
    content_for_layout = parse_template name, b
    html = parse_template 'layout', Proc.new {}    
    output ||=name
    File.open("#{@watson_dir}#{output}.html",'w') { |f| f.puts html }
  end
  
  # Main function that do all html generation
  # It call every method from this class that starts with page_
  # Every method itself should care about calling generate
  def all_pages
    puts "Generating pages:"
    self.methods.each do |m|
      if m.starts_with? 'page_'
        puts "  #{m[5..-1]} ..."
        method(m).call
      end
    end
    
  end
  
  def page_main #:nodoc:
    
    hours_labels = {0 => '0', 3 => '3', 9 => '0', 12 => '12', 15 => '15', 18 => '18', 21 => '21'}
    
    oldest = LogEntry.minimum(:requested_at)
    newest = LogEntry.maximum(:requested_at)
    hours_avg = LogEntry.find_by_sql("SELECT round((strftime('%s',requested_at)/3600)%24) hour, COUNT(*) ile, AVG(time) avg_time FROM log_entries GROUP BY hour")    
    hours_avg = hours_avg.sort_by { |h| h.hour.to_i }

    # Average request per hour
    g = Gruff::Line.new 320
    g.theme_greyscale
    g.title = "Avg requests per hour" 
    g.data("hours", hours_avg.map { |h| h.ile.to_f })
    g.labels = hours_labels
    g.write(@watson_dir+'images/avg_req_hour.png')

    # Average request time per hour
    g = Gruff::Line.new 320
    g.theme_greyscale
    g.title = "Avg request time per hour" 
    g.data("hours", hours_avg.map { |h| (h.avg_time.to_f*1000).round/1000.0 })
    g.labels = hours_labels
    g.write(@watson_dir+'images/avg_reqtime_hour.png')
    
    daily_avg = LogEntry.find_by_sql("SELECT round((strftime('%s',requested_at)/(3600*24))) day, COUNT(*) num, AVG(time) avg_time FROM log_entries GROUP BY day")    
    daily_avg = daily_avg.sort_by { |h| h.day.to_i }

    # Daily avg request time
    g = Gruff::Line.new 320
    g.theme_greyscale
    g.title = "Daily avg request time per hour"     
    g.data("days", daily_avg.map { |h| (h.avg_time.to_f*1000).round/1000.0 }) if daily_avg.size > 1
    #g.labels = hours_labels
    g.write(@watson_dir+'images/avg_reqtime_days.png')

    # Daily request number
    g = Gruff::Line.new 320
    g.theme_greyscale
    g.title = "Daily requests number" 
    g.data("days", daily_avg.map { |h| h.num.to_i }) if daily_avg.size > 1
    #g.labels = hours_labels
    g.write(@watson_dir+'images/reqs_days.png')

    # And finaly let's generate the main page
    #html = parse_template 'index', Proc.new {}
    generate 'index', Proc.new {}
  end
  
  def page_bottlenecks #:nodoc:
    select = '*,count(*) AS gn, MIN(completed) as completed, AVG(time) as ga, AVG(render_time) as gr, MIN(time) as min_a, MAX(time) as max_a, AVG(db_time) as gd'    
    logs = LogEntry.find(:all, :select => select, :group => 'controller, action', :order => 'ga*gn DESC')    
    generate 'optimize', Proc.new {}
    
    # It's all static html so we need to generate page for every sort order
    sort_orders = {'ga' => 'avg', 'gn' => 'hits', 'gr' => 'render_time', 'gd' => 'db_time',
        'min_a' => 'min_time', 'max_a' => 'max_time' }    
    for k,v in sort_orders 
      logs = logs.sort_by { |x| -x.send(k).to_f }
      generate 'optimize', Proc.new {}, "optimize_#{v}"
    end
    
  end

  def page_last_errors #:nodoc:
    logs = LogEntry.find(:all, :select => '*, count(*) as hits, MAX(requested_at) as requested_at', :conditions => 'completed=0', :order => 'requested_at DESC', :limit => 30,  :group => 'controller, action,exception_class')    
    generate 'last_errors', Proc.new {}
  end
  
  def parse_template(name,b)        
    #FIXME: I don't know how to get relative file path without hardcoding /vendor/plugins/watson
    ERB.new(File.read("#{Watson.plugin_dir}/templates/#{name}.rhtml")).result b    
  end


end
