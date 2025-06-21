# terraform/cloudfront.tf (Now just for the S3 bucket)

# 1. S3 Bucket for the React build files.
resource "aws_s3_bucket" "frontend" {
  bucket = "react-sec-deploy-frontend-bucket-reactsecops2" # Make sure this is globally unique!
}

# 2. Explicitly CONFIGURE the Public Access Block for this bucket.
# We are telling AWS that for THIS BUCKET, it's okay to have a public policy.
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false # Must be false to allow public policies
  block_public_policy     = false # THIS IS THE KEY: Set to false
  ignore_public_acls      = false # Must be false to allow public policies
  restrict_public_buckets = false # Must be false to allow public policies
}


# 3. Modern resource for S3 website configuration.
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
  # This resource depends on the public access block being configured first.
  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# 4. S3 Bucket Policy to allow public read access.
# This will now succeed because the block public access setting allows it.
resource "aws_s3_bucket_policy" "frontend_public_read" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
  # This resource depends on the public access block being configured first.
  depends_on = [aws_s3_bucket_public_access_block.frontend]
}


# --- ALL CLOUDFRONT RESOURCES HAVE BEEN REMOVED ---
# --- The aws_lb_listener_rule is also removed as it depended on CloudFront's logic ---
# --- We will re-create a simpler listener rule in ecs.tf ---


# --- NEW OUTPUTS ---
output "frontend_s3_website_url" {
  description = "The public URL for the frontend React app."
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}