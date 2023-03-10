# #### Required ####

variable "git_branch" {
  description = "The name of the git branch for deployment"
  type        = string  
}

variable "base_dir" {
  description = "The path to the base directory of the repo"
  type        = string  
}