terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    nxos = {
      source  = "netascode/nxos"
      version = ">=0.3.2"
    }
  }
}

# requirement
resource "nxos_feature_bgp" "example" {
  admin_state = "enabled"
}


module "main" {
  source = "../.."

  asn = "65002"
  depends_on = [
    nxos_feature_bgp.example
  ]
}

data "nxos_rest" "nxos_bgp" {
  dn = "sys/bgp"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp" {
  component = "nxos_bgp"

  equal "adminSt" {
    description = "adminSt"
    got         = data.nxos_rest.nxos_bgp.content.adminSt
    want        = "enabled"
  }
}
