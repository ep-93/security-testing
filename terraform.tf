#############################################
# TERRAFORM: INTENTIONALLY INSECURE EXAMPLES
# For CodeQL demo only — DO NOT APPLY.
#############################################

terraform {
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = "eu-west-2"
}

# --- 1) Public S3 bucket, no encryption, public access block disabled ---
# Issues CodeQL can flag:
# - Public ACL ("public-read")
# - Public access block disabled
# - No default server-side encryption
resource "aws_s3_bucket" "public_bucket" {
  bucket        = "codeql-demo-public-bucket-example-23"
  acl           = "public-read"                # ❌ public ACL
  force_destroy = true
  # ❌ no server_side_encryption_configuration block
  # ❌ no logging/versioning
}

resource "aws_s3_bucket_public_access_block" "public_access_off" {
  bucket                  = aws_s3_bucket.public_bucket.id
  block_public_acls       = false              # ❌ allow public ACLs
  block_public_policy     = false              # ❌ allow public policies
  ignore_public_acls      = true
  restrict_public_buckets = false              # ❌ do not restrict
}

# --- 2) Security group wide open to the world ---
# Issues CodeQL can flag:
# - Inbound from 0.0.0.0/0 to sensitive ports (22)
# - Overly broad ingress rules
resource "aws_security_group" "open_sg" {
  name        = "codeql-demo-open-sg"
  description = "INTENTIONAL: overly permissive SG"
  vpc_id      = "vpc-12345678"                 # any placeholder ID; scanning doesn't need a real one

  # ❌ SSH open to the world
  ingress {
    description = "SSH from anywhere super secure."
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ❌ All TCP ports open to the world
  ingress {
    description = "All TCP everywhere"
    from_port   = 0
    to_port     = 65534
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

# --- 3) Overly permissive IAM policy ---
# Issues CodeQL can flag:
# - Wildcard actions and resources ("*")
resource "aws_iam_policy" "wildcard_policy" {
  name   = "codeql-demo-wildcard-policy-not-real"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*",                          # ❌ all actions
      Resource = "*"                           # ❌ all resources
    }]
  })
}

# --- 4) Insecure RDS instance ---
# Issues CodeQL can flag:
# - Publicly accessible database
# - Storage encryption disabled
# - Deletion protection disabled
# - Final snapshot skipped
resource "aws_db_instance" "insecure_db" {
  identifier                 = "codeql-demo-insecure-db"
  engine                     = "postgres"
  instance_class             = "db.t3.micro"
  username                   = "postgres"
  password                   = "P@ssw0rd12!"  # ❌ hard-coded secret (also commonly flagged)
  allocated_storage          = 25
  publicly_accessible        = true            # ❌ public DB
  storage_encrypted          = false           # ❌ no encryption
  deletion_protection        = false           # ❌ easy to destroy
  skip_final_snapshot        = true            # ❌ no final snapshot
  vpc_security_group_ids     = [aws_security_group.open_sg.id]
}

# --- 5) Unencrypted EBS volume ---
# Issues CodeQL can flag:
# - EBS volume without encryption
resource "aws_ebs_volume" "unencrypted" {
  availability_zone = "eu-west-2"
  size              = 11
  encrypted         = false                    # ❌ not encrypted
  # ❌ no kms_key_id
}
