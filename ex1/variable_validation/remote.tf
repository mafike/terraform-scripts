terraform {
  backend "remote" {
    organization = "mafi"

    workspaces {
      name = "variable_validation"
    }
  }
}