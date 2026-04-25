# Items and Prices

This document tracks the budget shopping list for the rack build.

Primary source preference is **eBay**. Prices are estimated from current listings and should be treated as **pre-tax, pre-shipping, and availability-sensitive**.

The target is to keep the initial purchase plan under **$5,000** while still building toward the full rack plan.

---

## Budget Summary

| Plan | Estimated Total | Notes |
|---|---:|---|
| Buy-now under-$5K plan | `$4,903.15` | Uses existing UniFi 8-port SFP+ aggregation switch for Phase 1 |
| Deferred full network/storage upgrades | Not included | Adds larger UniFi aggregation, gateway refresh, 48-port PoE refresh, and full disk fill |
| Initial raw disk capacity | `70TB raw` | 7 × 10TB SAS drives |
| Full shelf raw capacity later | `240TB raw` | 24 × 10TB SAS drives |
| Additional drives needed later | 17 drives | 17 × 10TB SAS drives |

---

## Buy-Now Plan Under $5K

This list keeps the initial build under budget while still getting:

- Five total Dell R710 servers
- Max CPU target counted and priced
- Max RAM target counted and priced
- iDRAC6 Enterprise cards for all servers
- 10Gb SFP+ NICs for all servers
- Disk shelf installed
- 70TB raw starting storage
- UPS and PDU expansion
- Raspberry Pi rack shelf with four Raspberry Pi nodes
- Required SFP+, SAS, RJ45, and power cabling

> Phase 1 uses the existing UniFi 8-port SFP+ aggregation switch. That gives each server one 10Gb SFP+ uplink plus uplink capacity. Dual 10Gb per server requires a larger aggregation switch and is listed in the deferred upgrades section.

---

## Buy-Now Shopping Table

