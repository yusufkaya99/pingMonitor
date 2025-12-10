# Ping Monitor

A minimal terminal-based tool to monitor multiple IP addresses using `fping`. It shows per-destination latency and also determines the actual source IP and network interface used for each target — useful in systems with multiple network interfaces.

---

## Features

- Monitor multiple IP addresses in parallel with real-time updates
- Dynamic IP management - Add, remove, or modify IP addresses without editing the script
- IP range support - Quickly add multiple IPs using range notation (e.g., 192.168.5.1-10)
- Persistent configuration - IP addresses are saved to a config file and persist between runs
- Duplicate prevention - Automatically prevents adding duplicate IP addresses
- Determine source IP and interface for each destination
- Show ping results and latency clearly in a color-coded table format
- Ping statistics - Track success, failure, rate, and last status change time
- Interactive menu - Press CTRL+O during monitoring to manage IPs
- Automatic refresh at configurable intervals

---

## Requirements

- `fping`
- `iproute2` (`ip route get` must be available)
- Standard POSIX tools (`awk`, `sed`, `grep`)

To install `fping` (if not already installed):

```bash
sudo apt install fping
```

## Installation

Make the script executable:

```bash
chmod +x pingMonitor.sh
```

## Usage

Run the monitor with default settings:

```bash
./pingMonitor.sh
```

## Options
- -i, --interval N        Set interval between ping rounds (default: 2 seconds)"
- -t, --timeout  N        Set timeout for each ping (default: 200 ms)"
- -m, --manage            Open IP management menu immediately"
- -h, --help              Show the help message"

Example option usage:

```bash
./pingMonitor.sh -i 5 -t 300
```

Example output:

```bash
 Target IP        |  Result          |  Latency  |  Source IP        |  Interface  |  Success  |  Failure  |  Rate  |  Last Change  |  Last Update
---------------------------------------------------------------------------------------------------------------------------------------------------
192.168.99.1      |  ✅ Successfull  |  1.10ms   |  192.168.99.35    |  enp45s0    |  10       |  10       |  %50   |  14:19:50     |  14:20:15
8.8.8.8           |  ❌ No Response  |  -        |  192.168.1.12     |  wlan0      |  2        |  8        |  %20   |  14:20:05     |  14:20:15
```
