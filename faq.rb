# 1) Make sure pandoc is installed in your system http://johnmacfarlane.net/pandoc
# 2) Make sure the JSON gem is installed in your system `gem install json_pure`
# 3) Make sure you have a config.yml file setup alongside this script. See config.yml.example for an example
require 'rubygems'
require 'net/http'
require 'json/pure'
require 'yaml'

config = YAML::load( File.open('config.yml') )

faq = {}

print 'Retrieving faqs...'
Net::HTTP.start(config['host']) { |http|
  response = http.get("/projects/#{config['project_id']}/issues.json?&limit=100&status_id=closed&key=#{config['api_key']}")
  json = JSON.parse(response.body)
  faq = json['issues']
  puts "retrieved #{faq.count}/#{json['total_count']}"
  
  target = "output/response.txt"
  print "Writing server response to #{target}..."
  open(target, "wb"){ |file| file.write(response.body) }
  puts "done!"
}

categories = faq.map{|q| q['category']}.uniq

target = "output/faq.md"
print "Writing Markdown format to #{target}..."
open(target, "wb") do |file|
  header = "mCloud Frequently Asked Questions"
  file.write "#{header}\n"
  file.write "=" * header.length
  file.write "\n_Date generated: #{Time.now.inspect}_"
  file.write "\n"
  categories.each do |category|
    file.write "\n## #{category['name']} ##\n"
    filtered_faq = faq.select{ |q| q['category']['id']==category['id'] }
    filtered_faq.each do |q|
      file.write "\n### #{q['subject']} ###\n"
      file.write "#{q['description']} "
      file.write "(ID: #{q['id']})\n"
    end
  end
end
puts "done!"

# `pandoc -s output/faq.md -o output/faq.rtf`