variable "aws_region"         { default = "eu-west-1" }
variable "aws_provider_role"  { }

variable "environment"        { default = "nonprod" }
variable "trend_policy_id"    { default = 21 }
variable "image_id"           { }
variable "key_name"           { default = "jenkins-testing" }
output "hostname"             { value = "${aws_instance.test_instance.private_dns}" }