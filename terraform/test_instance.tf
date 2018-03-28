resource "aws_instance" "test_instance" {
  ami = "${var.image_id}"
  instance_type = "t2.medium"
  key_name = "${var.key_name}"
  vpc_security_group_ids = [
    "${data.terraform_remote_state.security.management_sg_id}",
    "${data.terraform_remote_state.security.bakery_sg_id}"]
  subnet_id = "${element(split(",", data.terraform_remote_state.infra.bakery_subnet_ids),0)}"
  iam_instance_profile = "ec2-std"
  user_data = <<EOF
#cloud-config
trend:
  server: ${data.terraform_remote_state.trend.trend_dsa_fqdn}
  policy_id: ${var.trend_policy_id}
environment:
  http_proxy: http://${data.terraform_remote_state.proxy-stacks.bakery_proxy_lb_fqdn}:80
  https_proxy: http://${data.terraform_remote_state.proxy-stacks.bakery_proxy_lb_fqdn}:80
  management_proxy: http://${data.terraform_remote_state.proxy-stacks.management_proxy_lb_fqdn}:80
  no_proxy: localhost,127.0.0.1,.via.novonet,.avivagroup.com,.avivaaws.com,.compute.internal,.avivacloud.com,169.254.169.254
EOF

  tags {
    "Name" = "shared-artifactory-ami-test"
    "HSN" = "ARTIFACTORY PRE AWD"
    "Costcentre_Projectcode" = "9MT63"
    "Owner" = "sanjay.sharma1@aviva.com"
  }
}

provider "aws" {
  region  = "${var.aws_region}"
  assume_role = {
    role_arn = "${var.aws_provider_role}"
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config {
    region  = "${var.aws_region}"
    bucket  = "aviva-${var.environment}-tfstate"
    key     = "management/infra.tfstate"
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"
  config {
    region  = "${var.aws_region}"
    bucket  = "aviva-${var.environment}-tfstate"
    key     = "management/security.tfstate"
  }
}

data "terraform_remote_state" "trend" {
  backend = "s3"
  config {
    region  = "${var.aws_region}"
    bucket  = "aviva-${var.environment}-tfstate"
    key     = "management/trend-stack.tfstate"
  }
}

data "terraform_remote_state" "proxy-stacks" {
  backend = "s3"
  config {
    region  = "${var.aws_region}"
    bucket  = "aviva-${var.environment}-tfstate"
    key     = "management/proxy-stacks.tfstate"
  }
}