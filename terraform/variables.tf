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