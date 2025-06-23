# infrastructure/s3_frontend.tf

resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-hosting-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-frontend-bucket"
  }
}

# Block public access at the bucket level, as CloudFront is the entry point.
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "frontend_s3_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}