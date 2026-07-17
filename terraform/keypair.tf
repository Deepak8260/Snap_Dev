#############################################
# Create AWS Key Pair
#############################################

resource "aws_key_pair" "terraform_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Name        = var.key_name
    Project     = var.project_name
    Environment = var.environment
  }
}