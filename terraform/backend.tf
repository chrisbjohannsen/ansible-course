terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    region = "us-west-2"
    bucket = "orbitdev.terraform.state.a72c58f7-ffee-486e-ae01-56de58a9368d"
    key    = "ansible-course"
  }
}