| Category | Item | Qty | Unit Price | Line Total | Link | Notes |
|---|---|---:|---:|---:|---|---|
| Servers | Dell PowerEdge R710 server | 3 | `$74.95` | `$224.85` | [eBay](https://www.ebay.com/itm/167942888241) | You already have 2; this adds 3 more |
| Rails | Dell 2U ReadyRails / R710-compatible rail kit | 5 | `$24.95` | `$124.75` | [eBay](https://www.ebay.com/itm/257307487731) | Buy fewer if any servers already include rails |
| Network cards | Lot of 4 Intel X520-DA2 dual-port 10Gb SFP+ NICs | 1 | `$69.99` | `$69.99` | [eBay](https://www.ebay.com/itm/137203582783) | Covers 4 servers |
| Network cards | Intel X520-DA2 dual-port 10Gb SFP+ NIC | 1 | `$19.49` | `$19.49` | [eBay](https://www.ebay.com/itm/267581934543) | Fifth NIC |
| iDRAC | Dell iDRAC6 Enterprise card for R710 | 5 | `$5.00` | `$25.00` | [eBay](https://www.ebay.com/itm/316849877329) | Verify listing includes the Enterprise module and dedicated port hardware |
| CPU | Matching pair Intel Xeon X5680 CPUs | 5 | `$22.80` | `$114.00` | [eBay](https://www.ebay.com/itm/358092250464) | Verify selected variant is X5680 before purchase |
| RAM | 16GB DDR3 ECC Registered RDIMM | 90 | `$12.97` | `$1,167.30` | [eBay](https://www.ebay.com/itm/137223844466) | 18 DIMMs per server × 5 servers |
| Storage shelf | NetApp DS4243 / DS4246 24-bay disk shelf | 1 | `$359.99` | `$359.99` | [eBay](https://www.ebay.com/itm/257410390518) | Verify trays, controllers, PSUs, rails, and IOM modules |
| Storage HBA | LSI SAS9300-8E external SAS HBA | 1 | `$25.95` | `$25.95` | [eBay](https://www.ebay.com/itm/204809441705) | External SAS HBA for disk shelf host |
| SAS cables | External Mini-SAS cable | 2 | `$22.00` | `$44.00` | [eBay](https://www.ebay.com/itm/205030955651) | Match HBA and shelf connector type before purchase |
| Hard drives | Dell / WD 10TB SAS 3.5-inch 12Gbps HDD | 7 | `$199.00` | `$1,393.00` | [eBay](https://www.ebay.com/itm/196522699838) | 70TB raw starting pool |
| UPS | APC Smart-UPS 3000VA rackmount UPS | 1 | `$500.00` | `$500.00` | [eBay](https://www.ebay.com/itm/405806157708) | Verify batteries, rails, input plug, and output connectors |
| Power | 0U rack PDU, 12 × C13 outlets | 2 | `$39.95` | `$79.90` | [eBay](https://www.ebay.com/itm/266859166115) | A-side and B-side rack power |
| Raspberry Pi | Raspberry Pi 4 Model B kit | 4 | `$67.99` | `$271.96` | [eBay](https://www.ebay.com/itm/389372317583) | Verify RAM size and kit contents |
| Raspberry Pi | UCTRONICS 1U Raspberry Pi rackmount shelf | 1 | `$60.00` | `$60.00` | [eBay](https://www.ebay.com/itm/389356456554) | Rackmount for 4 Pis |
| Raspberry Pi power | Raspberry Pi USB-C power supply | 4 | `$9.99` | `$39.96` | [eBay](https://www.ebay.com/itm/134503542601) | One per Pi |
| Raspberry Pi storage | SanDisk 256GB microSD card | 4 | `$25.99` | `$103.96` | [eBay](https://www.ebay.com/itm/227303273420) | One per Pi |
| SFP+ cabling | Lot of 15 10Gtek 2m SFP+ DAC cables | 1 | `$85.00` | `$85.00` | [eBay](https://www.ebay.com/itm/405650586398) | Covers server uplinks and spares |
| RJ45 cabling | Cat6A patch cable bundle | 1 | `$58.88` | `$58.88` | [eBay](https://www.ebay.com/itm/180874463263) | Patch panel and switch patching |
| RJ45 cabling | 3-pack Cat6 3ft patch cables | 2 | `$10.49` | `$20.98` | [eBay](https://www.ebay.com/itm/397701458275) | iDRAC and management cabling |
| Power cables | 15-pack 6ft C14-to-C13 power cords | 1 | `$65.98` | `$65.98` | [eBay](https://www.ebay.com/itm/115055585346) | Server, shelf, UPS/PDU power wiring |
| Thermal paste | Arctic MX-4 thermal paste | 1 | `$8.21` | `$8.21` | [eBay](https://www.ebay.com/itm/394670604714) | CPU upgrades |
| Cable management | 1U brush cable manager | 2 | `$19.41` | `$38.82` | [eBay](https://www.ebay.com/itm/372673453144) | Front and rear cable control |

## Buy-Now Total

| Total Type | Amount |
|---|---:|
| Estimated subtotal | `$4,903.15` |
| Budget target | `$5,000.00` |
| Remaining before tax/shipping | `$96.85` |

---

## Storage Capacity Plan

### Initial Under-$5K Storage

| Item | Count | Capacity Each | Raw Capacity |
|---|---:|---:|---:|
| 10TB SAS drives | 7 | 10TB | 70TB raw |

### Full Shelf Later

| Item | Count | Capacity Each | Raw Capacity |
|---|---:|---:|---:|
| 10TB SAS drives | 24 | 10TB | 240TB raw |

### Remaining Drive Fill

| Item | Count Needed Later | Unit Price | Future Cost |
|---|---:|---:|---:|
| Additional 10TB SAS drives | 17 | `$199.00` | `$3,383.00` |

### Alternative High-Capacity Drive Lot

| Option | Raw Capacity | Price | Link | Notes |
|---|---:|---:|---|---|
| Lot of 24 × 12TB SAS drives | 288TB raw | `$4,296.00` | [eBay](https://www.ebay.com/itm/327012427591) | Too expensive for the under-$5K phase by itself |
| Single 12TB SAS drive | 12TB raw | `$249.00` | [eBay](https://www.ebay.com/itm/195839008532) | Good later upgrade if 12TB pricing drops |
| Single 10TB SAS drive | 10TB raw | `$199.00` | [eBay](https://www.ebay.com/itm/196522699838) | Best current budget fit |

Recommended storage decision:

```text
Buy 7 × 10TB SAS drives now.
Fill the remaining 17 bays later with matching 10TB SAS drives or move to 12TB+ drives if prices drop.
```

---

## Max CPU and RAM Count

This is the full target for all five Dell R710 servers.

### CPU Count

| Item | Per Server | Server Count | Total Needed |
|---|---:|---:|---:|
| Intel Xeon X5680 CPUs | 2 | 5 | 10 |
| CPU pairs | 1 | 5 | 5 pairs |
| Physical cores | 12 | 5 | 60 cores |
| Threads | 24 | 5 | 120 threads |

### RAM Count

| Item | Per Server | Server Count | Total Needed |
|---|---:|---:|---:|
| 16GB DDR3 ECC Registered RDIMMs | 18 | 5 | 90 DIMMs |
| RAM per server | 288GB | 5 | 1,440GB |
| Total RAM in TiB | ~0.281TiB | 5 | ~1.406TiB |

### RAM Purchase Rule

Use matched DDR3 ECC Registered DIMMs where possible.

Recommended target:

```text
90 × 16GB DDR3 ECC Registered RDIMM
```

Avoid mixing:

- ECC RDIMM with UDIMM
- Different voltages when possible
- Different ranks when possible
- Random speed bins if buying enough matched modules is possible

---

## iDRAC Count

None of the servers currently have iDRAC cards.

| Item | Per Server | Server Count | Total Needed |
|---|---:|---:|---:|
| Dell iDRAC6 Enterprise card | 1 | 5 | 5 |
| Dedicated iDRAC RJ45 management port/module | 1 | 5 | 5 |
| Cat6/Cat6A management cable | 1 | 5 | 5 |

Important purchase check:

```text
Verify each iDRAC listing includes the Enterprise card and the dedicated management port hardware.
Some listings separate the iDRAC module, vFlash module, and dedicated NIC hardware.
```

---

## Network Card Count

| Item | Per Server | Server Count | Total Needed |
|---|---:|---:|---:|
| Dual-port 10Gb SFP+ PCIe NIC | 1 | 5 | 5 |
| Total 10Gb SFP+ ports | 2 | 5 | 10 |
| Phase 1 active 10Gb links | 1 | 5 | 5 |
| Final dual 10Gb links | 2 | 5 | 10 |

Recommended NIC:

```text
Intel X520-DA2 dual-port 10Gb SFP+ PCIe
```

Phase 1 connection plan:

```text
Existing UniFi 8-port SFP+ aggregation switch:
  - 5 ports = one 10Gb link per R710
  - 1 port = uplink to access/gateway side
  - 1 port = optional uplink/spare
  - 1 port = optional uplink/spare
```

Final connection plan:

```text
Larger UniFi SFP+ aggregation switch:
  - 10 ports = dual 10Gb links for 5 R710 servers
  - 2+ ports = uplinks
  - spare ports = storage, lab, migration, future expansion
```

---

## Deferred / Optional Upgrades

These are not included in the under-$5K total.

| Category | Item | Qty | Unit Price | Line Total | Link | Reason Deferred |
|---|---|---:|---:|---:|---|---|
| 10Gb aggregation | UniFi US-16-XG 16-port 10G aggregation switch | 1 | `$399.95` | `$399.95` | [eBay](https://www.ebay.com/itm/389794389303) | Needed for dual 10Gb to all servers |
| 10Gb aggregation | UniFi US-16-XG alternate listing | 1 | `$549.99` | `$549.99` | [eBay](https://www.ebay.com/itm/389526254251) | Higher-priced fallback |
| 10Gb aggregation | UniFi USW-Pro-Aggregation | 1 | `$795.00+` | `$795.00+` | [eBay](https://www.ebay.com/itm/187680460291) | Better long-term backbone if found used |
| Gateway | UniFi UXG-Pro | 1 | `$400.00` | `$400.00` | [eBay](https://www.ebay.com/itm/357170075051) | USG Pro 4 replacement |
| Access switch | UniFi US-48-500W 48-port PoE switch | 1 | `$300.00` | `$300.00` | [eBay](https://www.ebay.com/itm/387735694505) | Replaces 2 × 24-port switches |
| Access switch | UniFi 48-port PoE alternate listing | 1 | `$350.00` | `$350.00` | [eBay](https://www.ebay.com/itm/226979398405) | Fallback 48-port PoE option |
| Storage | Additional 10TB SAS drives | 17 | `$199.00` | `$3,383.00` | [eBay](https://www.ebay.com/itm/196522699838) | Fills the remaining disk shelf bays |
| Storage | 24 × 12TB SAS bulk lot | 1 | `$4,296.00` | `$4,296.00` | [eBay](https://www.ebay.com/itm/327012427591) | 288TB raw, but not budget-friendly |
| Power | UniFi SmartPower PDU Pro | 1 | `$329.61` | `$329.61` | [eBay](https://www.ebay.com/itm/236444204683) | Nice UniFi-managed power, but not required for budget phase |
| Power | APC metered rack PDU | 1 | `$139.00` | `$139.00` | [eBay](https://www.ebay.com/itm/277851327430) | Better metering than basic 0U PDU |
| Cabling | Extra 10Gb DAC cables | As needed | `$14.00` | Varies | [eBay](https://www.ebay.com/itm/116731186539) | Add when moving to dual 10Gb per server |

---

## Recommended Purchase Order

### First Purchase Batch

Buy these first:

1. Additional R710 servers
2. Rails
3. iDRAC6 Enterprise cards
4. X520-DA2 NICs
5. CPUs
6. RAM
7. Thermal paste

Reason:

```text
The servers should be fully upgraded, firmware updated, tested, and stable before storage and rack power complexity is added.
```

### Second Purchase Batch

Buy these next:

1. Disk shelf
2. HBA
3. SAS cables
4. 7 × 10TB SAS drives

Reason:

```text
This starts the storage pool while keeping the total build under $5K.
```

### Third Purchase Batch

Buy these next:

1. UPS
2. 0U PDUs
3. C13/C14 power cables
4. Cable management

Reason:

```text
Power distribution should be cleaned up before all servers are powered together.
```

### Fourth Purchase Batch

Buy these next:

1. Raspberry Pi rackmount
2. Raspberry Pi boards
3. Pi power supplies
4. Pi microSD cards

Reason:

```text
The Pi shelf is useful but not required before the core server/storage build is validated.
```

### Deferred Purchase Batch

Buy these when budget allows:

1. UniFi US-16-XG or UniFi Pro Aggregation
2. UniFi UXG-Pro
3. UniFi 48-port PoE switch
4. Remaining 17 hard drives
5. Managed/metred UniFi or APC PDUs

---

## Cost Control Notes

To stay under $5K:

- Use the existing 8-port UniFi SFP+ aggregation switch during Phase 1.
- Start with 7 × 10TB SAS drives instead of filling all 24 bays immediately.
- Buy RAM in bulk lots when possible.
- Buy NICs in lots first, then fill missing count with singles.
- Do not buy the gateway and 48-port PoE switch in the same phase as the storage shelf.
- Avoid the 24 × 12TB bulk lot unless the network upgrade and Pi shelf are deferred.
- Verify whether R710 purchases include rails, power supplies, bezels, or iDRAC cards before buying those separately.

---

## Compatibility Checks Before Purchase

### Dell R710

Verify:

- Includes both CPU heatsinks
- Includes both power supplies
- Includes drive blanks or caddies if needed
- Accepts Xeon X5680 with current BIOS
- Has available PCIe x8 slots for 10Gb NIC and optional HBA
- Includes rails only if listing explicitly says so

### RAM

Verify:

- DDR3
- ECC
- Registered / RDIMM
- 16GB per DIMM
- Compatible with Dell R710
- Prefer matched kits

### iDRAC

Verify:

- iDRAC6 Enterprise, not Express only
- Dedicated NIC/port hardware is included
- Compatible with Dell PowerEdge R710
- vFlash is optional, not required

### 10Gb NIC

Verify:

- Intel X520-DA2 or equivalent
- Dual-port SFP+
- PCIe x8
- Standard or low-profile bracket as needed
- Works with DAC cables and Proxmox/Linux

### Disk Shelf

Verify:

- 24-bay 3.5-inch shelf
- Includes trays/caddies
- Includes both PSUs
- Includes IOM modules/controllers
- Includes rails or budget for rails
- Confirm SAS connector type before buying cables

### Hard Drives

Verify:

- 3.5-inch LFF
- SAS, not SATA, unless using proper shelf/interposer support
- 512e or 4Kn compatibility with the storage OS
- Seller provides SMART/health testing when possible
- Buy matching models when practical

### UPS

Verify:

- Includes batteries or price accordingly
- Includes rails
- Input plug matches available circuit
- Output connectors match PDU plan
- Runtime is acceptable for graceful shutdown

---

## Final Buy-Now Target State

After buying the under-$5K list, the rack should have:

- 5 × Dell R710 servers
- 10 × Intel Xeon X5680 CPUs
- 60 physical CPU cores
- 120 CPU threads
- 90 × 16GB DDR3 ECC RDIMMs
- 1.44TB total RAM
- 5 × iDRAC6 Enterprise cards
- 5 × dual-port 10Gb SFP+ NICs
- 1 × disk shelf
- 7 × 10TB SAS drives
- 70TB raw initial storage
- 1 × external SAS HBA
- UPS-backed rack power
- 2 × 0U PDUs
- 4 × Raspberry Pi nodes
- 1 × Raspberry Pi rack shelf
- Required SFP+, SAS, RJ45, power, and cable-management hardware

---

## Maintenance

Update this file when:

- Prices change
- Listings disappear
- Items are purchased
- Quantities change
- Disk size target changes
- Network upgrade phase changes
- UPS/PDU model changes
- Server hardware arrives with included rails, iDRAC, RAM, CPUs, or NICs

**Last Updated**: April 25, 2026  
**Target File**: `Docs/Network/Items-prices.md`