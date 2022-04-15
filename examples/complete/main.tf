module "nxos_bgp" {
  source  = "netascode/bgp/nxos"
  version = ">= 0.0.1"

  asn                     = "65001"
  enhanced_error_handling = false
  template_peers = {
    "SPINE-PEERS" = {
      asn              = "65001"
      description      = "Spine Peers template"
      peer_type        = "fabric-external"
      source_interface = "lo0"
      address_families = {
        ipv4_unicast = {
          send_community_standard = true
          route_reflector_client  = true
        }
        l2vpn_evpn = {
          send_community_standard = true
          send_community_extended = true
          route_reflector_client  = true
        }
      }
    }
  }
  vrfs = {
    "default" = {
      router_id                       = "1.2.3.4"
      log_neighbor_changes            = true
      graseful_restart_stalepath_time = 123
      graseful_restart_restart_time   = 123
      neighbors = {
        "5.6.7.8" = {
          description      = "My description"
          peer_type        = "fabric-external"
          asn              = "65002"
          source_interface = "lo2"
          address_families = {
            ipv4_unicast = {
              send_community_standard = true
              send_community_extended = true
              route_reflector_client  = false
            }
            l2vpn_evpn = {
              send_community_standard = true
              route_reflector_client  = false
            }
          }
        }
        "9.10.11.12" = {
          description  = "My description 2"
          inherit_peer = "SPINE-PEERS"
        }
      }
    }
    "VRF1" = {
      router_id                       = "10.20.30.40"
      log_neighbor_changes            = true
      graseful_restart_stalepath_time = 1230
      graseful_restart_restart_time   = 1230
      neighbors = {
        "50.60.70.80" = {
          description = "My description"
        }
        "90.100.110.120" = {
          description = "My description 2"
        }
      }
    }
  }
}
