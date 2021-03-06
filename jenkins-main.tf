# t2.micro node with an AWS Tag naming it "web-server"
provider "aws" {
    region = "ap-south-1"
}

# Get the AWS Ubuntu image
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Create security group with web and ssh access
resource "aws_security_group" "web_server" {
  name = "web_server"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deploy ssh key for instance access
resource "aws_key_pair" "deployer" {
  key_name = "web_server"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Create web server
resource "aws_instance" "web_server" {
    ami = "${data.aws_ami.ubuntu.id}"
    vpc_security_group_ids = ["${aws_security_group.web_server.id}"]
    instance_type = "t2.micro"
    key_name      = "web_server"
    tags {
        Name = "web-server"
    }

  connection {
    user         = "ubuntu"
    private_key  = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
   source = "java.pp"
   destination = "/home/ubuntu/java.pp"
  }

  provisioner "file" {
   source = "jenkins.pp"
   destination = "/home/ubuntu/jenkins.pp"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install apache2 -y",
      "sudo apt-get install puppet -y",
      "sudo chmod 777 /var/www/html/index.html",
      "sudo puppet apply /home/ubuntu/java.pp",
      "sudo puppet apply /home/ubuntu/jenkins.pp"
    ]
  }

  provisioner "file" {
    source = "index.html"
    destination = "/var/www/html/index.html"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 644 /var/www/html/index.html"
    ]
  }

  # Save the public IP for testing
  provisioner "local-exec" {
    command = "echo ${aws_instance.web_server.public_ip} > public-ip.txt"
  }

}

output "public_ip" {
  value = "${aws_instance.web_server.public_ip}"
}
