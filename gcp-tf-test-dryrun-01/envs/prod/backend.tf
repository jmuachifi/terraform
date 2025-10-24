terraform {
  backend "gcs" {
    bucket = "REPLACE_WITH_STATE_BUCKET"
    prefix = "state/prod"
  }
}
