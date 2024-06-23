resource "aws_instance" "jenkins" {
  ami                    = var.AMIS[var.REGION]
  instance_type          = "t2.micro"
  availability_zone      = var.ZONE1
  key_name               = "new_key"
  vpc_security_group_ids = ["sg-0e493b239a9695d08"]
  tags = {
    Name = "jenkins_instance"
  Project = "Jenkins" }
}