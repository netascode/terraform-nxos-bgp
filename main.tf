locals {
  address_family_names_map = {
    "ipv4_unicast" : "ipv4-ucast"
    "ipv6_unicast" : "ipv6-ucast"
    "l2vpn_evpn" : "l2vpn-evpn"
  }
  template_peers_af_map = merge([
    for template_name, template in var.template_peers : {
      for af_name, af in template.address_families : "${template_name}-${af_name}" => merge(af, { "template_name" : template_name, "address_family" : local.address_family_names_map[af_name] })
    } if template.address_families != null
  ]...)
  /* Example:
  {
    "SPINE-PEERS-ipv4_unicast" = {
      "address_family" = "ipv4-ucast"
      "route_reflector_client" = true
      "send_community_extended" = tobool(null)
      "send_community_standard" = true
      "template_name" = "SPINE-PEERS"
    }
    "SPINE-PEERS-l2vpn_evpn" = {
      "address_family" = "l2vpn-evpn"
      "route_reflector_client" = true
      "send_community_extended" = tobool(null)
      "send_community_standard" = true
      "template_name" = "SPINE-PEERS"
    }
  }
  */

  neighbors_map = merge([
    for vrf_name, vrf in var.vrfs : {
      for neighbor_ip, neighbor in vrf.neighbors : "${vrf_name}-${neighbor_ip}" => merge(neighbor, { "vrf_name" : vrf_name, "address" : neighbor_ip })
    }
  ]...)
  /* Example:
  {
    "VRF1-50.60.70.80" = {
      "address" = "50.60.70.80"
      "address_families" = tomap(null)
      "asn" = tostring(null)
      "description" = "My description"
      "inherit_peer" = tostring(null)
      "peer_type" = tostring(null)
      "source_interface" = tostring(null)
      "vrf_name" = "VRF1"
    }
    "default-5.6.7.8" = {
      "address" = "5.6.7.8"
      "address_families" = tomap({
        "ipv4_unicast" = {
          "route_reflector_client" = false
          "send_community_extended" = true
          "send_community_standard" = true
        }
        "l2vpn_evpn" = {
          "route_reflector_client" = false
          "send_community_extended" = tobool(null)
          "send_community_standard" = true
        }
      })
      "asn" = "65002"
      "description" = "My description"
      "inherit_peer" = tostring(null)
      "peer_type" = "fabric-external"
      "source_interface" = "lo2"
      "vrf_name" = "default"
  }
  */

  neighbors_af_map = merge([
    for neighbor_key, neighbor in local.neighbors_map : {
      for af_name, af in neighbor.address_families : "${neighbor_key}-${af_name}" => merge(af, { "vrf_name" : neighbor.vrf_name, "address" : neighbor.address, "address_family" : local.address_family_names_map[af_name] })
    } if neighbor.address_families != null
  ]...)
  /*
  Example:
  {
    "default-5.6.7.8-ipv4_unicast" = {
      "address" = "5.6.7.8"
      "address_family" = "ipv4-ucast"
      "route_reflector_client" = false
      "send_community_extended" = true
      "send_community_standard" = true
      "vrf_name" = "default"
    }
    "default-5.6.7.8-l2vpn_evpn" = {
      "address" = "5.6.7.8"
      "address_family" = "l2vpn-evpn"
      "route_reflector_client" = false
      "send_community_extended" = tobool(null)
      "send_community_standard" = true
      "vrf_name" = "default"
    }
  }
  */
}

resource "nxos_bgp" "bgpEntity" {
  admin_state = "enabled"
}

resource "nxos_bgp_instance" "bgpInst" {
  admin_state             = "enabled"
  asn                     = var.asn
  enhanced_error_handling = var.enhanced_error_handling == true ? "yes" : "no"
  depends_on = [
    nxos_bgp.bgpEntity
  ]
}

resource "nxos_bgp_vrf" "bgpDom" {
  for_each  = var.vrfs
  name      = each.key
  router_id = each.value.router_id
  depends_on = [
    nxos_bgp_instance.bgpInst
  ]
}

resource "nxos_bgp_route_control" "bgpRtCtrl" {
  for_each             = var.vrfs
  vrf                  = each.key
  log_neighbor_changes = each.value.log_neighbor_changes == true ? "enabled" : "disabled"
  depends_on = [
    nxos_bgp_vrf.bgpDom
  ]
}

resource "nxos_bgp_graceful_restart" "bgpGr" {
  for_each         = var.vrfs
  vrf              = each.key
  restart_interval = each.value.graseful_restart_restart_time != null ? each.value.graseful_restart_restart_time : 120
  stale_interval   = each.value.graseful_restart_stalepath_time != null ? each.value.graseful_restart_stalepath_time : 300
  depends_on = [
    nxos_bgp_vrf.bgpDom
  ]
}

resource "nxos_bgp_peer_template" "bgpPeerCont" {
  for_each         = var.template_peers
  template_name    = each.key
  asn              = each.value.asn
  description      = each.value.description != null ? each.value.description : ""
  peer_type        = each.value.peer_type != null ? each.value.peer_type : "fabric-internal"
  source_interface = each.value.source_interface != null ? each.value.source_interface : "unspecified"
  depends_on = [
    nxos_bgp_vrf.bgpDom
  ]
}

resource "nxos_bgp_peer_template_address_family" "bgpPeerAf" {
  for_each                = local.template_peers_af_map
  template_name           = each.value.template_name
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
  vrf              = each.value.vrf_name
  address          = each.value.address
  asn              = each.value.asn
  description      = each.value.description != null ? each.value.description : ""
  peer_template    = each.value.inherit_peer != null ? each.value.inherit_peer : ""
  peer_type        = each.value.peer_type != null ? each.value.peer_type : "fabric-internal"
  source_interface = each.value.source_interface != null ? each.value.source_interface : "unspecified"
  depends_on = [
    nxos_bgp_vrf.bgpDom
  ]
}

resource "nxos_bgp_peer_address_family" "bgpPeerAf" {
  for_each                = local.neighbors_af_map
  vrf                     = each.value.vrf_name
  address                 = each.value.address
  address_family          = each.value.address_family
  control                 = each.value.route_reflector_client == true ? "rr-client" : ""
  send_community_extended = each.value.send_community_extended == true ? "enabled" : "disabled"
  send_community_standard = each.value.send_community_standard == true ? "enabled" : "disabled"
  depends_on = [
    nxos_bgp_peer.bgpPeer
  ]
}
