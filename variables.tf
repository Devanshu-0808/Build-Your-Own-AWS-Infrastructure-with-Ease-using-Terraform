

resource "aws_key_pair" "key_tf" {
  key_name   = "key-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCp249PyCh6bs69wU/Ul7S42kbny80/qUs43Ewbx1Y1/uLjUoJHjs3TFyZN90kQHcFSVXezsTCffVVZ0SBVxnAwPbbtfUaSwYL9lneq7jiUoeOoV0xLsOQV86+RRj3+KLBa8QxGcD9quT81gmoK7OIFqcuXeb1LDYn9mRugOaJpsAlif8UjYEg3Z5P8+GNkFo64D6pHeozrrtTND4js51osdPkLJ26B2W/fb7wck29FUI45zI6QnjscUPkdjXp2bp/Gn8TUmXHKsJb33/qk9PzISuzGo/p+sh5KZlQrktgh+Pudi75vDfEs3Rco48W9Lc73Y8gG6uLFIvr5urs+oZRX5TeH1I/jajZeLkCzqUExcG4Ge4MktDw3c1n5vDjjpG+jycqnEypT+XdRByup3r66QJ0uaScm2SOsMLXq9Uc2vZKI5OhafDljtMaMzXYgPEemrYBYU210HVW7RDjciuALuGyKsRU9JCuFsLSNccvo3qg8weBfI2EUg0/BgVy9xbE= devanshu@kali"
}
####

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"

  dynamic "ingress" {
    for_each = [22, 80,443]
    iterator = port
    content {

      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }

  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

} 
####
resource "aws_instance" "web" {
  ami           = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.key_tf.key_name
  vpc_security_group_ids=["${aws_security_group.allow_tls.id}"]
  tags = {
    Name = "first_tf_instance"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo su -i
  apt-get update
  apt-get install nginx -y
   echo "H1 Devanshu" > /var/www/html/index.html
EOF

connection {
    type ="ssh"
    user="ubuntu"
    private_key=file("${path.module}/aws_instance")
    host="${self.public_ip}" 
  }

provisioner "file"{
  source="readme.md" # terraform machine
  destination = "/tmp/readme.md"  # remote machine
}

provisioner "local-exec"{
  command ="echo ${self.public_ip} > /tmp/mypublicip.txt"
}
provisioner "local-exec"{
  working_dir="/tmp/"
  interpreter=[
    "/usr/bin/python3" , "-c"
  ]
  command ="print('HelloWorld')"
}
provisioner "local-exec"{
    command = "echo 'at Create'"
}
provisioner "local-exec"{
    when =destroy
    command ="echo 'at delete'"
}
provisioner "remote-exec"{
    inline=[
         "echo 'hello'>/tmp/test.txt"
    ]
    
}
provisioner "remote-exec"{
    script="./test.sh"
    
}
}

data "aws_ami" "ubuntu"{
  most_recent= true
  owners=["099720109477"]

filter {
 name=  "name"
 values=["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
}
filter {
   name="root-device-type"
   values=["ebs"]
}
filter {
   name="virtualization-type"
   values=["hvm"]
}

}

terraform{
   backend "s3" {
    bucket = "terraform-bucket1.2"
    region = "us-east-1"
    key="hello.tfstate"
     dynamodb_table ="devanshu-table"
   }
}