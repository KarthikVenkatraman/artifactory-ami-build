require 'json'
require 'erb'
require 'ostruct'
require 'securerandom'
require 'fileutils'

module Environment
  class PackerCopyTemplate
    RHEL_TEMPLATE = File.dirname(__FILE__) + '/templates/copy_rhel_template.erb'
    WIN_TEMPLATE = File.dirname(__FILE__) + '/templates/copy_win_template.erb'
    @os_type

    def initialize(os_type)
      @os_type = os_type
      os_type == :rhel ? @template = File.read(RHEL_TEMPLATE) : nil
      os_type == :win ? @template = File.read(WIN_TEMPLATE) : nil
    end

    def generate(role_arn, image_name, image_id, variables_filepath, output_filepath)
      file = File.read(variables_filepath)
      env_vars = JSON.parse(file)
      add_assume_role_credentials!(role_arn, env_vars)

      copy_vars = copy_ami_vars(env_vars)
      copy_vars['ami_name'] = image_name

      copy_vars['source_ami_id'] = image_id
      File.open(output_filepath, 'w') do |f|
        f.write UserDataRenderer.render(@template, copy_vars)
      end

      @os_type == :win ? FileUtils.cp_r(Dir.glob(File.dirname(__FILE__) + '/files/win_*'), File.dirname(output_filepath) ) : nil

    end

    def add_assume_role_credentials!(role_arn, vars)
      client_factory = AwsSupport::ClientFactory.new(role_arn)

      vars['aws_access_key'] = client_factory.credentials.credentials.access_key_id
      vars['aws_secret_key'] = client_factory.credentials.credentials.secret_access_key
      vars['aws_security_token'] = client_factory.credentials.credentials.session_token
    end

    def copy_ami_vars(vars)
      copy_vars = vars.select{ |k,v| k.match /(_vpc_id|bakery_1_subnet_id|bakery_sg_id|aws)/}
      copy_vars.keys.each { |key | if key =~ /_vpc_id/ ; copy_vars['vpc_id'] = copy_vars.delete(key) end }
      copy_vars
    end

  end

  class UserDataRenderer < OpenStruct
    def self.render(t, h)
      UserDataRenderer.new(h)._render(t)
    end

    def _render(template)
      ERB.new(template).result(binding)
    end
  end
end
