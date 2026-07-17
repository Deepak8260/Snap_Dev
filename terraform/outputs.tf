#############################################
# Jenkins Master Public IP
#############################################

output "jenkins_master_public_ip" {
  description = "Public IP address of the Jenkins Master"

  value = aws_instance.master.public_ip
}

#############################################
# Jenkins Master Public DNS
#############################################

output "jenkins_master_public_dns" {
  description = "Public DNS of the Jenkins Master"

  value = aws_instance.master.public_dns
}

#############################################
# Jenkins Agent Public IP
#############################################

output "jenkins_agent_public_ip" {
  description = "Public IP address of the Jenkins Agent"

  value = aws_instance.agent.public_ip
}

#############################################
# Jenkins Agent Public DNS
#############################################

output "jenkins_agent_public_dns" {
  description = "Public DNS of the Jenkins Agent"

  value = aws_instance.agent.public_dns
}

#############################################
# Jenkins URL
#############################################

output "jenkins_url" {
  description = "Jenkins Dashboard URL"

  value = "http://${aws_instance.master.public_ip}:8080"
}

#############################################
# Flask Application URL
#############################################

output "flask_application_url" {
  description = "SnapDev Application URL"

  value = "http://${aws_instance.agent.public_ip}:5000"
}