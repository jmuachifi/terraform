# modules/ec2/ec2_instance.tf
// To Generate Private Key
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
 variable "key_name" {}

// Create Key Pair for Connecting EC2 via SSH
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

// Save PEM file locally
resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = var.key_name
}

// Create a security group
resource "aws_security_group" "sg_ec2" {
  name        = "sg_ec2"
  description = "Security group for EC2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
variable "subnet_ids" {
  description = "List of subnet IDs"
  type = list(string)
  default = ["subnet-05a3acd1df6160e45", "subnet-0a86b5b762c97e73e"] 
}
variable "vpc_id" {
  description = "VPC ID"
  type = string
  default = "vpc-0c79b80b22ab20beb"
  
}

// Create an Elastic Load Balancer
resource "aws_lb" "elbweb" {
  name              = "elbweb"
  internal         = false
  load_balancer_type = "application"
  subnets = var.subnet_ids
  
}
// Create a Target Group
resource "aws_lb_target_group" "elbwebtg" {
  name     = "elbwebtg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
}
// Attach taget group to the load balancer
resource "aws_lb_target_group_attachment" "elbwebtgattachment" {
  count            = length(aws_instance.public_instance)
  target_group_arn = aws_lb_target_group.elbwebtg.arn
  target_id        = aws_instance.public_instance[count.index].id
  port             = 80
  
}

resource "aws_instance" "public_instance" {
  count                 = 2
  ami                    = "ami-08f7912c15ca96832"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
    user_data              = <<-EOF
    #!/bin/bash
    echo "<!--aws-lab.html-->" > /var/www/html/index.html
    echo "<!DOCTYPE html>" >> /var/www/html/index.html
    echo "<html>" >> /var/www/html/index.html
    echo "<head>" >> /var/www/html/index.html
    echo "  <meta name='viewport' content='width=device-width, initial-scale=1'>" >> /var/www/html/index.html
    echo "  <link href='https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css' rel='stylesheet'>" >> /var/www/html/index.html
    echo "  <script src='https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js'></script>" >> /var/www/html/index.html
    echo "  <title>AWS-WEB-SERVER</title>" >> /var/www/html/index.html
    echo "</head>" >> /var/www/html/index.html
    echo "<body style='background-color: black;'>" >> /var/www/html/index.html
    echo "" >> /var/www/html/index.html
    echo "<div class='container mt-3'>" >> /var/www/html/index.html
    echo "  <h2>AWS WEB SERVR</h2>" >> /var/www/html/index.html
    echo "  <div class='mt-4 p-5 bg-primary text-white rounded'>" >> /var/www/html/index.html
    echo "    <h1>ENGINX - IT WORKS!</h1>" >> /var/www/html/index.html
    echo "    <p>Yes, AWS is Great and work very well</p>" >> /var/www/html/index.html
    echo "  </div>" >> /var/www/html/index.html
    echo "</div>" >> /var/www/html/index.html
    echo "" >> /var/www/html/index.html
    echo "</body>" >> /var/www/html/index.html
    echo "</html>" >> /var/www/html/index.html
  EOF

  tags = {
    Name = "public_instance-${count.index}"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa_4096.private_key_pem
    host        = self.public_ip
  
  }
 provisioner "remote-exec" {
        inline = [
            "sudo apt-get update -y",
            "sudo apt-get install -y nginx",
            "sudo systemctl enable nginx",
            "sudo systemctl start nginx"
        ]
    
    }
    #depends_on = [aws_elb.elbweb]
}

# output "public_instance_id" {
#     value = aws_instance.public_instance[*].id
# }
# output "public_ip" {
#     value = aws_instance.public_instance[*].public_ip
# }
output "public_instance_id" {
  value = [for instance in aws_instance.public_instance : instance.id]
}

output "public_ip" {
  value = [for instance in aws_instance.public_instance : instance.public_ip]
}
output "elb_dns_name" {
  value = aws_lb.elbweb.dns_name
}