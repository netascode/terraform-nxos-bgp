<!-- BEGIN_TF_DOCS -->
[![Tests](https://github.com/netascode/terraform-nxos-bgp/actions/workflows/test.yml/badge.svg)](https://github.com/netascode/terraform-nxos-bgp/actions/workflows/test.yml)

# Terraform NX-OS BGP Module

Manages NX-OS BGP

Model Documentation: [Link](https://developer.cisco.com/docs/cisco-nexus-3000-and-9000-series-nx-api-rest-sdk-user-guide-and-api-reference-release-9-3x/#!configuring-bgp)

## Examples

```hcl
module "nxos_bgp" {
  source  = "netascode/bgp/nxos"
  version = ">= 0.1.0"

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
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_nxos"></a> [nxos](#requirement\_nxos) | >= 0.3.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nxos"></a> [nxos](#provider\_nxos) | >= 0.3.9 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_device"></a> [device](#input\_device) | A device name from the provider configuration. | `string` | `null` | no |
| <a name="input_asn"></a> [asn](#input\_asn) | BGP Autonomous system number. | `string` | n/a | yes |
| <a name="input_enhanced_error_handling"></a> [enhanced\_error\_handling](#input\_enhanced\_error\_handling) | BGP Enhanced error handling. | `bool` | `true` | no |
| <a name="input_template_peers"></a> [template\_peers](#input\_template\_peers) | BGP Template Peers list.<br>  Choices `peer_type`: `fabric-internal`, `fabric-external`, `fabric-border-leaf`. Default value `peer_type`: `fabric-internal`.<br>  List `address_families`:<br>  Choices `address_family`: `ipv4_unicast`, `ipv6_unicast`. | <pre>list(object({<br>    name             = string<br>    asn              = optional(string)<br>    description      = optional(string)<br>    peer_type        = optional(string)<br>    source_interface = optional(string)<br>    address_families = optional(list(object({<br>      address_family          = string<br>      send_community_standard = optional(bool)<br>      send_community_extended = optional(bool)<br>      route_reflector_client  = optional(bool)<br>    })))<br>  }))</pre> | `[]` | no |
| <a name="input_vrfs"></a> [vrfs](#input\_vrfs) | BGP VRF list.<br>  List `neighbors`:<br>  Allowed formats `ip`: `192.168.1.1` or `192.168.1.0/24`.<br>  Choices `peer_type`: `fabric-internal`, `fabric-external`, `fabric-border-leaf`. Default value `peer_type`: `fabric-internal`.<br>  List `address_families`:<br>  Choices `address_family`: `ipv4_unicast`, `ipv6_unicast`, `l2vpn_evpn`. | <pre>list(object({<br>    vrf                             = string<br>    router_id                       = optional(string)<br>    log_neighbor_changes            = optional(bool)<br>    graceful_restart_stalepath_time = optional(number)<br>    graceful_restart_restart_time   = optional(number)<br>    neighbors = optional(list(object({<br>      ip               = string<br>      asn              = optional(string)<br>      inherit_peer     = optional(string)<br>      description      = optional(string)<br>      peer_type        = optional(string)<br>      source_interface = optional(string)<br>      address_families = optional(list(object({<br>        address_family          = string<br>        send_community_standard = optional(bool)<br>        send_community_extended = optional(bool)<br>        route_reflector_client  = optional(bool)<br>      })))<br>    })))<br>  }))</pre> | `[]` | no |

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