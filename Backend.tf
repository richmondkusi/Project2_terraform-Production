# Creating s3 bucket
resource "aws_s3_bucket" "terraform-state-bucket1" {

  bucket = "terraform-state-bucket1"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "Terraform-state-bucket1"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "SSE1" {
  bucket = aws_s3_bucket.terraform-state-bucket1.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning_1" {
  bucket = aws_s3_bucket.terraform-state-bucket1.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Creating Dynamo DB Table
resource "aws_dynamodb_table" "terraform-lock1-table" {
  name         = "terraform-lock1-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}



# Creation of Backend

terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket1"
    key            = "terraform.tfstate1"
    region         = "eu-west-2"
    dynamodb_table = "terraform-lock1-table"
    encrypt        = true
  }
}