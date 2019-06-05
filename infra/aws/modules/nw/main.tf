resource "aws_vpc" "aws-module-nw-vpc" {
  cidr_block = "${var.vpc_cidr_block}"

  tags = {
    Name = "${var.namespace}"
  }
}

resource "aws_internet_gateway" "aws-module-nw-internet-gateway" {
  vpc_id = "${aws_vpc.aws-module-nw-vpc.id}"
  tags = {
    Name = "${var.namespace}"
  }
}

resource "aws_route" "aws-module-nw-vpc" {
  route_table_id = "${aws_vpc.aws-module-nw-vpc.main_route_table_id}"
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id  = "${aws_internet_gateway.aws-module-nw-internet-gateway.id}"
}

data "aws_availability_zones" "available" {
  blacklisted_names = var.blacklisted_zones
}

resource "aws_subnet" "aws-module-nw-subnet" {
  count      = var.subnet_count
  vpc_id     = "${aws_vpc.aws-module-nw-vpc.id}"
  cidr_block = replace(var.vpc_cidr_block, "/([0-9]+)\\.([0-9]+)\\.[0-9]+\\.([0-9]+)\\/([0-9]+)/", "$1.$2.${count.index + 1}.$3/24")
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true
}
