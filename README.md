# CF IP Scanner

Fast concurrent IP ping scanner.  
Available in **Python**, **Go**, **Node.js**, and **Bash**.  
Originally made to scan Cloudflare IP ranges, but works with **any CIDR** range.

Works on:
- **Termux** (Android)
- **Windows 11** (Python / Go / Node.js)
- Linux / macOS

---

## Features

- Concurrent scanning (default 32 workers)
- Cross-platform
- Saves reachable IPs to `reachable.txt`
- Easy to change the target range
- Four versions: Python, Go, Node.js, and Bash

---

## 1. Python Version

### Termux (Android)

```bash
pkg update && pkg upgrade -y
pkg install python git -y

git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner

python scan.py
```

### Windows 11

```cmd
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner
python scan.py
```

**Configuration** (edit top of `scan.py`):

```python
NETWORK = "104.18.16.0/20"
THREADS = 32
TIMEOUT = 0.5
```

---

## 2. Go Version (Recommended - Fastest)

### Termux

```bash
pkg install golang git -y
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner
go run scan.go
```

### Windows 11

```cmd
go run scan.go
```

**Configuration** (edit top of `scan.go`):

```go
const (
    Network = "104.18.16.0/20"
    Workers = 32
    Timeout = 500 * time.Millisecond
)
```

---

## 3. Node.js Version

### Termux

```bash
pkg install nodejs git -y
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner
node scan.js
```

### Windows 11

```cmd
node scan.js
```

**Configuration** (edit top of `scan.js`):

```js
const NETWORK = "104.18.16.0/20";
const WORKERS = 32;
const TIMEOUT = 500;
```

---

## 4. Bash Version (Best for Termux / Linux)

```bash
pkg update && pkg upgrade -y
pkg install python git -y          # python is used only to generate IP list

git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner

chmod +x scan.sh
./scan.sh
```

**Configuration** (edit top of `scan.sh`):

```bash
NETWORK="104.18.16.0/20"
WORKERS=32
TIMEOUT=0.5
```

> Note: The Bash version uses `xargs -P` for concurrency and works great on Termux and Linux.  
> On Windows it is recommended to use the Python, Go, or Node.js version instead.

---

## Example Output

```
Scanning 104.18.16.0/20 with 32 workers...
Total hosts to scan: 4094

[+] 104.18.16.5
[+] 104.18.17.23
...

========================================
Done! 47/4094 hosts are reachable
Results saved to: reachable.txt
========================================
```

---

## Requirements

| Version  | Requirements                              |
|----------|-------------------------------------------|
| Python   | Python 3.7+                               |
| Go       | Go 1.18+                                  |
| Node.js  | Node.js 14+                               |
| Bash     | Bash + Python (only for IP list generation) |

---

## License

Free to use and modify.
