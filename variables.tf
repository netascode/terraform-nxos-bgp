variable "asn" {
  description = "BGP Autonomous system number."
  type        = string

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.asn)) || can(regex("^\\d+$", var.asn))
    error_message = "`asn`: Allowed formats: `1-4294967295` or `1-65535.0-65535`."
  }
}

variable "enhanced_error_handling" {
  description = "BGP Enhanced error handling."
  type        = bool
  default     = true
}

variable "template_peer" {
  description = "BGP template peers."
  type = map(object({
    asn              = optional(string)
    description      = optional(string)
    peer_type        = optional(string)
    source_interface = optional(string)
    address_family = optional(map(object({
      send_community_standard = optional(bool)
      send_community_extended = optional(bool)
      route_reflector_client  = optional(bool)
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.template_peer : can(regex("^\\S+$", k))
    ])
    error_message = "`template_peer`: Whitespaces are not allowed in map keys."
  }

  validation {
    condition = alltrue([
      for k, v in var.template_peer : can(regex("^\\d+\\.\\d+$", v.asn)) || can(regex("^\\d+$", v.asn)) || v.asn == null
    ])
    error_message = "`asn`: Allowed formats: `1-4294967295` or `1-65535.0-65535`."
  }

  validation {
    condition = alltrue([
      for k, v in var.template_peer : can(regex("^.{0,254}$", v.description)) || v.description == null
    ])
    error_message = "`description`: Maximum characters: `254`."
  }

  validation {
    condition = alltrue([
      for k, v in var.template_peer : try(contains(["fabric-internal", "fabric-external", "fabric-border-leaf"], v.peer_type), v.peer_type == null, false)
    ])
    error_message = "`peer_type`: Allowed values are `fabric-internal`, `fabric-external` or `fabric-border-leaf`."
  }

  validation {
    condition = alltrue([
      for k, v in var.template_peer : can(regex("^\\S*$", v.source_interface)) || v.source_interface == null
    ])
    error_message = "`source_interface`: Whitespaces are not allowed. Must match first field in the output of `show int brief`. Example: `eth1/1`."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.template_peer : value.address_family == null ? [true] : [
        for k, v in value.address_family : contains(["ipv4_unicast", "ipv6_unicast", "l2vpn_evpn"], k)
      ]
    ]))
    error_message = "`address_family`: Allowed map keys are `ipv4_unicast`, `ipv6_unicast` or `l2vpn_evpn`."
  }
}

variable "vrf" {
  description = "BGP VRFs."
  type = map(object({
    router_id                       = optional(string)
    log_neighbor_changes            = optional(bool)
    graseful_restart_stalepath_time = optional(number)
    graseful_restart_restart_time   = optional(number)
    neighbors = optional(map(object({
      asn              = optional(string)
      inherit_peer     = optional(string)
      description      = optional(string)
      peer_type        = optional(string)
      source_interface = optional(string)
      address_family = optional(map(object({
        send_community_standard = optional(bool)
        send_community_extended = optional(bool)
        route_reflector_client  = optional(bool)
      })))
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vrf : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", v.router_id)) || v.router_id == null
    ])
    error_message = "`router_id`: Allowed formats: `192.168.1.1`."
  }

  validation {
    condition = alltrue([
      for k, v in var.vrf : try(v.graseful_restart_stalepath_time >= 1 && v.graseful_restart_stalepath_time <= 3600, v.graseful_restart_stalepath_time == null)
    ])
    error_message = "`graseful_restart_stalepath_time`: Minimum value: `1`. Maximum value: `3600`."
  }

  validation {
    condition = alltrue([
      for k, v in var.vrf : try(v.graseful_restart_restart_time >= 1 && v.graseful_restart_restart_time <= 3600, v.graseful_restart_restart_time == null)
    ])
    error_message = "`graseful_restart_restart_time`: Minimum value: `1`. Maximum value: `3600`."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.vrf : value.neighbors == null ? [true] : [
        for k, v in value.neighbors : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", k)) || can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+\\/\\d+$", k))
      ]
    ]))
    error_message = "`neighbors`: Map keys allowed format: `192.168.1.1` or `192.168.1.0/24`."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.vrf : value.neighbors == null ? [true] : [
        for k, v in value.neighbors : can(regex("^\\d+\\.\\d+$", v.asn)) || can(regex("^\\d+$", v.asn)) || v.asn == null
      ]
    ]))
    error_message = "`asn`: Allowed formats: `1-4294967295` or `1-65535.0-65535`."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.vrf : value.neighbors == null ? [true] : [
        for k, v in value.neighbors : can(regex("^\\S+$", v.inherit_peer)) || v.inherit_peer == null
      ]
    ]))
    error_message = "`inherit_peer`: Whitespaces are not allowed."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.vrf : value.neighbors == null ? [true] : [
        for k, v in value.neighbors : can(regex("^.{0,254}$", v.description)) || v.description == null
      ]
    ]))
    error_message = "`description`: Maximum characters: `254`."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.vrf : value.neighbors == null ? [true] : [
        for k, v in value.neighbors : try(contains(["fabric-internal", "fabric-external", "fabric-border-leaf"], v.peer_type), v.peer_type == null, false)
      ]
    ]))
    error_message = "`peer_type`: Allowed values are `fabric-internal`, `fabric-external` or `fabric-border-leaf`."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.vrf : value.neighbors == null ? [true] : [
        for k, v in value.neighbors : can(regex("^\\S*$", v.source_interface)) || v.source_interface == null
      ]
    ]))
    error_message = "`source_interface`: Whitespaces are not allowed. Must match first field in the output of `show int brief`. Example: `eth1/1`."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.vrf : value.neighbors == null ? [true] : flatten([
        for neighbor_key, neighbor_value in value.neighbors : neighbor_value.address_family == null ? [true] : [
          for k, v in neighbor_value.address_family : contains(["ipv4_unicast", "ipv6_unicast", "l2vpn_evpn"], k)
        ]
      ])
    ]))
    error_message = "`address_family`: Allowed map keys are `ipv4_unicast`, `ipv6_unicast` or `l2vpn_evpn`."
  }
}
