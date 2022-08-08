module "sonarqube_network" {
  source                                      = "cn-terraform/networking/aws"
  name_prefix                                 = "${var.name_prefix}-networking"
  vpc_cidr_block                              = "192.168.0.0/16"
  availability_zones                          = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnets_cidrs_per_availability_zone  = ["192.168.0.0/19", "192.168.32.0/19", "192.168.64.0/19", "192.168.96.0/19"]
  private_subnets_cidrs_per_availability_zone = ["192.168.128.0/19", "192.168.160.0/19", "192.168.192.0/19", "192.168.224.0/19"]
}