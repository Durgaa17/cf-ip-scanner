import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.net.InetAddress

// ====================== CONFIG ======================
const val NETWORK = "104.18.16.0/20"
const val WORKERS = 32
const val TIMEOUT_MS = 500
// ====================================================

fun main() {
    println("Scanning $NETWORK with $WORKERS workers...")
    println("This may take a while depending on the range size.\n")

    val ips = cidrToIps(NETWORK)
    val total = ips.size
    println("Total hosts to scan: $total\n")

    val alive = mutableListOf<String>()
    val lock = Any()
    val executor = Executors.newFixedThreadPool(WORKERS)

    for (ip in ips) {
        executor.submit {
            if (isAlive(ip)) {
                println("[+] $ip")
                synchronized(lock) {
                    alive.add(ip)
                }
            }
        }
    }

    executor.shutdown()
    executor.awaitTermination(1, TimeUnit.HOURS)

    alive.sort()
    File("reachable.txt").writeText(alive.joinToString("\n") + if (alive.isNotEmpty()) "\n" else "")

    println("\n========================================")
    println("Done! ${alive.size}/$total hosts are reachable")
    println("Results saved to: reachable.txt")
    println("========================================")

    if (alive.isNotEmpty()) {
        println("\nReachable IPs:")
        alive.forEach { println(it) }
    } else {
        println("\nNo reachable hosts found.")
    }
}

fun cidrToIps(cidr: String): List<String> {
    val parts = cidr.split("/")
    val ipStr = parts[0]
    val prefix = parts[1].toInt()

    val bytes = InetAddress.getByName(ipStr).address
    var ip = ((bytes[0].toInt() and 0xFF) shl 24) or
             ((bytes[1].toInt() and 0xFF) shl 16) or
             ((bytes[2].toInt() and 0xFF) shl 8) or
             (bytes[3].toInt() and 0xFF)

    val mask = if (prefix == 0) 0 else -1 shl (32 - prefix)
    val network = ip and mask
    val broadcast = network or mask.inv()

    val result = mutableListOf<String>()
    for (i in (network + 1) until broadcast) {
        result.add("${(i shr 24) and 0xFF}.${(i shr 16) and 0xFF}.${(i shr 8) and 0xFF}.${i and 0xFF}")
    }
    return result
}

fun isAlive(ip: String): Boolean {
    return try {
        val isWindows = System.getProperty("os.name").lowercase().contains("win")
        val command = if (isWindows) {
            listOf("ping", "-n", "1", "-w", TIMEOUT_MS.toString(), ip)
        } else {
            listOf("ping", "-c", "1", "-W", maxOf(1, TIMEOUT_MS / 1000).toString(), ip)
        }

        val process = ProcessBuilder(command)
            .redirectErrorStream(true)
            .start()

        val finished = process.waitFor(TIMEOUT_MS + 1000L, TimeUnit.MILLISECONDS)
        if (!finished) {
            process.destroyForcibly()
            return false
        }
        process.exitValue() == 0
    } catch (e: Exception) {
        false
    }
}
