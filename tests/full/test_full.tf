terraform {
  required_version = ">= 1.3.0"

  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    nxos = {
      source  = "netascode/nxos"
      version = ">=0.3.15"
    }
  }
}

# requirements
resource "nxos_feature_bgp" "fmBgp" {
  admin_state = "enabled"
}

resource "nxos_vrf" "l3Inst" {
  name = "VRF1"
}

resource "nxos_ipv4_vrf" "ipv4Dom" {
  name = "VRF1"
}

module "main" {
  source = "../.."

  asn                     = "65001"
  enhanced_error_handling = false
  template_peers = [
    {
      name             = "SPINE-PEERS"
      asn              = "65001"
      description      = "Spine Peers template"
      peer_type        = "fabric-external"
      source_interface = "lo0"
      address_families = [
        {
          address_family          = "ipv4_unicast"
          send_community_standard = true
          route_reflector_client  = true
        },
        {
          address_family          = "l2vpn_evpn"
          send_community_standard = true
          send_community_extended = true
          route_reflector_client  = true
        }
      ]
    }
  ]
  vrfs = [
    {
      vrf                             = "default"
      router_id                       = "1.2.3.4"
      log_neighbor_changes            = true
      graceful_restart_stalepath_time = 123
      graceful_restart_restart_time   = 123
      neighbors = [
        {
          ip               = "5.6.7.8"
          description      = "My description"
          peer_type        = "fabric-external"
          asn              = "65002"
          source_interface = "lo2"
          address_families = [
            {
              address_family          = "ipv4_unicast"
              send_community_standard = true
              send_community_extended = true
              route_reflector_client  = false
            },
            {
              address_family          = "l2vpn_evpn"
              send_community_standard = true
              route_reflector_client  = false
            }
          ]
        },
        {
          ip           = "9.10.11.12"
          description  = "My description 2"
          inherit_peer = "SPINE-PEERS"
        }
      ]
    },
    {
      vrf                             = "VRF1"
      router_id                       = "10.20.30.40"
      log_neighbor_changes            = true
      graceful_restart_stalepath_time = 1230
      graceful_restart_restart_time   = 1230
      neighbors = [
        {
          ip          = "50.60.70.80"
          description = "My description"
        },
        {
          ip          = "90.100.110.120"
          description = "My description 2"
        }
      ]
    }
  ]
  depends_on = [
    nxos_feature_bgp.fmBgp,
    nxos_vrf.l3Inst,
    nxos_ipv4_vrf.ipv4Dom
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

data "nxos_rest" "nxos_bgp_instance" {
  dn = "sys/bgp/inst"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_instance" {
  component = "nxos_bgp_instance"

  equal "adminSt" {
    description = "adminSt"
    got         = data.nxos_rest.nxos_bgp_instance.content.adminSt
    want        = "enabled"
  }

  equal "asn" {
    description = "asn"
    got         = data.nxos_rest.nxos_bgp_instance.content.asn
    want        = "65001"
  }

  equal "enhancedErr" {
    description = "enhancedErr"
    got         = data.nxos_rest.nxos_bgp_instance.content.enhancedErr
    want        = "no"
  }
}

data "nxos_rest" "nxos_bgp_vrf_default" {
  dn = "sys/bgp/inst/dom-[default]"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_vrf_default" {
  component = "nxos_bgp_vrf_default"

  equal "name" {
    description = "name"
    got         = data.nxos_rest.nxos_bgp_vrf_default.content.name
    want        = "default"
  }

  equal "rtrId" {
    description = "rtrId"
    got         = data.nxos_rest.nxos_bgp_vrf_default.content.rtrId
    want        = "1.2.3.4"
  }
}

data "nxos_rest" "nxos_bgp_vrf_vrf1" {
  dn = "sys/bgp/inst/dom-[VRF1]"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_vrf_vrf1" {
  component = "nxos_bgp_vrf_vrf1"

  equal "name" {
    description = "name"
    got         = data.nxos_rest.nxos_bgp_vrf_vrf1.content.name
    want        = "VRF1"
  }

  equal "rtrId" {
    description = "rtrId"
    got         = data.nxos_rest.nxos_bgp_vrf_vrf1.content.rtrId
    want        = "10.20.30.40"
  }
}

data "nxos_rest" "nxos_bgp_route_control" {
  dn = "sys/bgp/inst/dom-[default]/rtctrl"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_route_control" {
  component = "nxos_bgp_route_control"

  equal "enforceFirstAs" {
    description = "enforceFirstAs"
    got         = data.nxos_rest.nxos_bgp_route_control.content.enforceFirstAs
    want        = "enabled"
  }

  equal "fibAccelerate" {
    description = "fibAccelerate"
    got         = data.nxos_rest.nxos_bgp_route_control.content.fibAccelerate
    want        = "disabled"
  }

  equal "logNeighborChanges" {
    description = "logNeighborChanges"
    got         = data.nxos_rest.nxos_bgp_route_control.content.logNeighborChanges
    want        = "enabled"
  }

  equal "supprRt" {
    description = "supprRt"
    got         = data.nxos_rest.nxos_bgp_route_control.content.supprRt
    want        = "enabled"
  }
}

data "nxos_rest" "nxos_bgp_graceful_restart" {
  dn = "sys/bgp/inst/dom-[default]/gr"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_graceful_restart" {
  component = "nxos_bgp_graceful_restart"

  equal "restartIntvl" {
    description = "restartIntvl"
    got         = data.nxos_rest.nxos_bgp_graceful_restart.content.restartIntvl
    want        = "123"
  }

  equal "staleIntvl" {
    description = "staleIntvl"
    got         = data.nxos_rest.nxos_bgp_graceful_restart.content.staleIntvl
    want        = "123"
  }
}

data "nxos_rest" "nxos_bgp_peer_template" {
  dn = "sys/bgp/inst/dom-[default]/peercont-[SPINE-PEERS]"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_peer_template" {
  component = "nxos_bgp_peer_template"

  equal "asn" {
    description = "asn"
    got         = data.nxos_rest.nxos_bgp_peer_template.content.asn
    want        = "65001"
  }

  equal "desc" {
    description = "desc"
    got         = data.nxos_rest.nxos_bgp_peer_template.content.desc
    want        = "Spine Peers template"
  }

  equal "peerType" {
    description = "peerType"
    got         = data.nxos_rest.nxos_bgp_peer_template.content.peerType
    want        = "fabric-external"
  }

  equal "srcIf" {
    description = "srcIf"
    got         = data.nxos_rest.nxos_bgp_peer_template.content.srcIf
    want        = "lo0"
  }
}

data "nxos_rest" "nxos_bgp_peer_template_address_family" {
  dn = "sys/bgp/inst/dom-[default]/peercont-[SPINE-PEERS]/af-[l2vpn-evpn]"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_peer_template_address_family" {
  component = "nxos_bgp_peer_template_address_family"

  equal "ctrl" {
    description = "ctrl"
    got         = data.nxos_rest.nxos_bgp_peer_template_address_family.content.ctrl
    want        = "rr-client"
  }

  equal "sendComExt" {
    description = "sendComExt"
    got         = data.nxos_rest.nxos_bgp_peer_template_address_family.content.sendComExt
    want        = "enabled"
  }

  equal "sendComStd" {
    description = "sendComStd"
    got         = data.nxos_rest.nxos_bgp_peer_template_address_family.content.sendComStd
    want        = "enabled"
  }
}

data "nxos_rest" "nxos_bgp_peer" {
  dn = "sys/bgp/inst/dom-[default]/peer-[5.6.7.8]"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_peer" {
  component = "nxos_bgp_peer"

  equal "asn" {
    description = "asn"
    got         = data.nxos_rest.nxos_bgp_peer.content.asn
    want        = "65002"
  }

  equal "name" {
    description = "name"
    got         = data.nxos_rest.nxos_bgp_peer.content.name
    want        = "My description"
  }

  equal "peerType" {
    description = "peerType"
    got         = data.nxos_rest.nxos_bgp_peer.content.peerType
    want        = "fabric-external"
  }

  equal "srcIf" {
    description = "srcIf"
    got         = data.nxos_rest.nxos_bgp_peer.content.srcIf
    want        = "lo2"
  }

  equal "peerImp" {
    description = "peerImp"
    got         = data.nxos_rest.nxos_bgp_peer.content.peerImp
    want        = ""
  }
}

data "nxos_rest" "nxos_bgp_peer_address_family" {
  dn = "sys/bgp/inst/dom-[default]/peer-[5.6.7.8]/af-[ipv4-ucast]"

  depends_on = [module.main]
}

resource "test_assertions" "nxos_bgp_peer_address_family" {
  component = "nxos_bgp_peer_address_family"

  equal "ctrl" {
    description = "ctrl"
    got         = data.nxos_rest.nxos_bgp_peer_address_family.content.ctrl
    want        = ""
  }

  equal "sendComExt" {
    description = "sendComExt"
    got         = data.nxos_rest.nxos_bgp_peer_address_family.content.sendComExt
    want        = "enabled"
  }

  equal "sendComStd" {
    description = "sendComStd"
    got         = data.nxos_rest.nxos_bgp_peer_address_family.content.sendComStd
    want        = "enabled"
  }
}
