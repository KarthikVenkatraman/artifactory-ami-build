# Packer Rakelib

This repository contains tasks to support AMI building in the Bakery.

## Installation
Install into your Packer AMI build project using the following command

`git submodule add https://stash.aviva.co.uk/scm/cloud/packer-rakelib.git rakelib`

Ensure you have a Rakefile in the root directory of the project.

If this is the first time you are using this rake library, run `bundle install` to install required gems.

## Usage

The following summarises the available tasks

### Create Variables File

Create a JSON formatted file containing variables that can simplify Packer configuration.

`rake environment:variables_file[role_arn,output_filepath]`

* role_arn: the role to assume when making aws api calls.
* output_filepath: the path and filename to create relative to the working directory

### Create User Data File

Create a YAML formatted user data file suitable for passing to a linux or windows instance in the Bakery at launch.

`rake environment:rhel_user_data_file[vars_filepath,output_filepath]`
`rake environment:win_user_data_file[vars_filepath,output_filepath]`

* output_filepath: the path and filename to create relative to the working directory
* vars_filepath: the path and filename to the variables file created using the task above. (Required for variable
substitution.)

### Create a Packer Copy Image Template File

Create a Packer Template file for a provisioner-less, simple copy (par)bake.

`rake environment:create_packer_copy_template[image_name,image_id,variables_file,packer_template_file]`

* image_name: to set the image name in the Packer template.
* image_id: the image to copy.
* variables_file: the path and filename, relative to the working directory, containing the environment specific variables to use.
* packer_template_file: the path and filename for the Packer template to create relative to the working directory.

### Git Tag

Add or update a tag in git.

`rake git:tag[tag]`

* tag the tag to apply or update

### Delete Image

Delete an image and all snapshots

`rake image:delete[role_arn,image_id]`

* role_arn: the role to assume when making aws api calls.
* image_id: the image to delete

### Encrypt Image

Encrypt an image and all snapshots through copying.

`rake image:encrypt[role_arn,image_id,kms_key_id]`

* role_arn: the role to assume when making aws api calls.
* image_id: the image to copy and encrypt
* kms_key_id: the key to use to encrypt (optional)

### Add Tags

Add tags to an image

`rake image:tag[role_arn,image_id,tag_values]`

* role_arn: the role to assume when making aws api calls.
* image_id: the image to tag
* tag_values: the tags to add in the form key=value passed as optional args so can accept repeating tag values.

### Copy Tags

Copy tags from a source image to a target image including all it's snapshots.

`rake image:copy_tags[role_arn,source_image_id,target_image_id]`

* role_arn: the role to assume when making aws api calls.
* source_image_id: the image to copy tags from
* target_image_id: the image to copy tags to

### Share Image

`rake image:share[role_arn,image_id,account_numbers]`

* role_arn: the role to assume when making aws api calls.
* image_id: the image to share
* account_numbers: the account number to share the image with passed as optional args so can accept multiple account
numbers.

`rake image:share[role_arn,image_id,account_numbers]`

* role_arn:
* image_id:
* account_numbers:

### Run Tests

Run all the RSpec tests or run CIS-CAT against a Windows instance

For ServerSpec test ensure you have a running instance and have set the environment variable `TARGET_HOST` to be set
to the fqdn of the instance to run the tests against before running.

`rake test:all`

For CIS-CAT ensure you have installed a JRE on your instance and that the CIS-CAT archive
has been extracted prior to running the task. It is suggested you do this via the instance's
UserData script. You must also ensure WinRM is enabled and a local user has been created and
added to the Administrators group.

`rake test:win_cis_cat[hostname,username,password,benchmark,profile,options]`

* hostname: the fqdn of the server to run the test on
* username: local user id to authenticate the WinRM connection
* password: password for the local user id
* benchmark: CIS-CAT benchmark XML file
* profile: name of a profile within the benchmark file
* options: other options to pass to CIS-CAT when run
