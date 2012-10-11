#!/Users/a927043/.rvm/rubies/ruby-1.9.3-p194/bin/ruby

require 'net/http'
require 'optparse'
require 'rubygems'
require 'typhoeus'
require 'json'

def validateResponse(type, response)
  if(type == "reviews") 
    return response.include? 'doGameSpot'
  elsif (type == "trailers")
    return response.include? 'sku'
  end
end

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do|opts|  
  opts.banner = "Usage: 3rdpartyvalidator.rb [options] -t [trailers|reviews] -f filename (trailers = csv of skus, reviews = csv of pids)"
  
  options[:datafile] = nil
  opts.on( '-f', '--filename FILE', 'File containing csv of product ids' ) do|file|
    options[:datafile] = file
  end
  
  options[:type] = nil
  opts.on("--type [TYPE]", [:trailers, :reviews], "Select data type (trailers, reviews)") do |t|
    options[:type] = t.to_s
  end
end

optparse.parse!

#Now raise an exception if we have not found a host option
unless options[:datafile] && options[:type]
  $stderr.puts "Usage: 3rdpartyvalidator.rb [options] -t [trailers|reviews] -f filename (trailers = csv of skus, reviews = csv of pids)"
  exit
end

urls = Hash.new;
urls["trailers"] = "http://secure.totaleclips.com/bestbuy/lookup_multiple_by_sku?callback=busopsLow.ExternalContent.doPlayTrailer&retailer_skus=%s"
urls["reviews"] = "http://www.gamespot.com/pages/partners/bestbuy/js.php?pid=%s"

runner = Typhoeus::Hydra.new(:max_concurrency => 20) # keep from killing some servers
runner.disable_memoization

pids = Array.new;
file = File.open(options[:datafile]) or die UI.messagebox("Unable to open file...") 

encoding_options = {
    :invalid           => :replace,  # Replace invalid byte sequences
    :undef             => :replace,  # Replace anything not defined in ASCII
    :replace           => '',        # Use a blank for those replacements
    :universal_newline => true       # Always break lines with \n
  }

file.each_line { |line|
  

  # This seems to be necessary to help with the exported file from MS Word.
  line = line.encode Encoding.find('ASCII'), encoding_options
  
  # remove the trailing ,
  if line[-2] == ','
    line = line[0..-2]
  end
  if(line.include? ',')
    pids.concat(line.split(','))
  else
    pids.push(line.chomp)
  end
}
file.close()

pids.each {|pid|  
  req = Typhoeus::Request.new( urls[options[:type]] % pid )
  req.on_complete do |response|
    # puts "responseBody = #{response.body}"
    isValid = validateResponse(options[:type], response.body);
    if(not (isValid)) 
      puts "#{pid}"
    end
    
  end
  runner.queue(req)
}
runner.run