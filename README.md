# CF IP Scanner

Fast concurrent IP ping scanner written in pure Python.  
Originally made to scan Cloudflare IP ranges, but works with **any CIDR** range.

Works on:
- **Termux** (Android)
- **Windows 11**
- Linux / macOS

---

## Features

- Concurrent scanning (default 32 threads)
- Cross-platform (Windows + Linux/Termux)
- Saves reachable IPs to `reachable.txt`
- Easy to change the target range

---

## How to Use

### 1. Termux (Android)

```bash
# Update packages
pkg update && pkg upgrade -y

# Install required tools
pkg install python git -y

# Clone the repository
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner

# Run the scanner
python scan.py
```

Results will be saved in `reachable.txt` in the same folder.

---

### 2. Windows 11 (Command Prompt or PowerShell)

#### Method A: Using Git (Recommended)

1. Install [Git for Windows](https://git-scm.com/download/win) if you don't have it.
2. Open **Command Prompt** or **PowerShell** and run:

```cmd
git clone https://github.com/Durgaa17/cf-ip-scanner.git
cd cf-ip-scanner
python scan.py
```

#### Method B: Without Git

1. Download the repository as ZIP from:  
   https://github.com/Durgaa17/cf-ip-scanner
2. Extract the ZIP file.
3. Open the folder in Command Prompt / PowerShell.
4. Run:

```cmd
python scan.py
```

> **Note:** Make sure Python is installed and added to PATH.  
> Download Python from: https://www.python.org/downloads/

---

## Configuration

Open `scan.py` and edit these lines at the top:

```python
NETWORK = "104.18.16.0/20"   # Change to any CIDR (example: 1.1.1.0/24)
THREADS = 32                 # Number of parallel pings
TIMEOUT = 0.5                # Timeout per ping (seconds)
```

---

## Example Output

```
Scanning 104.18.16.0/20 (4094 hosts) with 32 threads...
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

- Python 3.7+
- No external libraries needed (uses only standard library)

---

## License

Free to use and modify.
