# morgan.sziraki@gmail.com
# simple API response parser to extract temperature from 
# motion sensors
#  Mon 13 Nov 2017 10:21:56 GMT

require 'json'
require 'net/http'
require 'uri'
require 'openssl'

BASE_URL = 'https://api.prod.bgchprod.info/omnia'

def process(node)
    unless node['attributes']['temperature'].nil?
        device = node['name']
        device = 'Thermostat' if node['name'].eql?('Receiver')
        puts "#{device} = #{ node['attributes']['temperature']['reportedValue']}"
    end
end

def parse
    uri = URI.parse("#{BASE_URL}/nodes")
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.alertme.zoo-6.0.0+json'
    request['X-Omnia-Client'] = 'swagger'
    request['X-Omnia-Access-Token'] = ENV['MY_API_TOKEN']

    req_options = {
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
end

nodes_hash = JSON.parse(parse.response.body)
nodes_hash['nodes'].each { |x| process(x) }

