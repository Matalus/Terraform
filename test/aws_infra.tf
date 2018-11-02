#Define provider Amazon Web Services
provider "aws" {
   region = "us-east-2"
   access_key = "${var.AWS_ACCESS_KEY}"
   secret_key = "${var.AWS_SECRET_KEY}"
   
}
#define VPC 
resource "aws_vpc" "tftest" {
    cidr_block = "10.0.0.0/16"
}
resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.tftest.id}"
}

#define subnet
resource "aws_subnet" "tfsubnet" {
  vpc_id = "${aws_vpc.tftest.id}"
  cidr_block = "10.0.0.1/24"

  tags {
    Name = "TF Subnet"
  }
}

resource "aws_instance" "Matt-Web-01" {
    ami = "ami-028779930ada5200c"
    instance_type = "t2.micro"
    key_name = "MattEC2"
    subnet_id = "${aws_subnet.tfsubnet.id}"
    vpc_security_group_ids = ["${aws_security_group.test-sg.id}"]

    provisioner "local-exec" {
        command = "echo ${aws_instance.Matt-Web-01.public_ip} > ip_address.txt"
    }   


    tags {
        Name = "Matt-Web-01"
    }
}

resource "aws_instance" "Matt-Web-02" {
    ami = "ami-0679e5ac84d15f15e"
    instance_type = "t2.micro"
    key_name = "MattEC2"
    subnet_id = "${aws_subnet.tfsubnet.id}"
    vpc_security_group_ids = ["${aws_security_group.test-sg.id}"]

    provisioner "local-exec" {
        command = "echo ${aws_instance.Matt-Web-02.public_ip} > ip_address.txt"
    }

    tags {
        Name = "Matt-Web-02"
    }
}

resource "aws_security_group" "test-sg" {
    name = "allow winrm"
    description = "Allow Windows Remote Management"
    vpc_id = "${aws_vpc.tftest.id}"

    ingress {
        from_port = 5985
        to_port = 5985
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "allow WINRM"
    }
}

