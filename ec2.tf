# Create a new SSH key pair
resource "tls_private_key" "bedrock_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bedrock_generated_key" {
  key_name   = "terraform-key"
  public_key = tls_private_key.bedrock_ssh_key.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content  = tls_private_key.bedrock_ssh_key.private_key_pem
  filename = "bedrock-council-app/terraform-key.pem"

  # Set file permissions to read-only
  file_permission = "0400"
}

resource "aws_security_group" "bedrock_sg" {
  name        = "bedrock-sg"
  description = "bedrock security group"
  vpc_id      = var.vpc_id

  # Ingress rules to allow HTTP traffic from specified IPs
  dynamic "ingress" {
    for_each = var.allowed_ips
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bedrock-security-group"
  }
}


resource "aws_instance" "bedrock_instance_test" {
  ami             = var.ami_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.bedrock_sg.name]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name       = var.instance_name
    nukeoptout = true
    Owner      = "gunjan.mehta@slalom.com"
  }

  user_data = file("userdata.sh")
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = var.ec2_role_name
}