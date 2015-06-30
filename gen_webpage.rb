require 'elasticsearch/transport'
require 'erb'

es = Elasticsearch::Client.new
response = es.perform_request('GET', "/logstash/plugins/_search", {}, { from: 0, size: 200})

@data = response.body["hits"]["hits"]

#puts @data.inspect

puts ERB.new(IO.read("template.erb")).result(binding)

