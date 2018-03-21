# extract verions for each component on a given environement
# requires a config file to map TLA to Role
# also need a sub_domain 

require 'json'
require 'yaml'
require 'optparse'
require 'ostruct'
require 'resolv'

EXIT_INVALID_OPTIONS = 1
DEFAULT_CONFIG_FILE = "#{File.dirname(__FILE__)}/versions_from_env.yaml"
DNS_TXT = 'dns_txt' # section in DEFAULT_CONFIG_FILE
CONFIG = 'config' # section in DEFAULT_CONFIG_FILE

class VersionsFromEnv

  def initialize(options)
    config_file = options.config_file

    @map_hash = from_yaml(config_file)
    @config = cfg # now an object
    @dns_txt = dns_txt
    @versions = dig_versions.merge(static_versions)
  end

  def print
    @versions.each_pair { |k, v| puts "#{k}: #{v}"}
  end

  def to_yaml
    puts '---'
    print
  end

  private

  def dig_versions
    h = Hash.new()
    @dns_txt.each_pair do |k,v| 
      h[k] = dig(v).data
    end
    h
  end

  def dig(component)
    txt_record = "_version.#{component}.#{@config.environment}.#{@config.sub_domain}"
    records = Array.new
    Resolv::DNS.open do |dns|
      records = dns.getresources(txt_record, Resolv::DNS::Resource::IN::TXT)
      records.empty? ? nil : records.map(&:data).join(' ')
    end
    records[0]
  end

  def static_versions
    @map_hash.select { |k,_v| not_reserved?(k) }.values.reduce Hash.new, :merge
  end

  def not_reserved?(key) # 'true' if 'key' is not in array of reserved keys
    [DNS_TXT, CONFIG].select { |i| !i.match(/key/) }
  end

  def cfg
    JSON.parse(@map_hash.delete(CONFIG).to_json, object_class: OpenStruct)
  end

  def dns_txt
    @map_hash.delete(DNS_TXT)
  end

  def from_yaml(map_file)
    return YAML.load_file(map_file) if File.exist?(map_file)
    raise "No map file found"
  end
end

def validate_options(options)
  errors = Array.new
  unless options.config_file
    if File.exist?(DEFAULT_CONFIG_FILE)
      options.config_file = DEFAULT_CONFIG_FILE
    else
      errors << 'You must specify an config file: -f FILE'
    end
  end

  if errors.count > 0
    puts errors.join("\n")
    exit EXIT_INVALID_OPTIONS
  end
end

# if running as a script
if __FILE__ == $0
  options = OpenStruct.new

  OptionParser.new do |opts|
    opts.banner = 'Usage: versions_from_env.rb [options]'
    opts.on('-f', '--config-file FILE', 'A yaml file with at least key "dns_txt"') { |o| options.config_file = o }
    opts.on('-o', '--output-file FILE', 'A versions.yaml file') { |o| options.output_file = o }
    opts.on_tail('-h', '--help') {
      puts opts
      exit
    }
  end.parse!

  validate_options(options)

  obj = VersionsFromEnv.new(options)
  obj.to_yaml
end

=begin
DEFAULT_CONFIG_FILE looks like this
-------------------------------------------------------


---
config:
  sub_domain: "bgchprod.info"
  environment: "prod"
  debug: false
  version: "0.1"
base:
  branding: 1.0-b229
  rabbitmq-plugin: 1.0-b36
  infrastructure-modules: 1.0-b76
  provisioning-ec2: 1.0-b1486
fixed:
  platform-acceptance: 1.0-b205
  smoke-test-service: 1.0-b13
  rabbitmq-kafka-bridge: 1.0-b112
  feature-toggler: 1.0-b22
  email-sending-service: 1.0-b47
  sms-sending-service: 1.0-b66
  zoo: 1.0-b11679
  notification-gateway: 
dns_txt:
  api: api 
  node-snapshot-persister: nsp 
  node-registry: reg 
  system-alerts-notifier: san 
  trigger-processor: trp 
  software-upgrade-daemon: sud 
  rhc-onboarding-daemon: onb 
  sms-command-processor: smc 
  rules-service: rul 
  hub-connection-notifier: hcn 
  synthetic-device-service: sds 
  push-notification: pns 
  telemetry-collector: tlm 
  tsdb-connector: tsc 
  device-recovery: sdr 
  dispatcher: dispatcher
  activation: activation
  hub-migration-service: hms 
  ecosystem: ecosystem
  state-cache: statecache
  event-logger
=end

