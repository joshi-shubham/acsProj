module "globalvars" {
  source = "../../../modules/globalvars"
}

module "vpc_dev" {
  source                     = "../../../modules/network"
  vpc_cidr                   = var.vpc_cidr
  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  default_tags               = module.globalvars.default_tags
  env                        = var.env
  prefix                     = module.globalvars.prefix
  nat_gateway                = true
  internet_gateway           = true
}