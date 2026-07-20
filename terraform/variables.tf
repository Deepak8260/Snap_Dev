##############################
# AWS Configuration
##############################

variable "aws_region" {
  description = "AWS region where infrastructure will be deployed."
  type        = string
}

##############################
# Project Information
##############################

variable "project_name" {
  description = "Project name used for naming and tagging AWS resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (Development, Testing, Production)."
  type        = string
}

##############################
# EC2 Configuration
##############################

variable "instance_type" {
  description = "EC2 instance type for Jenkins Master and Agent."
  type        = string
}

variable "master_instance_name" {
  description = "Name of the Jenkins Master EC2 instance."
  type        = string
}

variable "agent_instance_name" {
  description = "Name of the Jenkins Agent EC2 instance."
  type        = string
}

##############################
# SSH Key Configuration
##############################

variable "key_name" {
  description = "AWS Key Pair name."
  type        = string
}

variable "public_key_path" {
  description = "Absolute path to the local SSH public key."
  type        = string
}

##############################
# Network Configuration
##############################

variable "my_ip" {
  description = "Your public IP address in CIDR format (Example: 49.xxx.xxx.xxx/32)."
  type        = string
}

##############################
# Jenkins Configuration
##############################

variable "jenkins_admin_username" {
  description = "Jenkins administrator username"
  type        = string
}

variable "jenkins_admin_password" {
  description = "Jenkins administrator password"
  type        = string
  sensitive   = true
}

variable "github_username" {}
variable "github_token" {}

variable "dockerhub_username" {}
variable "dockerhub_password" {}

##################################################
# Jenkins Agent Configuration
##################################################

variable "agent_name" {
  description = "Jenkins Agent Name"
  type        = string
}

variable "agent_labels" {
  description = "Labels assigned to Jenkins Agent"
  type        = string
}

variable "agent_remote_fs" {
  description = "Remote workspace directory"
  type        = string
}

variable "agent_executors" {
  description = "Number of executors on Agent"
  type        = number
}

##################################################
# Jenkins Email-Notification Configuration
##################################################

variable "smtp_server" {
  default = "smtp.gmail.com"
}

variable "smtp_port" {
  default = "465"
}

variable "smtp_username" {
  sensitive = true
}

variable "smtp_password" {
  sensitive = true
}

variable "smtp_ssl" {
  default = true
}

variable "admin_email" {
  sensitive = true
}