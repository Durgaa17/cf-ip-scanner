# CF IP Scanner - PowerShell version
# Best for Windows 11 (also works on PowerShell Core)

# ====================== CONFIG ======================
$Network = "104.18.16.0/20"   # Change this to any CIDR
$Workers = 32                 # Number of concurrent pings
$Timeout = 500                # Timeout in milliseconds
# ====================================================

function Get-IPsFromCIDR {
    param([string]$CIDR)

    $parts = $CIDR -split "/"
    $ip = [System.Net.IPAddress]::Parse($parts[0])
    $prefix = [int]$parts[1]

    $ipBytes = $ip.GetAddressBytes()
    [Array]::Reverse($ipBytes)
    $ipInt = [BitConverter]::ToUInt32($ipBytes, 0)

    $mask = if ($prefix -eq 0) { 0 } else { [uint32](-bnot ([uint32]([math]::Pow(2, 32 - $prefix) - 1))) }
    $network = $ipInt -band $mask
    $broadcast = $network -bor (-bnot $mask)

    $ips = @()
    for ($i = $network + 1; $i -lt $broadcast; $i++) {
        $bytes = [BitConverter]::GetBytes([uint32]$i)
        [Array]::Reverse($bytes)
        $ips += [System.Net.IPAddress]::new($bytes).ToString()
    }
    return $ips
}

Write-Host "Scanning $Network with $Workers workers..."
Write-Host "This may take a while depending on the range size.`n"

$ips = Get-IPsFromCIDR -CIDR $Network
$total = $ips.Count
Write-Host "Total hosts to scan: $total`n"

$alive = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

$ips | ForEach-Object -ThrottleLimit $Workers -Parallel {
    $ip = $_
    $timeout = $using:Timeout

    $ping = Test-Connection -ComputerName $ip -Count 1 -TimeoutSeconds ([math]::Ceiling($timeout / 1000)) -Quiet -ErrorAction SilentlyContinue

    if ($ping) {
        Write-Host "[+] $ip"
        ($using:alive).Add($ip) | Out-Null
    }
}

$aliveList = $alive.ToArray() | Sort-Object
$aliveList | Out-File -FilePath "reachable.txt" -Encoding utf8

Write-Host "`n========================================"
Write-Host "Done! $($aliveList.Count)/$total hosts are reachable"
Write-Host "Results saved to: reachable.txt"
Write-Host "========================================"

if ($aliveList.Count -gt 0) {
    Write-Host "`nReachable IPs:"
    $aliveList
} else {
    Write-Host "`nNo reachable hosts found."
}
