# Minecraft Java Edition Server Launcher

PowerShell Auto‑Update & Launch Script

**`server.ps1`** is a single‑file utility that installs Java (if missing), fetches the requested or latest **`minecraft_server-<version>.jar`**, accepts the EULA on your behalf (optional), and starts the server with sensible defaults—all on Windows via PowerShell.

---

## Features

* **Java bootstrap** – Installs OpenJDK 21 automatically through **winget** when no compatible Java runtime is found.
* **Version‑aware download** – Downloads the specified version *or* the latest release. The Mojang version manifest is queried **only when the latest version is requested**, avoiding unnecessary network calls.
* **EULA automation** – Pass `-Eula yes|true` to skip the interactive prompt and write `eula=true` to *eula.txt*.
* **16 GB heap & nogui by default** – Tweakable with `-MinMemory`, `-MaxMemory`, and `-Gui` switches.
* **Modular functions** – Each major step lives in its own function for easy maintenance and reuse.

---

## Tested Environment

| Item            | Recommended / Required                      |
| --------------- | ------------------------------------------- |
| OS              | Windows 10 / 11                             |
| Shell           | PowerShell 7.x or Windows PowerShell 5.1    |
| Package manager | winget (bundled with Windows App Installer) |
| Network         | HTTPS access to `launchermeta.mojang.com`   |

> **Heads‑up:** If *winget* is unavailable, pre‑install Java 21 and make sure it is on **PATH**.

---

## Quick Start

```powershell
# Run from the script’s directory – grabs the latest build & auto‑accepts the EULA
./server.ps1 -Eula yes
```

First‑run flow:

1. Check for Java; install if missing.
2. Resolve the latest version and download the JAR if not present.
3. Ensure *eula.txt* exists and contains `eula=true` (auto or interactive).
4. Launch the server with the requested heap size.

---

## Parameters

| Parameter    | Type     | Default  | Description                                        |
| ------------ | -------- | -------- | -------------------------------------------------- |
| `-Version`   | `string` | *latest* | Example: `"1.20.4"` to pin a version.              |
| `-MinMemory` | `string` | `16G`    | Passed to Java as `-Xms`.                          |
| `-MaxMemory` | `string` | `16G`    | Passed to Java as `-Xmx`.                          |
| `-Gui`       | `switch` | *off*    | Show the legacy server GUI instead of `nogui`.     |
| `-Eula`      | `string` | *empty*  | `yes` or `true` = non‑interactive EULA acceptance. |

---

## Usage Examples

### Start a specific version with an 8 GB heap

```powershell
./server.ps1 -Version 1.20.4 -MinMemory 8G -MaxMemory 8G -Eula yes
```

### Start with the GUI enabled (4 GB heap)

```powershell
./server.ps1 -MinMemory 4G -MaxMemory 4G -Gui -Eula yes
```

### Grab the latest version and confirm the EULA interactively

```powershell
./server.ps1
```

---

## About the EULA

Running a Minecraft server requires acceptance of the **Mojang EULA**. The script supports:

* `-Eula yes|true` – immediately writes `eula=true`.
* No `-Eula` flag – prompts for confirmation.

Read the full EULA here: [https://aka.ms/MinecraftEULA](https://aka.ms/MinecraftEULA).

---

## Java Installation Strategy

* Only triggers `winget install Microsoft.OpenJDK.21` when Java is missing.
* Refreshes the current session’s **PATH** so the new Java is available right away.

---

## Script Layout (bird’s‑eye view)

```text
server.ps1
├─ Install-Java       # Java presence check & winget install
├─ Get-Manifest       # Fetches version manifest (latest only)
├─ Ensure-ServerJar   # Verifies & downloads the server JAR
├─ Ensure-Eula        # Verifies & updates eula.txt
└─ Main               # Orchestrates steps & launches Java
```

---

## Caveats & Tips

* **Backup your world**—the script does not guard against map corruption.
* Future changes in Mojang’s API or download host can break the script.
* Linux/macOS are *not* supported; use a shell script or container solution instead.

---

## License

Licensed under the **Apache License 2.0**. See the `LICENSE` file for full text.

---

## Contributing

1. Open an issue or pull request.
2. When reporting bugs, include your PowerShell version, Windows build, and the exact command line you ran.

---

## Author

Satoru Yoshihara (Vaduz)
[@Vaduzjp](https://x.com/Vaduzjp)
