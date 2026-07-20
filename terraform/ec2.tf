#############################################
# Jenkins Master EC2
#############################################

resource "aws_instance" "master" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name

  vpc_security_group_ids = [
    aws_security_group.master_sg.id
  ]

  associate_public_ip_address = true

  user_data = templatefile(
    "${path.module}/userdata/master.sh.tpl",
    {

      # ----------------------------------
      # Jenkins Admin
      # ----------------------------------

      jenkins_admin_username = var.jenkins_admin_username
      jenkins_admin_password = var.jenkins_admin_password

      # ----------------------------------
      # GitHub Credentials
      # ----------------------------------

      github_username = var.github_username
      github_token    = var.github_token

      # ----------------------------------
      # Docker Hub Credentials
      # ----------------------------------

      dockerhub_username = var.dockerhub_username
      dockerhub_password = var.dockerhub_password

      # ----------------------------------
      # SSH Credential for Jenkins Agent
      # ----------------------------------

      agent_ssh_private_key = tls_private_key.jenkins_agent.private_key_openssh

      # ----------------------------------
      # Agent Configuration
      # ----------------------------------

      agent_name       = var.agent_name
      agent_labels     = var.agent_labels
      agent_remote_fs  = var.agent_remote_fs
      agent_executors  = var.agent_executors

      # ----------------------------------
      # SMTP Configuration
      # ----------------------------------
      smtp_server   = var.smtp_server
      smtp_port     = var.smtp_port
      smtp_ssl      = var.smtp_ssl
      smtp_username = var.smtp_username
      smtp_password = var.smtp_password
      admin_email   = var.admin_email

      # Terraform gets this automatically
      agent_private_ip = aws_instance.agent.private_ip
    }
  )

  user_data_replace_on_change = true

  tags = {
    Name = var.master_instance_name
  }
}

#############################################
# Jenkins Agent EC2
#############################################

resource "aws_instance" "agent" {

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name

  vpc_security_group_ids = [
    aws_security_group.agent_sg.id
  ]

  associate_public_ip_address = true

  user_data = templatefile(
    "${path.module}/userdata/agent.sh.tpl",
    {

      controller_public_key = tls_private_key.jenkins_agent.public_key_openssh

    }
  )

  user_data_replace_on_change = true

  tags = {
    Name = var.agent_instance_name
  }
}