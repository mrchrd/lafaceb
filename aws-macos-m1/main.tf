provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "random_password" "ec2user" {
  length      = 16
  min_lower   = 2
  min_numeric = 2
  min_upper   = 2
  special     = false
}

locals {
  name = "lafaceb"

  azs           = slice(data.aws_availability_zones.available.names, 0, 1)
  instance_type = "mac2.metal"
  vpc_cidr      = "10.0.0.0/16"

  tags = {
    Name = local.name
  }

  user_data = <<-EOT
    #!/bin/bash
    dscl . -passwd /Users/ec2-user ${random_password.ec2user.result}
    /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -clientopts -setvnclegacy -vnclegacy yes -clientopts -setvncpw -vncpw password1 -restart -agent -privs -all
  EOT
}

data "aws_ami" "image" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "amzn-ec2-macos-.*-arm64"

  filter {
    name   = "architecture"
    values = ["arm64_mac"]
  }
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name = local.name

  create_private_key    = true
  private_key_algorithm = "ED25519"
  tags                  = local.tags
}

resource "local_file" "ssh_key" {
  filename = "${path.module}/id_ed25519"

  content         = format("%s\n", module.key_pair.private_key_openssh)
  file_permission = "0600"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name

  azs            = local.azs
  cidr           = local.vpc_cidr
  public_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  tags           = local.tags
}

module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name = local.name

  egress_rules        = ["all-all"]
  ingress_cidr_blocks = [format("%s/32", chomp(data.http.myip.response_body))]
  ingress_rules       = ["ssh-tcp"]
  tags                = local.tags
  vpc_id              = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5900
      to_port     = 5900
      protocol    = "tcp"
      description = "vnc"
      cidr_blocks = format("%s/32", chomp(data.http.myip.response_body))
    },
  ]
}

resource "aws_ec2_host" "host" {
  auto_placement    = "off"
  availability_zone = element(module.vpc.azs, 0)
  host_recovery     = "off"
  instance_type     = local.instance_type
  tags              = local.tags
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = local.name

  ami                         = data.aws_ami.image.image_id
  associate_public_ip_address = true
  host_id                     = aws_ec2_host.host.id
  instance_type               = aws_ec2_host.host.instance_type
  key_name                    = module.key_pair.key_pair_name
  subnet_id                   = element(module.vpc.public_subnets, 0)
  tenancy                     = "host"
  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true
  tags                        = local.tags
  vpc_security_group_ids      = [module.security_group.security_group_id]
}

output "ip_address" {
  value = module.ec2_instance.*.public_ip
}

output "ssh_key" {
  value     = format("%s\n", module.key_pair.private_key_openssh)
  sensitive = true
}

output "ssh_user" {
  value = "ec2-user"
}

output "vnc_password" {
  value = random_password.ec2user.result
  sensitive = true
}

output "vnc_user" {
  value = "ec2-user"
}
