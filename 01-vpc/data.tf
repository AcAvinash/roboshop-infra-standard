
# data source needed to get default vpc details
data "aws_vpc" "default" {
  default = true
}
