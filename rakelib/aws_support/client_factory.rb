require 'aws-sdk'

module AwsSupport
  class ClientFactory

    attr_reader :region, :credentials

    def initialize(role_arn, region = 'eu-west-1')
      Aws.use_bundled_cert!

      @region = region
      @credentials = Aws::AssumeRoleCredentials.new(client: Aws::STS::Client.new(region: region),
                                                    role_arn: role_arn,
                                                    role_session_name: 'session-name')
    end

    def ec2_client()
      Aws::EC2::Client.new(region: @region, credentials: @credentials)
    end

    def route53_client()
      Aws::Route53::Client.new(region: @region, credentials: @credentials)
    end

    def get_account()
      @credentials.client.get_caller_identity.account
    end

    def sts_client()
      Aws::STS::Client.new(region: @region)
    end

  end
end