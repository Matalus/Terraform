provider "aws" {
   region = "us-east-2"
}

resource "aws_vpc" "myapp" {
  cidr_block = "10.100.0.0/16"
}

resource "aws_subnet" "public_1a" {
  vpc_id = "${aws_vpc.myapp.id}"
  cidr_block = "10.100.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-2a"

  tags {
    Name = "Public 1A"
  }
}

resource "aws_subnet" "public_1b" {
  vpc_id = "${aws_vpc.myapp.id}"
  cidr_block = "10.100.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "us-east-2b"

  tags {
    Name = "Public 1B"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.myapp.id}"

  tags {
    Name = "myapp gw"
  }
}

resource "aws_security_group" "allow_winrm" {
  name = "allow_all"
  description = "Allow inbound WINRM traffic from my IP"
  vpc_id = "${aws_vpc.myapp.id}"

  ingress {
    from_port = 5985
    to_port = 5985
    protocol = "tcp"
    cidr_blocks = ["123.123.123.123/32"]
  }
  
  tags {
    Name = "Allow WINRM"
  }
}

resource "aws_security_group" "myapp_SG" {
  name = "web server"
  description = "allow HTTP and HTTPS traffic in, browser out"
  vpc_id = "${aws_vpc.myapp.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 1024
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "myapp_sql" {
  name = "web server"
  description = "Allow access to SQL"
  vpc_id = "${aws_vpc.myapp.id}"

  ingress {
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = ["${aws_instance.web01.private_ip}","${aws_instance.web02.private_ip}"]
  }

  egress {
      from_port = 1024
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web01" {
    ami = "ami-028779930ada5200c"
    instance_type = "t1.micro"
    subnet_id = "${aws_subnet.public_1a.id}"
    vpc_security_group_ids = ["${aws_security_group.myapp_SG.id}","${aws_security_group.allow_winrm.id}"]
    key_name = "MattEC2"
    tags {
        Name = "web01"
    }
}

resource "aws_instance" "web02" {
    ami = "ami-0679e5ac84d15f15e"
    instance_type = "t1.micro"
    subnet_id = "${aws_subnet.public_1b.id}"
    vpc_security_group_ids = ["${aws_security_group.myapp_SG.id}","${aws_security_group.allow_winrm.id}"]
    key_name = "MattEC2"
    tags {
        Name = "web02"
    }
}

resource "aws_elb" "web-elb" {
  name = "web-elb"
  availability_zones = ["us-east-2a", "us-east-2b"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.web01.id}","${aws_instance.web02.id}"]

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "Web ELB"
  }
}

