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

data "http" "myip" {
  url = "http://checkip.amazonaws.com/"
}

resource "aws_security_group" "bedrock_sg" {
  name        = "bedrock-sg"
  description = "bedrock security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    # Replace "YOUR_IP_ADDRESS" with your actual IP address with /32 CIDR notation
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
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

  user_data = <<-EOF
              #!/bin/bash -xe
              sudo yum update -y
              sudo yum groupinstall -y "Development Tools"
              sudo yum install -y openssl-devel bzip2-devel libffi-devel

              cd /usr/src/
              sudo wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
              sudo tar xzf Python-3.12.0.tgz

              cd Python-3.12.0/
              sudo ./configure --enable-optimizations
              sudo make altinstall

              python3.12 -c "import ssl; print(ssl.OPENSSL_VERSION)"

              python3.12 -m ensurepip --upgrade
              python3.12 -m pip install --upgrade pip setuptools

              cd /home/ec2-user/
              sudo yum install git -y

              sudo git clone https://github.com/rahul-grover/bedrock-council-app.git
              cd bedrock-council-app

              python3.12 -m venv venv
              source venv/bin/activate

              cd front-end/
              pip install -r requirements.txt
              
              PRIVATE_IP=$(hostname -i)
              echo $PRIVATE_IP
              export AWS_DEFAULT_REGION=ap-southeast-2
              
              chainlit run app.py --host $PRIVATE_IP --port 80 -w -d
              EOF
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = var.ec2_role_name
}