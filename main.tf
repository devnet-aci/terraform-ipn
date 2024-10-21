terraform {
  required_providers {
    nxos = {
      source = "CiscoDevNet/nxos"
      version = "0.5.0"
    }
  }
}

provider "nxos" {
  username = var.user.username
  password = var.user.password
  url      = var.user.url
  #Testado e validado no OpenNXOS da Cisco
}


 ###################################################
 ################## FEATURES #######################

resource "nxos_feature_lldp" "feature_lldp" {
  admin_state = var.status
}
resource "nxos_feature_ospf" "feature_ospf" {
  admin_state = var.status
}
resource "nxos_feature_pim" "feature_pim" {
  admin_state = var.status
}
resource "nxos_feature_dhcp" "feature_dhcp" {
  admin_state = var.status
}

 ##############################################
 ################## vRF #######################

resource "nxos_vrf" "vRF" {
  name        = var.vRF
  description = var.vRF
}

 ##################################################################
 ################## INTERFACES PARA O SPINE #######################

resource "nxos_physical_interface" "l3_interface01_to_spine" {
  interface_id             = var.int_to_spine_01
  layer                    = var.l3
  mtu                      = var.mtu
}
resource "nxos_physical_interface" "l3_interface02_to_spine" {
  interface_id             = var.int_to_spine_02
  layer                    = var.l3
  mtu                      = var.mtu
}
#Associando as interfaces a vRF
resource "nxos_physical_interface_vrf" "vrf_interface01_to_spine" {
  depends_on = [ nxos_vrf.vRF ]
  interface_id = var.int_to_spine_01
  vrf_dn       = var.vRF_path
}
resource "nxos_physical_interface_vrf" "vrf_interface02_to_spine" {
  depends_on = [ nxos_vrf.vRF ]
  interface_id = var.int_to_spine_02
  vrf_dn       = var.vRF_path
}

#Criando sub-interfaces
resource "nxos_subinterface" "subinterface01_to_spine" {
  depends_on = [ nxos_physical_interface.l3_interface01_to_spine ]
  interface_id = var.subint_to_spine_01
  admin_state  = var.up
  mtu          = var.mtu
  description  = var.description_interface01
  encap        = var.encap_vlan4
}
resource "nxos_subinterface" "subinterface02_to_spine" {
  depends_on = [ nxos_physical_interface.l3_interface02_to_spine ]
  interface_id = var.subint_to_spine_02
  admin_state  = var.up
  mtu          = var.mtu
  description  = var.description_interface02
  encap        = var.encap_vlan4
}

#Associando as sub-interfaces a vRF

resource "nxos_subinterface_vrf" "vrf_subinterface02_to_spine" {
  depends_on = [ nxos_subinterface.subinterface01_to_spine ]
  interface_id = var.subint_to_spine_01
  vrf_dn       = var.vRF_path
}
resource "nxos_subinterface_vrf" "vrf_subinterface01_to_spine" {
  depends_on = [ nxos_subinterface.subinterface02_to_spine ]
  interface_id = var.subint_to_spine_02
  vrf_dn       = var.vRF_path
}


resource "nxos_ipv4_interface" "ipv4_subinterface01" {
  depends_on = [ nxos_subinterface_vrf.vrf_subinterface01_to_spine ]
  vrf          = var.vRF
  interface_id = var.subint_to_spine_01
}
resource "nxos_ipv4_interface" "ipv4_subinterface02" {
  depends_on = [ nxos_subinterface_vrf.vrf_subinterface02_to_spine ]
  vrf          = var.vRF
  interface_id = var.subint_to_spine_02
}

#Colocando IPv4 nas sub-interfaces
resource "nxos_ipv4_interface_address" "ip_subinterface01_to_spine_associate" {
  depends_on = [ nxos_ipv4_interface.ipv4_subinterface01 ]
  vrf          = var.vRF
  interface_id = var.subint_to_spine_01
  address      = var.IP_subint_to_spine_01
}
resource "nxos_ipv4_interface_address" "ip_subinterface02_to_spine_associate" {
  depends_on = [ nxos_ipv4_interface.ipv4_subinterface02 ]
  vrf          = var.vRF
  interface_id = var.subint_to_spine_02
  address      = var.IP_subint_to_spine_02
}
 ###############################################
 ################## OSPF #######################

