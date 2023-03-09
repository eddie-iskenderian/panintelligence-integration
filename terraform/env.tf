locals {
  common = {
    region  = "ap-southeast-2"
    suffix  = startswith(var.git_branch, "release") || var.git_branch == "develop" ? "" : lower("-${replace(var.git_branch, "/", "-")}")
    service = "delivery"
    prefix  = "data"
  }

  env = {
    teamdata = {
      name = "teamdata"
    }
    integrationdata = {
      name = "integrationdata"
    }
    proddata = {
      name = "proddata"
    }
  }

  workspace = local.env[terraform.workspace]
}
