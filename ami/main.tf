module "clean_old_ami" {
  source  = "./module/cleanup"
  prefix  = "Dev organization"
}
