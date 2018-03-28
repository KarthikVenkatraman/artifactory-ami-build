
require_relative 'aws_support/client_factory'
require_relative 'image/image_manager'

namespace 'image' do

  desc 'copy an image and apply encryption'
  task :encrypt, [:role_arn, :image_id, :kms_key_id] do |t, args|
    role_arn = args[:role_arn]
    image_id = args[:image_id]
    kms_key_id = args[:kms_key_id]

    puts "assuming role=#{role_arn}, and encrypting image=#{image_id}, using key=#{kms_key_id}"

    client_factory = AwsSupport::ClientFactory.new(role_arn)
    encrypted_image_id = Image::ImageManager.new(client_factory).encrypt_image(image_id, kms_key_id)

    puts "encrypted image created, id=#{encrypted_image_id}"
  end

  desc 'deletes an image and all associated snapshots'
  task :delete, [:role_arn, :image_id] do |t, args|
    role_arn = args[:role_arn]
    image_id = args[:image_id]

    puts "assuming role=#{role_arn}, and deleting image=#{image_id}"

    client_factory = AwsSupport::ClientFactory.new(role_arn)
    Image::ImageManager.new(client_factory).delete_image(image_id)

    puts "image deleted"
  end

  desc ''
  task :tag, [:role_arn, :image_id] do |t, args|
    role_arn = args[:role_arn]
    image_id = args[:image_id]
    tags = args.extras

    puts "assuming role=#{role_arn}, and tagging image=#{image_id} with tags: #{tags * ', '}"

    client_factory = AwsSupport::ClientFactory.new(role_arn)
    Image::ImageManager.new(client_factory).tag(image_id, tags)

    puts "tagging complete"
  end

  desc 'copy tags from a source image to a target image and all associated snapshots'
  task :copy_tags, [:role_arn, :source_image_id, :target_image_id] do |t,args|
    role_arn = args[:role_arn]
    source_image_id = args[:source_image_id]
    target_image_id = args[:target_image_id]

    puts "assuming role=#{role_arn}, and copying tags from image=#{source_image_id} to image=#{target_image_id}"

    client_factory = AwsSupport::ClientFactory.new(role_arn)
    Image::ImageManager.new(client_factory).copy_tags_from_to(source_image_id, target_image_id)

    puts "tagging complete"
  end

  desc 'share an ami with the accounts specified as extra args'
  task :share, [:role_arn, :image_id] do |t,args|
    role_arn = args[:role_arn]
    image_id = args[:image_id]
    account_numbers = args.extras

    puts "assuming role=#{role_arn}, and sharing image=#{image_id} with accounts=#{account_numbers * ', '}"

    client_factory = AwsSupport::ClientFactory.new(role_arn)
    Image::ImageManager.new(client_factory).share_with(image_id, account_numbers)

    puts 'sharing complete'
  end

end