resource "nxos_ospf" "ospf" {
  admin_state = var.status
}
resource "nxos_ospf_instance" "ospf_instance" {
  depends_on = [ nxos_ospf.ospf ]
  admin_state = var.status
  name        = var.vRF
}
resource "nxos_ospf_vrf" "ospf_vrf" {
  depends_on = [ nxos_ospf_instance.ospf_instance ]
  instance_name           = var.vRF
  name                    = var.vRF
  router_id               = var.rid_ospf
}
resource "nxos_ospf_interface" "ospf_subinterface02" {
   depends_on = [ nxos_ospf_vrf.ospf_vrf ]
   instance_name         = var.vRF
   vrf_name              = var.vRF
   interface_id          = var.subint_to_spine_01
   area                  = var.area_ospf
   network_type          = var.p2p_ospf
}
resource "nxos_ospf_interface" "ospf_subinterface01" {
   depends_on = [ nxos_ospf_interface.ospf_subinterface02 ]
   instance_name         = var.vRF
   vrf_name              = var.vRF
   interface_id          = var.subint_to_spine_02
   area                  = var.area_ospf
   network_type          = var.p2p_ospf
}
 #####################################################
 ################## DHCP RELAY #######################

resource "nxos_dhcp_relay_interface" "dhcp_relay_int01" {
  depends_on = [ nxos_ipv4_interface.ipv4_subinterface01 ]
  interface_id = var.subint_to_spine_01
}
resource "nxos_dhcp_relay_interface" "dhcp_relay_int02" {
  depends_on = [ nxos_ipv4_interface.ipv4_subinterface02 ]
  interface_id = var.subint_to_spine_02
}
resource "nxos_dhcp_relay_address" "sub01_dhcp_relay_01" {
  depends_on = [ nxos_dhcp_relay_interface.dhcp_relay_int01 ]
  interface_id = var.subint_to_spine_01
  vrf          = var.vRF
  address      = var.dhcp_relay01
}
resource "nxos_dhcp_relay_address" "sub01_dhcp_relay_02" {
  depends_on = [ nxos_dhcp_relay_address.sub01_dhcp_relay_01 ]
  interface_id = var.subint_to_spine_01
  vrf          = var.vRF
  address      = var.dhcp_relay02
}
resource "nxos_dhcp_relay_address" "sub01_dhcp_relay_03" {
  depends_on = [ nxos_dhcp_relay_address.sub01_dhcp_relay_02 ]
  interface_id = var.subint_to_spine_01
  vrf          = var.vRF
  address      = var.dhcp_relay03
}
resource "nxos_dhcp_relay_address" "sub02_dhcp_relay_01" {
  depends_on	= [ nxos_dhcp_relay_address.sub01_dhcp_relay_03 ]
  interface_id = var.subint_to_spine_02
  vrf          = var.vRF
  address      = var.dhcp_relay01
}
resource "nxos_dhcp_relay_address" "sub02_dhcp_relay_02" {
  depends_on = [ nxos_dhcp_relay_address.sub02_dhcp_relay_01 ]
  interface_id = var.subint_to_spine_02
  vrf          = var.vRF
  address      = var.dhcp_relay02
}
resource "nxos_dhcp_relay_address" "sub02_dhcp_relay_03" {
  depends_on = [ nxos_dhcp_relay_address.sub02_dhcp_relay_02 ]
  interface_id = var.subint_to_spine_02
  vrf          = var.vRF
  address      = var.dhcp_relay03
}
 ##############################################
 ################## PIM #######################

resource "nxos_pim" "pim" {
  admin_state = var.status
}
resource "nxos_pim_instance" "pim_instance" {
  depends_on = [ nxos_pim.pim]
  admin_state = var.status
}
resource "nxos_pim_vrf" "pim_vrf" {
  depends_on = [nxos_pim_instance.pim_instance]
  name        = var.vRF
  admin_state = var.status
  bfd         = false
}
resource "nxos_pim_static_rp_policy" "pim_rp" {
  depends_on = [ nxos_pim_vrf.pim_vrf]
  vrf_name = var.vRF
  name     = var.rp_name
}
resource "nxos_pim_static_rp" "pim_static_rp" {
  depends_on = [ nxos_pim_static_rp_policy.pim_rp ]
  vrf_name = var.vRF
  address  = var.ip_loopback
}
resource "nxos_pim_static_rp_group_list" "pim_rp_grp1" {
  depends_on = [ nxos_pim_static_rp.pim_static_rp ]
  vrf_name   = var.vRF
  rp_address = var.ip_loopback
  address    = var.GiPo
  bidir      = true
  override   = false
}
resource "nxos_pim_static_rp_group_list" "pim_rp_grp2" {
  depends_on = [ nxos_pim_static_rp.pim_static_rp ]
  vrf_name   = var.vRF
  rp_address = var.ip_loopback
  address    = var.rp_address
  bidir      = true
  override   = false
}
resource "nxos_pim_interface" "pim_subint01" {
  depends_on = [ nxos_pim_static_rp_group_list.pim_rp_grp2 ]
  vrf_name     = var.vRF
  interface_id = var.subint_to_spine_01
  admin_state  = var.status
  bfd          = var.disabled
  sparse_mode  = true
}
resource "nxos_pim_interface" "pim_subint02" {
  depends_on = [ nxos_pim_interface.pim_subint01 ]
  vrf_name     = var.vRF
  interface_id = var.subint_to_spine_02
  admin_state  = var.status
  bfd          = var.disabled
  sparse_mode  = true
}
 ###################################################
 ################## LOOPBACK #######################

