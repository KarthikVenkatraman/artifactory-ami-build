require 'aws-sdk'
require_relative '../aws_support/client_factory'

module Image
  class ImageManager

    def initialize(client_factory)
      @client_factory = client_factory
    end

    def encrypt_image(image_id, kms_key_id)
      ec2_client = @client_factory.ec2_client
      ec2 = Aws::EC2::Resource.new(client: ec2_client)

      source_image = ec2.image(image_id)
      puts "about to copy #{image_id}, #{source_image.name}"

      copy_result = ec2_client.copy_image({source_region: @client_factory.region,
                                           source_image_id: image_id,
                                           name: "encrypted-#{source_image.name}",
                                           encrypted: true,
                                           kms_key_id: kms_key_id})

      encrypted_image_id = copy_result.image_id

      puts "waiting for image #{encrypted_image_id} to be available"

      ec2_client.wait_until(:image_available, image_ids: [encrypted_image_id]) do |w|
        w.delay = 30
        w.max_attempts = 60
      end

      encrypted_image = ec2.image(encrypted_image_id)
      encrypted_image_snapshot_ids = snapshot_ids_for(encrypted_image)

      encrypted_tag = {key: "Encrypted", value: "true"}

      apply_tags(ec2_client, encrypted_image_snapshot_ids << encrypted_image.id, source_image.tags << encrypted_tag)

      encrypted_image.id
    end

    def tag(source_image_id, tagStrings)
      tags = []

      tagStrings.each do |tagString|
        keyValueArray = tagString.split('=')
        tags << {key: keyValueArray[0], value: keyValueArray[1]}
      end

      apply_tags(@client_factory.ec2_client, [source_image_id], tags)


    end

    def copy_tags_from_to(source_image_id, target_image_id)
      ec2 = Aws::EC2::Resource.new(client: @client_factory.ec2_client)

      source_image = ec2.image(source_image_id)
      source_tags = source_image.tags

      target_image = ec2.image(target_image_id)
      target_snapshot_ids = snapshot_ids_for(target_image)

      apply_tags(@client_factory.ec2_client, target_snapshot_ids << target_image_id, source_tags)
    end

    def delete_image(image_id)
      ec2_client = @client_factory.ec2_client
      ec2 = Aws::EC2::Resource.new(client: ec2_client)

      image = ec2.image(image_id)
      snapshot_ids = snapshot_ids_for(image)

      puts "deregistering image #{image_id}"

      ec2_client.deregister_image({image_id: image_id})

      puts "deleting snapshots #{snapshot_ids * ', '}"

      snapshot_ids.each do |snapshot_id|
        ec2_client.delete_snapshot({snapshot_id: snapshot_id})
      end
    end

    def snapshot_ids_for(image)
      image.block_device_mappings.collect { |block_device_mapping| block_device_mapping.ebs ? block_device_mapping.ebs.snapshot_id : nil} - [nil]
    end

    def apply_tags(ec2_client, resource_ids, tags)
      puts "tagging #{resource_ids * ', '}"
      ec2_client.create_tags({resources: resource_ids, tags: tags})
    end

    def share_with(image_id, account_ids)
      ec2_client = @client_factory.ec2_client
      ec2 = Aws::EC2::Resource.new(client: ec2_client)

      image = ec2.image(image_id)
      image.modify_attribute({attribute: 'launchPermission',
                              operation_type: 'add',
                              user_ids: account_ids})
    end

    private :snapshot_ids_for, :apply_tags

  end
end
