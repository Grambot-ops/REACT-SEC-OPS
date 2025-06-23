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

# We will apply this policy MANUALLY after creating the OAI in the console.
# It is kept here for reference.
data "aws_iam_policy_document" "s3_policy_reference" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "AWS"
      # This will be replaced with the OAI's Canonical User ID from the AWS console
      identifiers = ["REPLACE_WITH_OAI_CANONICAL_USER_ID"] 
    }
  }
}
    
output "frontend_s3_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "s3_policy_for_cloudfront_reference" {
  description = "Reference S3 bucket policy. Apply this manually after creating the OAI."
  value = data.aws_iam_policy_document.s3_policy_reference.json
}