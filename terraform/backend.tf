terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# For production, use remote backend like GCS:
# terraform {
#   backend "gcs" {
#     bucket = "your-terraform-state-bucket"
#     prefix = "terraform/state"
#   }
# }
