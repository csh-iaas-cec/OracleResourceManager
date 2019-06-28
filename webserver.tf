variable "tenancy_ocid" {
default = "ocid1.tenancy.oc1..aaaaaaaarwtkdhuw4wqljz5jmwxpsekrmjepnwnakffbjei3kcgn6rstazsq"
}



variable "region" {
default = "us-ashburn-1"
}


variable "compartment_ocid" {
default = "ocid1.compartment.oc1..aaaaaaaazpqeo2pr5yltbvgpixmhi6v2ukglwanbuykytgjhkumzwhra6teq"
}

provider "oci" {

 region           = "us-ashburn-1"
}

#data "oci_identity_availability_domains" "ashburn" {
#  compartment_id = "ocid1.compartment.oc1..aaaaaaaazpqeo2pr5yltbvgpixmhi6v2ukglwanbuykytgjhkumzwhra6teq"
#}

### Network Variables ##### 

variable "vcn_cidr_block" {
  default = "10.0.0.0/16"
}

variable "dns_label_vcn" {
  default = "dnsvcn"
}

variable "subnet_cidr_w1" {
  default = "10.0.10.0/24"
}

variable "subnet_cidr_w2" {
  default = "10.0.20.0/24"
}
variable "ad" {
    type = "list"
    default = ["XqVg:US-ASHBURN-AD-1","XqVg:US-ASHBURN-AD-2","XqVg:US-ASHBURN-AD-3"]
}


#### VCN  #######

resource "oci_core_virtual_network" "vcn_w" {
  cidr_block     = "${var.vcn_cidr_block}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "vcn_webserver"
  dns_label      = "vcn"

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

#### Internet Gateay ###

resource "oci_core_internet_gateway" "igw" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "igw"
  vcn_id         = "${oci_core_virtual_network.vcn_w.id}"
}

#### Route Table #####

resource "oci_core_route_table" "rt1" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.vcn_w.id}"
  display_name   = "rt1"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.igw.id}"
  }
}

##### Security Lists ######

resource "oci_core_security_list" "sl_w" {
  display_name   = "sl-loadbalancer"
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.vcn_w.id}"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    tcp_options {
      max = 22
      min = 22
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = 80
      min = 80
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    tcp_options {
      max = 443
      min = 443
    }

    protocol = "6"
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    icmp_options {
      type = 0
    }

    protocol = 1
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    icmp_options {
      type = 3
      code = 4
    }

    protocol = 1
    source   = "0.0.0.0/0"
  }
  ingress_security_rules {
    icmp_options {
      type = 8
    }

    protocol = 1
    source   = "0.0.0.0/0"
  }
}

#### Subnet  #######

resource "oci_core_subnet" "subnet1" {
  availability_domain = "${var.ad[0]}"
  cidr_block          = "${var.subnet_cidr_w1}"
  display_name        = "subnet1-AD1"
  security_list_ids   = "${oci_core_security_list.sl_w.id}"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.vcn_w.id}"
  route_table_id      = "${oci_core_route_table.rt1.id}"
  dhcp_options_id     = "${oci_core_virtual_network.vcn_w.default_dhcp_options_id}"

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "subnet2" {
  availability_domain = "${var.ad[1]}"
  cidr_block          = "${var.subnet_cidr_w2}"
  display_name        = "subnet2-AD2"
  security_list_ids   = "${oci_core_security_list.sl_w.id}"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.vcn_w.id}"
  route_table_id      = "${oci_core_route_table.rt1.id}"
  dhcp_options_id     = "${oci_core_virtual_network.vcn_w.default_dhcp_options_id}"

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

