terraform {
  source = "../modules"
}
inputs = {
  project_name = "nginx-webapp"
  domain       = "example.com"
}