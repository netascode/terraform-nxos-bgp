variable "device" {
  description = "A device name from the provider configuration."
  type        = string
  default     = null
}

variable "asn" {
  description = "BGP Autonomous system number."
  type        = string

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.asn)) || can(regex("^\\d+$", var.asn))
    error_message = "`asn`: Allowed formats are: `1-4294967295` or `1-65535.0-65535`."
  }
}

variable "enhanced_error_handling" {
  description = "BGP Enhanced error handling."
  type        = bool
  default     = true
}

variable "template_peers" {
  description = <<EOT
  BGP Template Peers list.
  Choices `peer_type`: `fabric-internal`, `fabric-external`, `fabric-border-leaf`. Default value `peer_type`: `fabric-internal`.
  List `address_families`:
  Choices `address_family`: `ipv4_unicast`, `ipv6_unicast`.
  EOT
  type = list(object({
    name             = string
    asn              = optional(string)
    description      = optional(string, "")
    peer_type        = optional(string, "fabric-internal")
    source_interface = optional(string, "unspecified")
    address_families = optional(list(object({
      address_family          = string
      send_community_standard = optional(bool, false)
      send_community_extended = optional(bool, false)
      route_reflector_client  = optional(bool, false)
    })), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for v in var.template_peers : can(regex("^\\S+$", v.name))
    ])
    error_message = "`name`: Whitespaces are not allowed."
  }

  validation {
    condition = alltrue([
      for v in var.template_peers : can(regex("^\\d+\\.\\d+$", v.asn)) || can(regex("^\\d+$", v.asn)) || v.asn == null
    ])
    error_message = "`asn`: Allowed formats are: `1-4294967295` or `1-65535.0-65535`."
  }

  validation {
    condition = alltrue([
      for v in var.template_peers : can(regex("^.{0,254}$", v.description)) || v.description == null
    ])
    error_message = "`description`: Maximum characters: `254`."
  }

  validation {
    condition = alltrue([
      for v in var.template_peers : try(contains(["fabric-internal", "fabric-external", "fabric-border-leaf"], v.peer_type), v.peer_type == null)
    ])
    error_message = "`peer_type`: Allowed values are `fabric-internal`, `fabric-external` or `fabric-border-leaf`."
  }

  validation {
    condition = alltrue([
      for v in var.template_peers : can(regex("^\\S*$", v.source_interface)) || v.source_interface == null
    ])
    error_message = "`source_interface`: Whitespaces are not allowed. Must match first field in the output of `show int brief`. Example: `eth1/1`."
  }

  validation {
    condition = alltrue(flatten([
      for value in var.template_peers : value.address_families == null ? [true] : [
        for v in value.address_families : contains(["ipv4_unicast", "ipv6_unicast", "l2vpn_evpn"], v.address_family)
      ]
    ]))
    error_message = "`address_family`: Allowed values are `ipv4_unicast`, `ipv6_unicast` or `l2vpn_evpn`."
  }
}

variable "vrfs" {
  description = <<EOT
  BGP VRF list.
  List `neighbors`:
  Allowed formats `ip`: `192.168.1.1` or `192.168.1.0/24`.
  Choices `peer_type`: `fabric-internal`, `fabric-external`, `fabric-border-leaf`. Default value `peer_type`: `fabric-internal`.
  List `address_families`:
  Choices `address_family`: `ipv4_unicast`, `ipv6_unicast`, `l2vpn_evpn`.
  EOT
  type = list(object({
    vrf                             = string
    router_id                       = optional(string)
    log_neighbor_changes            = optional(bool, false)
    graceful_restart_stalepath_time = optional(number, 300)
    graceful_restart_restart_time   = optional(number, 120)
    neighbors = optional(list(object({
      ip               = string
      asn              = optional(string)
      inherit_peer     = optional(string, "")
      description      = optional(string, "")
      peer_type        = optional(string, "fabric-internal")
      source_interface = optional(string, "unspecified")
      address_families = optional(list(object({
        address_family          = string
        send_community_standard = optional(bool, false)
        send_community_extended = optional(bool, false)
        route_reflector_client  = optional(bool, false)
      })))
    })))
  }))
  default = []

  validation {
    condition = alltrue([
      for v in var.vrfs : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", v.router_id)) || v.router_id == null
    ])
    error_message = "`router_id`: Allowed formats are: `192.168.1.1`."
  }

  validation {
    condition = alltrue([
      for v in var.vrfs : try(v.graceful_restart_stalepath_time >= 1 && v.graceful_restart_stalepath_time <= 3600, v.graceful_restart_stalepath_time == null)
    ])
    error_message = "`graceful_restart_stalepath_time`: Minimum value: `1`. Maximum value: `3600`."
  }

  validation {
    condition = alltrue([
      for v in var.vrfs : try(v.graceful_restart_restart_time >= 1 && v.graceful_restart_restart_time <= 3600, v.graceful_restart_restart_time == null)
    ])
    error_message = "`graceful_restart_restart_time`: Minimum value: `1`. Maximum value: `3600`."
  }

  validation {
    condition = alltrue(flatten([
      for value in var.vrfs : value.neighbors == null ? [true] : [
        for v in value.neighbors : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", v.ip)) || can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+\\/\\d+$", v.ip))
      ]
    ]))
    error_message = "`ip`: Allowed formats are: `192.168.1.1` or `192.168.1.0/24`."
  }

  validation {
    condition = alltrue(flatten([
      for value in var.vrfs : value.neighbors == null ? [true] : [
        for v in value.neighbors : can(regex("^\\d+\\.\\d+$", v.asn)) || can(regex("^\\d+$", v.asn)) || v.asn == null
      ]
    ]))
    error_message = "`asn`: Allowed formats are: `1-4294967295` or `1-65535.0-65535`."
  }

  validation {
    condition = alltrue(flatten([
      for value in var.vrfs : value.neighbors == null ? [true] : [
        for v in value.neighbors : can(regex("^\\S+$", v.inherit_peer)) || v.inherit_peer == null
      ]
    ]))
    error_message = "`inherit_peer`: Whitespaces are not allowed."
  }

  validation {
    condition = alltrue(flatten([
      for value in var.vrfs : value.neighbors == null ? [true] : [
        for v in value.neighbors : can(regex("^.{0,254}$", v.description)) || v.description == null
      ]
    ]))
    error_message = "`description`: Maximum characters: `254`."
  }

  validation {
    condition = alltrue(flatten([
      for value in var.vrfs : value.neighbors == null ? [true] : [
        for v in value.neighbors : try(contains(["fabric-internal", "fabric-external", "fabric-border-leaf"], v.peer_type), v.peer_type == null, false)
      ]
    ]))
    error_message = "`peer_type`: Allowed values are `fabric-internal`, `fabric-external` or `fabric-border-leaf`."
  }

  validation {
    condition = alltrue(flatten([
      for value in var.vrfs : value.neighbors == null ? [true] : [
        for v in value.neighbors : can(regex("^\\S*$", v.source_interface)) || v.source_interface == null
      ]
    ]))
    error_message = "`source_interface`: Whitespaces are not allowed. Must match first field in the output of `show int brief`. Example: `eth1/1`."
  }

  validation {
    condition = alltrue(flatten([
      for value in var.vrfs : value.neighbors == null ? [true] : flatten([
        for neighbor_value in value.neighbors : neighbor_value.address_families == null ? [true] : [
          for v in neighbor_value.address_families : contains(["ipv4_unicast", "ipv6_unicast", "l2vpn_evpn"], v.address_family)
        ]
      ])
    ]))
    error_message = "`address_family`: Allowed map keys are `ipv4_unicast`, `ipv6_unicast` or `l2vpn_evpn`."
  }
}
