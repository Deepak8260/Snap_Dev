# Infrastructure as Code (IaC) with Terraform

This module documents the Terraform automation suite used to provision AWS cloud infrastructure, security groups, SSH key pairs, and UserData startup bootstrapping scripts for **SnapDev**.

---

## Technical File Audit

| File / Template Path | Targeted Infrastructure Resource | Key Parameters & Responsibilities |
| --- | --- | --- |
| [`provider.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/provider.tf) | AWS Provider Configuration | Configures AWS provider bound to region variable `var.aws_region`. |
| [`versions.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/versions.tf) | Terraform Core Version Rules | Requires `terraform >= 1.0.0` and `hashicorp/aws ~> 5.0`. |
| [`data.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/data.tf) | AMI Lookup Data Source | Dynamically retrieves latest Ubuntu 22.04 LTS Jammy HVM SSD AMI ID from Canonical (`099720109477`). |
| [`tls.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/tls.tf) | RSA Key Generator | Generates 4096-bit RSA SSH private key (`tls_private_key.jenkins_agent`). |
| [`keypair.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/keypair.tf) | AWS Key Pair | Registers generated public key into AWS EC2 Key Pairs (`aws_key_pair.terraform_key`). |
| [`security-groups.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/security-groups.tf) | AWS Security Groups | Defines `master_sg` (Ports 22, 8080) and `agent_sg` (Ports 22, 5000, 8081, 9090, 9100, 3000, 30080). |
| [`ec2.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/ec2.tf) | AWS EC2 Instances | Provisions `aws_instance.master` and `aws_instance.agent`, injecting rendered UserData templates. |
| [`variables.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/variables.tf) | Variable Definitions | Declares input variable schemas, defaults, and descriptions. |
| [`outputs.tf`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/outputs.tf) | Output References | Outputs Master/Agent Public IPs, SSH connection strings, and Jenkins Web UI URL. |
| [`userdata/master.sh.tpl`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/userdata/master.sh.tpl) | Master Bootstrap Template | Shell template installing Docker, Java 17, Jenkins LTS, writing JCasC & Groovy files, and starting Jenkins. |
| [`userdata/agent.sh.tpl`](file:///d:/Personal_Files/VS_Code_Check/Devops_Practice/Snap_Dev/terraform/userdata/agent.sh.tpl) | Agent Bootstrap Template | Shell template installing Docker, Java 17, and injecting controller public key into `authorized_keys`. |

---

## Deep Dive: Terraform Resource Code

### 1. Dynamic RSA Key Generation & AWS Registration (`tls.tf` & `keypair.tf`)

Terraform dynamically generates a 4096-bit RSA SSH key pair at runtime, eliminating the need to hardcode PEM files:

```hcl
# tls.tf
resource "tls_private_key" "jenkins_agent" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# keypair.tf
resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.jenkins_agent.public_key_openssh
}
```

---

### 2. Network Security Group Rules (`security-groups.tf`)

#### Master Security Group (`master_sg`):
- Ingress Port `22` (TCP): SSH Access.
- Ingress Port `8080` (TCP): Jenkins Web UI and GitHub Webhook endpoint.

#### Agent Security Group (`agent_sg`):
- Ingress Port `22` (TCP): Jenkins Master SSH Agent connection.
- Ingress Port `5000` (TCP): Flask Web Application.
- Ingress Port `8081` (TCP): cAdvisor Container Metrics UI.
- Ingress Port `9090` (TCP): Prometheus TSDB Console.
- Ingress Port `9100` (TCP): Node Exporter OS Metrics.
- Ingress Port `3000` (TCP): Grafana Visualization UI.
- Ingress Port `30080` (TCP): Kubernetes NodePort Ingress.

---

### 3. EC2 Instance Provisioning (`ec2.tf`)

`ec2.tf` provisions `aws_instance.master` and `aws_instance.agent`, passing rendered template arguments to UserData:

```hcl
resource "aws_instance" "master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids      = [aws_security_group.master_sg.id]
  associate_public_ip_address = true

  user_data = templatefile(
    "${path.module}/userdata/master.sh.tpl",
    {
      jenkins_admin_username = var.jenkins_admin_username
      jenkins_admin_password = var.jenkins_admin_password
      github_username        = var.github_username
      github_token           = var.github_token
      dockerhub_username     = var.dockerhub_username
      dockerhub_password     = var.dockerhub_password
      agent_ssh_private_key  = tls_private_key.jenkins_agent.private_key_openssh
      agent_name             = var.agent_name
      agent_labels           = var.agent_labels
      agent_remote_fs        = var.agent_remote_fs
      agent_executors        = var.agent_executors
      smtp_server            = var.smtp_server
      smtp_port              = var.smtp_port
      smtp_ssl               = var.smtp_ssl
      smtp_username          = var.smtp_username
      smtp_password          = var.smtp_password
      admin_email            = var.admin_email
      agent_private_ip       = aws_instance.agent.private_ip
    }
  )

  tags = { Name = var.master_instance_name }
}

resource "aws_instance" "agent" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids      = [aws_security_group.agent_sg.id]
  associate_public_ip_address = true

  user_data = templatefile(
    "${path.module}/userdata/agent.sh.tpl",
    {
      controller_public_key = tls_private_key.jenkins_agent.public_key_openssh
    }
  )

  tags = { Name = var.agent_instance_name }
}
```

---

## Deep Dive: UserData Bootstrapping Templates

### 1. Master Bootstrapping (`userdata/master.sh.tpl`)
1. **Package Installation**: Installs `curl`, `git`, `gnupg`, `openjdk-17-jdk`, `docker.io`, and official Jenkins LTS.
2. **Directory Initialization**: Creates `/var/jenkins_home/casc_configs/`, `/var/jenkins_home/init.groovy.d/`, `/var/lib/jenkins/secrets/`, `/var/lib/jenkins/bootstrap/`.
3. **JCasC Injection**: Writes `system.yaml`, `security.yaml`, `credentials.yaml`, and `nodes.yaml` directly into `/var/jenkins_home/casc_configs/`.
4. **Groovy Init Injection**: Writes `create-pipeline-job.groovy` and `ssh-credential.groovy` into `/var/jenkins_home/init.groovy.d/`.
5. **Key & Pipeline Injections**: Writes RSA private key to `/var/lib/jenkins/secrets/agent_key` (`chmod 600`) and places `Jenkinsfile-compose` at `/var/lib/jenkins/bootstrap/Jenkinsfile-compose`.
6. **Zero-Touch Startup**: Injects `CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/` into Jenkins environment and restarts `jenkins.service`.

---

### 2. Agent Bootstrapping (`userdata/agent.sh.tpl`)
1. **Package Installation**: Installs `curl`, `git`, `openjdk-17-jdk`, `docker.io`.
2. **User Permissions**: Adds user `ubuntu` to `docker` group.
3. **Authorized Key Injection**: Appends `${controller_public_key}` directly into `/home/ubuntu/.ssh/authorized_keys`.
4. **Workspace Setup**: Creates `/home/ubuntu/jenkins` workspace directory owned by `ubuntu:ubuntu`.

---

## Command Lifecycle Guide

```bash
# Initialize working directory
terraform init

# Create secrets configuration file
cp terraform.tfvars.example terraform.tfvars

# Review plan
terraform plan

# Apply infrastructure
terraform apply -auto-approve

# Destroy infrastructure when finished
terraform destroy -auto-approve
```
