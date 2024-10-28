resource "aws_instance" "bedrock_instance_test" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name

  iam_instance_profile = aws_iam_instance_profile.my_instance_profile.name
}

resource "aws_iam_instance_profile" "bedrock_instance_profile_test" {
  name = "MyInstanceProfile"
  role = var.ec2_role_name
}