locals {
  address_family_names_map = {
    "ipv4_unicast" : "ipv4-ucast"
    "ipv6_unicast" : "ipv6-ucast"
    "l2vpn_evpn" : "l2vpn-evpn"
  }
  vrf_map           = { for v in var.vrfs : v.vrf => v }
  template_peer_map = { for v in var.template_peers : v.name => v }
  template_peer_af_map = merge([
    for tp in var.template_peers : {
      for af in tp.address_families :
      "${tp.name}-${af.address_family}" => merge(af, { "name" : tp.name, "address_family" : local.address_family_names_map[af.address_family] })
    } if tp.address_families != null
  ]...)
  /* Example:
  {
    "SPINE-PEERS-ipv4_unicast" = {
      "address_family" = "ipv4-ucast"
      "route_reflector_client" = true
      "send_community_extended" = tobool(null)
      "send_community_standard" = true
      "name" = "SPINE-PEERS"
    }
    "SPINE-PEERS-l2vpn_evpn" = {
      "address_family" = "l2vpn-evpn"
      "route_reflector_client" = true
      "send_community_extended" = true
      "send_community_standard" = true
      "name" = "SPINE-PEERS"
  }
  */

  neighbors_map = merge([
    for v in var.vrfs : {
      for n in v.neighbors : "${v.vrf}-${n.ip}" => merge(n, { "vrf" : v.vrf })
    }
  ]...)
  /* Example:
  {
    "VRF1-50.60.70.80" = {
      "address_families" = tolist(null)
      "asn" = tostring(null)
      "description" = "My description"
      "inherit_peer" = tostring(null)
      "ip" = "50.60.70.80"
      "peer_type" = tostring(null)
      "source_interface" = tostring(null)
      "vrf" = "VRF1"
    }
    "VRF1-90.100.110.120" = {
      "address_families" = tolist(null)
      "asn" = tostring(null)
      "description" = "My description 2"
      "inherit_peer" = tostring(null)
      "ip" = "90.100.110.120"
      "peer_type" = tostring(null)
      "source_interface" = tostring(null)
      "vrf" = "VRF1"
    }
    "default-5.6.7.8" = {
      "address_families" = tolist([
        {
          "address_family" = "ipv4_unicast"
          "route_reflector_client" = false
          "send_community_extended" = true
          "send_community_standard" = true
        },
        {
          "address_family" = "l2vpn_evpn"
          "route_reflector_client" = false
          "send_community_extended" = tobool(null)
          "send_community_standard" = true
        },
      ])
      "asn" = "65002"
      "description" = "My description"
      "inherit_peer" = tostring(null)
      "ip" = "5.6.7.8"
      "peer_type" = "fabric-external"
      "source_interface" = "lo2"
      "vrf" = "default"
    }
    "default-9.10.11.12" = {
      "address_families" = tolist(null)
      "asn" = tostring(null)
      "description" = "My description 2"
      "inherit_peer" = "SPINE-PEERS"
      "ip" = "9.10.11.12"
      "peer_type" = tostring(null)
      "source_interface" = tostring(null)
      "vrf" = "default"
    }
  }
  */

  neighbors_af_map = merge([
    for neighbor_key, neighbor in local.neighbors_map : {
      for af in neighbor.address_families : "${neighbor_key}-${af.address_family}" => merge(af, { "vrf" : neighbor.vrf, "ip" : neighbor.ip, "address_family" : local.address_family_names_map[af.address_family] })
    } if neighbor.address_families != null
  ]...)
  /*
  Example:
  {
    "default-5.6.7.8-ipv4_unicast" = {
      "address_family" = "ipv4-ucast"
      "ip" = "5.6.7.8"
      "route_reflector_client" = false
      "send_community_extended" = true
      "send_community_standard" = true
      "vrf" = "default"
    }
    "default-5.6.7.8-l2vpn_evpn" = {
      "address_family" = "l2vpn-evpn"
      "ip" = "5.6.7.8"
      "route_reflector_client" = false
      "send_community_extended" = tobool(null)
      "send_community_standard" = true
      "vrf" = "default"
    }
  }
  */
}

resource "nxos_bgp" "bgpEntity" {
  device      = var.device
  admin_state = "enabled"
}

resource "nxos_bgp_instance" "bgpInst" {
  device                  = var.device
  admin_state             = "enabled"
  asn                     = var.asn
  enhanced_error_handling = var.enhanced_error_handling

  depends_on = [
    nxos_bgp.bgpEntity
  ]
}

resource "nxos_bgp_vrf" "bgpDom" {
  for_each  = local.vrf_map
  device    = var.device
  asn       = var.asn
  name      = each.key
  router_id = each.value.router_id

  depends_on = [
    nxos_bgp_instance.bgpInst
  ]
}

resource "nxos_bgp_route_control" "bgpRtCtrl" {
  for_each             = local.vrf_map
  device               = var.device
  asn                  = var.asn
  vrf                  = each.key
  log_neighbor_changes = each.value.log_neighbor_changes == true ? "enabled" : "disabled"

  depends_on = [
    nxos_bgp_vrf.bgpDom
  ]
}

resource "nxos_bgp_graceful_restart" "bgpGr" {
  for_each         = local.vrf_map
  device           = var.device
  asn              = var.asn
  vrf              = each.key
  restart_interval = each.value.graceful_restart_restart_time
  stale_interval   = each.value.graceful_restart_stalepath_time

  depends_on = [
    nxos_bgp_vrf.bgpDom
  ]
}

resource "nxos_bgp_peer_template" "bgpPeerCont" {
  for_each         = local.template_peer_map
  device           = var.device
  asn              = var.asn
  template_name    = each.key
  remote_asn       = each.value.asn
  description      = each.value.description
  peer_type        = each.value.peer_type
  source_interface = each.value.source_interface

  depends_on = [
    nxos_bgp_vrf.bgpDom
  ]
}

resource "nxos_bgp_peer_template_address_family" "bgpPeerAf" {
  for_each                = local.template_peer_af_map
  device                  = var.device
  asn                     = var.asn
  template_name           = each.value.name
  address_family          = each.value.address_family
  control                 = each.value.route_reflector_client == true ? "rr-client" : ""
  send_community_extended = each.value.send_community_extended == true ? "enabled" : "disabled"
  send_community_standard = each.value.send_community_standard == true ? "enabled" : "disabled"

  depends_on = [
    nxos_bgp_peer_template.bgpPeerCont
  ]
}

resource "nxos_bgp_peer" "bgpPeer" {
  for_each         = local.neighbors_map
  device           = var.device
  asn              = var.asn
  vrf              = each.value.vrf
  address          = each.value.ip
  remote_asn       = each.value.asn
  description      = each.value.description
  peer_template    = each.value.inherit_peer
  peer_type        = each.value.peer_type
  source_interface = each.value.source_interface

  depends_on = [
    nxos_bgp_vrf.bgpDom
  ]
}

resource "nxos_bgp_peer_address_family" "bgpPeerAf" {
  for_each                = local.neighbors_af_map
  device                  = var.device
  asn                     = var.asn
  vrf                     = each.value.vrf
  address                 = each.value.ip
  address_family          = each.value.address_family
  control                 = each.value.route_reflector_client == true ? "rr-client" : ""
  send_community_extended = each.value.send_community_extended == true ? "enabled" : "disabled"
  send_community_standard = each.value.send_community_standard == true ? "enabled" : "disabled"

  depends_on = [
    nxos_bgp_peer.bgpPeer
  ]
}
