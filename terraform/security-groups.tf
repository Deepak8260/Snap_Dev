#############################################
# Jenkins Master Security Group
#############################################

resource "aws_security_group" "master_sg" {
  name        = "${var.project_name}-master-sg"
  description = "Security Group for Jenkins Master"
  vpc_id      = data.aws_vpc.default.id

  #################################
  # SSH
  #################################

  ingress {
    description = "SSH from My Laptop"

    from_port = 22
    to_port   = 22

    protocol = "tcp"

    cidr_blocks = [
      var.my_ip
    ]
  }

  #################################
  # Jenkins
  #################################

  ingress {
    description = "Jenkins UI"

    from_port = 8080
    to_port   = 8080

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  #################################
  # HTTP
  #################################

  ingress {
    description = "HTTP"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  #################################
  # Outbound
  #################################

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.project_name}-Master-SG"
  }
}

###################################################
# Jenkins Agent Security Group
###################################################

resource "aws_security_group" "agent_sg" {

  name = "${var.project_name}-agent-sg"

  description = "Security Group for Jenkins Agent"

  vpc_id = data.aws_vpc.default.id

  #################################
  # SSH ONLY FROM MASTER SG
  #################################

  ingress {

    description = "SSH From Jenkins Master"

    from_port = 22
    to_port   = 22

    protocol = "tcp"

    security_groups = [
      aws_security_group.master_sg.id
    ]
  }

  #################################
  # Flask Application
  #################################

  ingress {

    description = "Flask Application"

    from_port = 5000
    to_port   = 5000

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  #################################
  # Outbound
  #################################

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.project_name}-Agent-SG"
  }
}