require 'aws-sdk'
require 'aws-sdk-v1'
require 'timeout'

options = {
    :retry_limit => 10
}
AWS.config(
    :access_key_id     => __ACCESS_KEY__,
    :secret_access_key => __SECRET_KEY__,
    :region            => 'eu-west-1'
)
Aws.config.update(
    {
        :region            => 'eu-west-1',
        :credentials       => Aws::Credentials.new(__ACCESS_KEY__,__SECRET_KEY__),
        :user_agent_suffix => 'donkey'
    }
)
@r53_v2   = Aws::Route53::Client.new(options)
@r53_v1   = AWS::Route53.new
	Timeout.timeout(2) do
		resp = @r53_v1.client.list_hosted_zones
		puts "v1 #{resp}"
	end
	Timeout.timeout(2) do
		resp = @r53_v2.list_hosted_zones
		puts "v2 #{resp}"
	end
