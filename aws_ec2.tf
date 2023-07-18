resource "aws_instance" "terraform_sample_mitsuri" {
  count                       = 2
  ami                         = "ami-0d52744d6551d851e"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.terraform_sample_mitsuri[count.index].id
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.terraform_sample_mitsuri.id]
  key_name                    = "terraform_key"
  tags = {
    Name = "${format("test_server%02d", count.index + 1)}"
  }

}
