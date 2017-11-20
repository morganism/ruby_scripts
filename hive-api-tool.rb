# morgan.sziraki@gmail.com
# simple API tool
# motion sensors
#  Mon 13 Nov 2017 10:21:56 GMT

require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'optparse'
require 'ostruct'

EXIT_INVALID_OPTIONS = 1
BASE_URL = 'https://api.prod.bgchprod.info/omnia'

class HiveApiTool

  def initialize(options)
    @api_token = options.api_token
    @resource = options.resource
  end

  def to_h # returns hash ie: node['attributes']['temperature']['reportedValue']
    JSON.parse(parse.response.body)
  end

  def to_obj # returns obj.method ie: node.attributes.temperature.reportedValue
    JSON.parse(parse.response.body, object_class: OpenStruct)
  end

  def to_s
    puts (JSON.pretty_generate JSON.parse(parse.response.body))
  end
  alias_method :print, :to_s # provide convenience method

  private

  def parse
    uri = URI.parse("#{BASE_URL}/#{@resource}")
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.alertme.zoo-6.5.0+json'
    request['X-Omnia-Client'] = 'swagger'
    request['X-Omnia-Access-Token'] = @api_token

    response = Net::HTTP.start(uri.hostname, uri.port, req_options(uri)) do |http|
      http.request(request)
    end
  end

  def req_options(uri)
    {
        use_ssl: uri.scheme == 'https',
        verify_mode: OpenSSL::SSL::VERIFY_NONE,
    }
  end
end

def validate_options(options)
  errors = Array.new
  unless options.api_token
    errors << 'You must specify an API token: -t API_TOKEN'
  end
  unless options.resource
    errors << 'You must specify a RESOURCE: -r RESOURCE [nodes, events, etc].'
  end

  if errors.count > 0
    puts errors.join("\n")
    exit EXIT_INVALID_OPTIONS
  end
end

# if running as a script
if __FILE__ == $0
  options = OpenStruct.new
  options.api_token = ENV['API_TOKEN'] if ENV['API_TOKEN']

  OptionParser.new do |opts|
    opts.banner = "Usage: hive-api-tool.rb [options]\n  *** Only GET method supported. ***"
    opts.on('-t', '--api-token API_TOKEN', 'the API token (or export API_TOKEN)') { |o| options.api_token = o }
    opts.on('-r', '--resource RESOURCE', 'events, nodes, nodes/{id} ') { |o| options.resource = o }
    opts.on_tail('-h', '--help') {
      puts opts
      exit
    }
  end.parse!

  validate_options(options)

  api_tool = HiveApiTool.new(options)
  api_tool.print
end

