<!-- BEGIN_TF_DOCS -->
[![Tests](https://github.com/netascode/terraform-nxos-bgp/actions/workflows/test.yml/badge.svg)](https://github.com/netascode/terraform-nxos-bgp/actions/workflows/test.yml)

# Terraform NXOS BGP Module

Description

Manages NX-OS BGP

Model Documentation: [Link](https://developer.cisco.com/docs/cisco-nexus-3000-and-9000-series-nx-api-rest-sdk-user-guide-and-api-reference-release-9-3x/#!configuring-bgp)

## Examples

```hcl
module "nxos_bgp" {
  source  = "netascode/bgp/nxos"
  version = ">= 0.0.1"

  asn                     = "65001"
  enhanced_error_handling = false
  template_peer = {
    "SPINE-PEERS" = {
      asn              = "65001"
      description      = "Spine Peers template"
      peer_type        = "fabric-external"
      source_interface = "lo0"
      address_family = {
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
  vrf = {
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
          address_family = {
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
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_nxos"></a> [nxos](#requirement\_nxos) | >= 0.3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nxos"></a> [nxos](#provider\_nxos) | 0.3.4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_asn"></a> [asn](#input\_asn) | BGP Autonomous system number. | `string` | n/a | yes |
| <a name="input_enhanced_error_handling"></a> [enhanced\_error\_handling](#input\_enhanced\_error\_handling) | BGP Enhanced error handling. | `bool` | `true` | no |
| <a name="input_template_peer"></a> [template\_peer](#input\_template\_peer) | BGP template peers. | <pre>map(object({<br>    asn              = optional(string)<br>    description      = optional(string)<br>    peer_type        = optional(string)<br>    source_interface = optional(string)<br>    address_family = optional(map(object({<br>      send_community_standard = optional(bool)<br>      send_community_extended = optional(bool)<br>      route_reflector_client  = optional(bool)<br>    })))<br>  }))</pre> | `{}` | no |
| <a name="input_vrf"></a> [vrf](#input\_vrf) | BGP VRFs. | <pre>map(object({<br>    router_id                       = optional(string)<br>    log_neighbor_changes            = optional(bool)<br>    graseful_restart_stalepath_time = optional(number)<br>    graseful_restart_restart_time   = optional(number)<br>    neighbors = optional(map(object({<br>      asn              = optional(string)<br>      inherit_peer     = optional(string)<br>      description      = optional(string)<br>      peer_type        = optional(string)<br>      source_interface = optional(string)<br>      address_family = optional(map(object({<br>        send_community_standard = optional(bool)<br>        send_community_extended = optional(bool)<br>        route_reflector_client  = optional(bool)<br>      })))<br>    })))<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dn"></a> [dn](#output\_dn) | Distinguished name of the object. |

## Resources

| Name | Type |
|------|------|
| [nxos_bgp.bgpEntity](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp) | resource |
| [nxos_bgp_graceful_restart.bgpGr](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp_graceful_restart) | resource |
| [nxos_bgp_instance.bgpInst](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp_instance) | resource |
| [nxos_bgp_peer.bgpPeer](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp_peer) | resource |
| [nxos_bgp_peer_address_family.bgpPeerAf](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp_peer_address_family) | resource |
| [nxos_bgp_peer_template.bgpPeerCont](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp_peer_template) | resource |
| [nxos_bgp_peer_template_address_family.bgpPeerAf](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp_peer_template_address_family) | resource |
| [nxos_bgp_route_control.bgpRtCtrl](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp_route_control) | resource |
| [nxos_bgp_vrf.bgpDom](https://registry.terraform.io/providers/netascode/nxos/latest/docs/resources/bgp_vrf) | resource |
<!-- END_TF_DOCS -->