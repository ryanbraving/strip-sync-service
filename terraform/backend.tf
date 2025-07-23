terraform {
  backend "s3" {
    bucket       = "stripe-sync-service-terraform-state"
    key          = "stripe-sync-service/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true # Use a lock file in S3
  }
}