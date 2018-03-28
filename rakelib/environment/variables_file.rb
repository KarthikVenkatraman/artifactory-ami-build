require 'aws-sdk'

require_relative '../aws_support/client_factory'
require_relative 'specific_variables'

module Environment
  class VariablesFile

    def write_to(filename, role_arn, region = 'eu-west-1')
      client_factory = AwsSupport::ClientFactory.new(role_arn, region)
      vars = Hash.new

      add_ec2_variables(vars, client_factory)
      add_route53_variables(vars, client_factory)
      add_environment_specific_variables(vars, client_factory)

      write_file(filename, vars)
    end

    def add_ec2_variables(vars, client_factory)
      client = client_factory.ec2_client()
      ec2 = Aws::EC2::Resource.new(client: client)
      ec2.vpcs.each do |vpc|
        unless vpc.is_default
          vpc_key = key_from(name_tag(vpc), '_vpc_id')
          vars[vpc_key] = vpc.id

          vpc.subnets.each do |subnet|
            subnet_key = key_from(name_tag(subnet), '_subnet_id')
            vars[subnet_key] = subnet.id
          end

          vpc.security_groups.each do |security_group|
            security_group_key = key_from(security_group.group_name, '_sg_id')
            vars[security_group_key] = security_group.id
          end
        end
      end

      vars['win_2012r2_64_ami_id'] = retrieve_win_2012r2_ami_id(ec2)
      vars['cis_rhel7_ami_id'] = retrieve_cis_rhel_7_ami_id(ec2)

      available_images_by_name = ec2.images({filters: [{name: 'tag:Lifecycle', values: ['available']}], })
                                     .group_by { |image| image.tags.find { |tag| tag.key == 'Name' } }

      available_images_by_name.keys.each do |key|
        if key
          name = key.value
          latest_image = available_images_by_name[key].sort { |a, b| b.creation_date <=> a.creation_date }.first

          image_id_key = key_from(name, '_ami_id')

          vars[image_id_key] = latest_image.image_id
        end
      end
    end

    def name_tag(item)
      item.tags.find { |tag| tag.key == 'Name' }.value
    end

    def key_from(name, suffix)
      name.downcase.gsub(/-| /, '_') << suffix
    end

    def retrieve_win_2012r2_ami_id(ec2)
      ec2.images({owners: ['amazon'],
                  filters: [{name: 'name', values: ['Windows_Server-2012-R2_RTM-English-64Bit-Base-*']}]})
          .sort { |a, b| b.creation_date <=> a.creation_date }
          .first
          .image_id
    end

    def retrieve_cis_rhel_7_ami_id(ec2)
      ec2.images({owners: ['679593333241'],
                  filters: [{name: 'name', values: ['CIS Red Hat Enterprise Linux 7 Benchmark v2.1*']}]})
          .sort { |a, b| b.creation_date <=> a.creation_date }
          .first
          .image_id
    end

    def add_route53_variables(vars, client_factory)
      route53_client = client_factory.route53_client()
      route53_client.list_hosted_zones.hosted_zones.each do |hosted_zone|
        route53_client.list_resource_record_sets(hosted_zone_id: hosted_zone.id).resource_record_sets.select { |rrs| rrs.type = 'A' }.each do |resource_record_set|
          dns_name = resource_record_set.name[0...-1] # remove trailing dot

          dns_name_key = key_from(dns_name.split(/[.\s]/).first, '_dns_name')

          vars[dns_name_key] = dns_name
        end
      end
    end

    def add_environment_specific_variables(vars, client_factory)
      vars.merge!(Environment::SpecificVariables.for(client_factory.get_account()))
    end

    def write_file(filename, vars)
      File.open(filename, 'w') do |f|
        f.write vars.to_json
      end
    end

    private :name_tag, :key_from, :retrieve_win_2012r2_ami_id, :add_ec2_variables, :add_route53_variables, :write_file

  end
end