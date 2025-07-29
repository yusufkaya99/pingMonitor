# Ping Monitor

A minimal terminal-based tool to monitor multiple IP addresses using `fping`. It shows per-destination latency and also determines the actual source IP and network interface used for each target — useful in systems with multiple network interfaces.

---

## Features

- Monitor multiple IP addresses in parallel
- Determine source IP and interface for each destination
- Show ping result and latency clearly in a table format
- Refreshes automatically at set intervals

---

## Requirements

- `fping`
- `iproute2` (`ip route get` must be available)
- Standard POSIX tools (`awk`, `sed`, `grep`)

To install `fping` (if not already installed):

```bash
sudo apt install fping
```

## Configuration
Edit the top of the script to set your target IPs and options:

```bash
IP_LIST=(
    "192.168.99.1"
    "8.8.8.8"
)
```

## Usage
Make the script executable:

```bash
chmod +x pingMonitor.sh
```

Then run:

```bash
./pingMonitor.sh
```

Example output:

```bash
Target IP       | Result         | Latency | Source IP       | Interface | Last Update
----------------------------------------------------------------------------------------
192.168.99.1    | ✅ OK          | 1.10ms  | 192.168.99.35   | enp45s0   | 14:20:15
8.8.8.8         | ❌ No Response |   -     | 192.168.1.12    | wlan0     | 14:20:15
```

## Options
- -i, --interval N        Set interval between ping rounds (default: 2 seconds)"
- -t, --timeout  N        Set timeout for each ping (default: 200 ms)"
- -h, --help              Show the help message"

Example option usage:


```bash
./pingMonitor.sh -i 5 -t 300
```
