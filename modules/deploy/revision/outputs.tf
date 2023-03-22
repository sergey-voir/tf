output "revision_url" {
  value = "s3://${aws_s3_bucket.rev_bucket.bucket}/${aws_s3_object.rev_obj.key}"
}
