resource "aws_security_group" "bedrock_sg" {
  name        = "terraform-bedrock-sg"
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


resource "aws_instance" "tf_bedrock_instance" {
  ami             = var.ami_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.bedrock_sg.name]

  iam_instance_profile = var.ec2_role_name

  tags = {
    Name       = var.instance_name
    nukeoptout = true
    Owner      = "gunjan.mehta@slalom.com"
  }

  user_data = file("userdata.sh")
}