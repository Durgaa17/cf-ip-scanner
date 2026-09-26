# CF IP Scanner

Fast concurrent IP ping scanner.  
Available in **Python**, **Go**, and **Node.js**.  
Originally made to scan Cloudflare IP ranges, but works with **any CIDR** range.

Works on:
- **Termux** (Android)
- **Windows 11**
- Linux / macOS

---

## Features

- Concurrent scanning (default 32 workers)
- Cross-platform (Windows + Linux/Termux)
- Saves reachable IPs to `reachable.txt`
- Easy to change the target range
- Three versions: Python, Go, and Node.js

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

> Make sure Python is installed: https://www.python.org/downloads/

**Configuration** (edit top of `scan.py`):

```python
NETWORK = "104.18.16.0/20"   # Change to any CIDR
THREADS = 32
TIMEOUT = 0.5
```

---

## 2. Go Version (Recommended - Fastest)

### Termux (Android)

```bash
pkg update && pkg upgrade -y
pkg install golang git -y

git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner

go run scan.go

# Or build a binary
go build -o scanner scan.go
./scanner
```

### Windows 11

```cmd
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner

go run scan.go

# Or build
go build -o scanner.exe scan.go
scanner.exe
```

**Configuration** (edit top of `scan.go`):

```go
const (
    Network = "104.18.16.0/20" // Change to any CIDR
    Workers = 32
    Timeout = 500 * time.Millisecond
)
```

---

## 3. Node.js Version

### Termux (Android)

```bash
pkg update && pkg upgrade -y
pkg install nodejs git -y

git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner

node scan.js
```

### Windows 11

1. Install Node.js from: https://nodejs.org/
2. Open Command Prompt / PowerShell:

```cmd
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner

node scan.js
```

**Configuration** (edit top of `scan.js`):

```js
const NETWORK = "104.18.16.0/20"; // Change to any CIDR
const WORKERS = 32;
const TIMEOUT = 500; // milliseconds
```

---

## Example Output

```
Scanning 104.18.16.0/20 (4094 hosts) with 32 workers...
This may take a while depending on the range size.

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

| Version  | Requirements                          |
|----------|---------------------------------------|
| Python   | Python 3.7+ (standard library only)   |
| Go       | Go 1.18+ (standard library only)      |
| Node.js  | Node.js 14+ (standard library only)   |

---

## License

Free to use and modify.
