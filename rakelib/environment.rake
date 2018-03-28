
require_relative 'aws_support/client_factory'
require_relative 'environment/variables_file'
require_relative 'environment/user_data_file'
require_relative 'environment/packer_copy_template'

namespace 'environment' do

  desc 'discover the resource identifiers for the account and write to the specified file'
  task :variables_file, [:role_arn, :output_filepath] do |t, args|
    role_arn = args[:role_arn]
    filename = args[:output_filepath]

    puts "assuming role=#{role_arn}, and generating variables file to #{filename}"

    Environment::VariablesFile.new().write_to(filename, role_arn)
  end

  desc 'create the rhel user data file using provided variables file'
  task :rhel_user_data_file, [:vars_filepath, :output_filepath] do |t, args|
    vars_file = args[:vars_filepath]
    out_file  = args[:output_filepath]

    puts "generating linux user data file using variables from #{vars_file} and writing to #{out_file}"

    Environment::UserDataFile.new(:rhel).generate_from_write_to(vars_file, out_file)
  end

  desc 'create the win user data file using provided variables file'
  task :win_user_data_file, [:vars_filepath, :output_filepath] do |t, args|
    vars_file = args[:vars_filepath]
    out_file  = args[:output_filepath]

    puts "generating windows user data file using variables from #{vars_file} and writing to #{out_file}"

    Environment::UserDataFile.new(:win).generate_from_write_to(vars_file, out_file)
  end

  desc 'create the packer template to copy an image'
  task :packer_copy_template, [:role_arn, :image_name, :image_id, :variables_file, :packer_template_file] do |t, args|
    role_arn = args[:role_arn]
    image_name = args[:image_name]
    image_id = args[:image_id]
    variables_file = args[:variables_file]
    packer_template_file = args[:packer_template_file]

    Environment::PackerCopyTemplate.new(:rhel).generate(role_arn, image_name, image_id, variables_file, packer_template_file)
  end

  desc 'create the packer template to copy an windows image'
  task :packer_copy_win_template, [:role_arn, :image_name, :image_id, :variables_file, :packer_template_file, :packer_folder] do |t, args|
    role_arn = args[:role_arn]
    image_name = args[:image_name]
    image_id = args[:image_id]
    variables_file = args[:variables_file]
    packer_template_file = args[:packer_template_file]
    packer_folder = args[:packer_folder]

    Environment::PackerCopyTemplate.new(:win).generate(role_arn, image_name, image_id, variables_file, packer_template_file)
  end

end
