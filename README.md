# VLAN over LACP
This is a sample of the article [Open vSwitch + Libvirt で VLAN over LACP (802.3ad) による VM 間通信 - Qiita](https://qiita.com/sawa2d2/items/206dfc2ebe8828be014b).

![](https://raw.githubusercontent.com/wiki/sawa2d2/vlan-over-lacp/images/overview.drawio.png)

## Create an OVS bridge
Create an OVS bridge:
```
sudo ovs-vsctl add-br ovsbr0
```

## Create VMs
Download a Rocky 9.5 `qcow2` image for VMs:
```
$ sudo curl -L -o /var/lib/libvirt/images/Rocky-9-GenericCloud.latest.x86_64.qcow2 https://download.rockylinux.org/pub/rocky/9.2/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2 
```

Provision VMs using terraform:
```
$ terraform init --upgrade
$ terraform apply --auto-approve
```

## Configuring bonds

Delete ports that automatically created by libvirt and then create new bonds:
```
# Delete the existing ports
sudo ovs-vsctl del-port ovsbr0 tap1p1
sudo ovs-vsctl del-port ovsbr0 tap1p2
sudo ovs-vsctl del-port ovsbr0 tap2p1
sudo ovs-vsctl del-port ovsbr0 tap2p2

# Creating new bonds
# 1. Set each LACP port to active mode
# 2. Set each bond as balance-tcp mode
# 3. Accelerate LACP negotiation by setting it to fast mode
# 4. Use layer2+3 policy
# 5. Configure the bond to allow VLAN trunking for VLANs
sudo ovs-vsctl add-bond ovsbr0 bond-vm1 tap1p1 tap1p2 \
	-- set port bond-vm1 \
	lacp=active \
	bond_mode=balance-tcp \
	other_config:lacp-time=fast \
	other_config:bond-hash-policy=layer2+3 \
	trunks=10,20
sudo ovs-vsctl add-bond ovsbr0 bond-vm2 tap2p1 tap2p2 \
	-- set port bond-vm2 \
	lacp=active \
	bond_mode=balance-tcp \
	other_config:lacp-time=fast \
	other_config:bond-hash-policy=layer2+3 \
```

## (Optional) Enable NAT on a host
Enable IP forwarding on the host:
```
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -p
```

Enable masquerading on the host:
```
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload
```

## (Optional) Ensure VMs can connect to the internet
Set a gateway as the host `10.0.10.100` and DNSs on the VMs:
```
$ sudo nmcli con mod bond0.10 ipv4.gateway 10.0.10.100 ipv4.dns "8.8.4.4 8.8.8.8"
```

## (Optional) Cleanup
Delete the bonds:
```
$ sudo ovs-vsctl del-port ovsbr0 bond-vm1
$ sudo ovs-vsctl del-port ovsbr0 bond-vm2
```

Delete the OVS bridge:
```
$ sudo ovs-vsctl del-br ovsbr0
```

Delete the VMs:
```
$ terraform destroy
```

Disable NAT on the host:
```
$ ip route del 10.0.10.0/24 dev ovsbr0
$ echo 0 > /proc/sys/net/ipv4/ip_forward
$ firewall-cmd --permanent --remove-masquerade
```
