# ====================================================
# 🔐 SECURITY GROUPS
# ====================================================

# ------------------ Load Balancer SG ------------------
resource "aws_security_group" "lb_sg" {
  name        = "eks-lb-sg"
  description = "Allow HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-lb-sg"
  }
}

# ------------------ Worker Node SG ------------------
resource "aws_security_group" "worker_sg" {
  name        = "eks-worker-sg"
  description = "Allow SSH and traffic only from LB"
  vpc_id      = aws_vpc.main.id

  # SSH only from your IP / bastion
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # App traffic only from Load Balancer SG
  ingress {
    description     = "From Load Balancer"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id,aws_security_group.allow_all.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-worker-sg"
  }
}

# ------------------ RDS SG (Only from Worker Nodes) ------------------
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow DB only from worker nodes and bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from Workers and Bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [
      aws_security_group.worker_sg.id,
      aws_security_group.allow_all.id,aws_security_group.lb_sg.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

#--------------------allow-all-------------------------------#
resource "aws_security_group" "allow_all" {
  name        = "bastion-sg"
  description = "SSH access to bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}
