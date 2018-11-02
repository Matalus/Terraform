#Define provider Amazon Web Services
provider "aws" {
   region = "us-east-2"
   access_key = "${var.AWS_ACCESS_KEY}" #configured in tfvars
   secret_key = "${var.AWS_SECRET_KEY}" #configured in tfvars
   
}
#define VPC 
resource "aws_vpc" "tftest" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = "true"
    enable_dns_support = "true"
    tags {
        Name = "tf-vpc"
    }
}
resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.tftest.id}"

    tags {
        Name = "infra_tf"
    }
}

#define subnet
resource "aws_subnet" "tfsubnet" {
  vpc_id = "${aws_vpc.tftest.id}"
  cidr_block = "10.0.0.1/24"
  map_public_ip_on_launch = "true"

  tags {
    Name = "TF Subnet"
  }
}
#define route
resource "aws_route" "www" {
  route_table_id = "${aws_vpc.tftest.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gw.id}"
}

resource "aws_eip" "tftest-eip" {
    vpc = "true"
    depends_on = ["aws_internet_gateway.gw"]
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

    ingress {
        from_port = 3389
        to_port = 3389
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "allow WINRM"
    }
}