resource "nxos_loopback_interface" "loopback" {
  interface_id = var.loopback
  admin_state  = var.up
}
resource "nxos_loopback_interface_vrf" "loopback_vrf" {
  depends_on = [ nxos_loopback_interface.loopback ]
  interface_id = var.loopback
  vrf_dn       = var.vRF_path
}
resource "nxos_ipv4_interface" "vrf_loopback" {
  depends_on = [ nxos_loopback_interface_vrf.loopback_vrf ]
  vrf          = var.vRF
  interface_id = var.loopback
}
resource "nxos_ipv4_interface_address" "ip_loopback" {
  depends_on = [ nxos_ipv4_interface.vrf_loopback ]
 vrf          = var.vRF
 interface_id = var.loopback
 address      = var.ip_loopback
}
resource "nxos_ospf_interface" "ospf_loopback" {
  depends_on = [ nxos_ipv4_interface_address.ip_loopback ]
   instance_name         = var.vRF
   vrf_name              = var.vRF
   interface_id          = var.loopback
   area                  = var.rid_ospf
   network_type          = var.p2p_ospf
}
resource "nxos_pim_interface" "rp-phanton" {
  depends_on = [ nxos_ospf_interface.ospf_loopback ]
  vrf_name     = var.vRF
  interface_id = var.loopback
  admin_state  = var.status
  bfd          = var.disabled
  sparse_mode  = true
}

 ###################################################
 ################## LINK WAN #######################

resource "nxos_physical_interface" "interface01_wan" {
  interface_id             = var.int_wan_01
  layer                    = var.l3
  mtu                      = var.mtu
}
resource "nxos_physical_interface" "interface02_wan" {
  interface_id             = var.int_wan_02
  layer                    = var.l3
  mtu                      = var.mtu
}
resource "nxos_physical_interface_vrf" "vrf_interface01_wan" {
  depends_on = [ nxos_physical_interface.interface01_wan ]
  interface_id = var.int_wan_01
  vrf_dn       = var.vRF_path
}

resource "nxos_physical_interface_vrf" "vrf_interface02_wan" {
  depends_on = [ nxos_physical_interface.interface02_wan ]
  interface_id = var.int_wan_02
  vrf_dn       = var.vRF_path
}

resource "nxos_pim_interface" "pim_interface01_wan" {
  depends_on = [ nxos_physical_interface_vrf.vrf_interface01_wan ]
  vrf_name     = var.vRF
  interface_id = var.int_wan_01
  admin_state  = var.status
  bfd          = var.disabled
  sparse_mode  = true
}

resource "nxos_ipv4_interface" "interface01_wan_vrf" {
  depends_on = [ nxos_pim_interface.pim_interface01_wan ]
  vrf          = var.vRF
  interface_id = var.int_wan_01
}
resource "nxos_ipv4_interface_address" "ip_interface01_wan" {
  depends_on = [ nxos_ipv4_interface.interface01_wan_vrf ]
  vrf          = var.vRF
  interface_id = var.int_wan_01
  address      = var.ip_int_wan_01
}
resource "nxos_ospf_interface" "ospf_interface01_wan" {
   depends_on = [ nxos_ipv4_interface_address.ip_interface01_wan ]
   instance_name         = var.vRF
   vrf_name              = var.vRF
   interface_id          = var.int_wan_01
   area                  = var.area_ospf
   network_type          = var.p2p_ospf
}

resource "nxos_pim_interface" "pim_interface02_wan" {
  depends_on = [ nxos_ospf_interface.ospf_interface01_wan ]
  vrf_name     = var.vRF
  interface_id = var.int_wan_02
  admin_state  = var.status
  bfd          = var.disabled
  sparse_mode  = true
}

resource "nxos_ipv4_interface" "interface02_wan_vrf" {
  depends_on = [ nxos_pim_interface.pim_interface02_wan ]
  vrf          = var.vRF
  interface_id = var.int_wan_02
}
resource "nxos_ipv4_interface_address" "ip_interface02_wan" {
  depends_on = [ nxos_ipv4_interface.interface02_wan_vrf ]
  vrf          = var.vRF
  interface_id = var.int_wan_02
  address      = var.ip_int_wan_02
}
resource "nxos_ospf_interface" "ospf_interface02_wan" {
   depends_on = [ nxos_ipv4_interface_address.ip_interface02_wan ]
   instance_name         = var.vRF
   vrf_name              = var.vRF
   interface_id          = var.int_wan_02
   area                  = var.area_ospf
   network_type          = var.p2p_ospf
}

#by Freitas
