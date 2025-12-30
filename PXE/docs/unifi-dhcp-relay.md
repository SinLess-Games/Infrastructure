# UniFi considerations

If UniFi is not doing DHCP, you may still need it to do one of:
- VLAN trunking to the PXE host (so the PXE host can be L3-present on each VLAN), or
- DHCP relay (if supported on your gateway model/firmware) to the PXE host

If your gateway cannot relay DHCP, Option A (trunk + subinterfaces) is the usual approach.
