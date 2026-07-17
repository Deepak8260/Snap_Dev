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

  user_data = file("${path.module}/userdata/master.sh")

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

  user_data = file("${path.module}/userdata/agent.sh")

  tags = {
    Name = var.agent_instance_name
  }
}