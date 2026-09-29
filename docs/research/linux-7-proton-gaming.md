# Linux 7.0-7.2 for Wine and Proton gaming on the AMD desktop

Research date: 2026-09-26.

## Answer

**Do not upgrade from Linux 6.18 solely for a claimed Wine or Proton speedup.**
The Windows synchronization interfaces often cited as reasons to upgrade predate Linux 7, and the verified Linux 7.2 `ntsync` fix affects Wine in a time namespace with a clock offset, not normal desktop gameplay ([Linux 6.14 `NTSYNC` configuration](https://github.com/torvalds/linux/blob/v6.14/drivers/misc/Kconfig), [Linux 7.2 fix](https://github.com/torvalds/linux/commit/180a232ea78003d1dc869b217b4e49106fd58e8f)).
The stronger reason to test a newer supported kernel is a *specific AMD display or graphics-queue fault*, if it matches this machine's symptoms, rather than a general FPS promise ([Linux 7.1 AMD fixes](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.1), [GFX11 interrupt-routing fix](https://github.com/torvalds/linux/commit/88e589cc811ba907209a426c426c469bcb4bb894)).
No cited upstream source provides a controlled 6.18 versus 7.2 Proton/AMD game benchmark for this desktop.

## Versions and what they actually add

| Feature | First upstream kernel | Relevance to this comparison |
| --- | --- | --- |
| Syscall user dispatch | 5.11 | Designed for compatibility layers such as Wine; its [5.11 documentation](https://github.com/torvalds/linux/blob/v5.11/Documentation/admin-guide/syscall-user-dispatch.rst) says modern games rarely issue intercepted Windows-code syscalls. It is not a Linux 7 addition. |
| `futex_waitv()` | 5.16 | The [5.16 futex2 API](https://github.com/torvalds/linux/blob/v5.16/Documentation/userspace-api/futex2.rst) documents waiting on multiple futexes. It is distinct from `ntsync` and is already available on 6.18. |
| `ntsync` | 6.14 | The [6.14 kernel configuration](https://github.com/torvalds/linux/blob/v6.14/drivers/misc/Kconfig) includes `CONFIG_NTSYNC`; the [6.18 user API](https://docs.kernel.org/6.18/userspace-api/ntsync.html) documents `/dev/ntsync`, semaphores, mutexes, events, and wait-any/wait-all. Presence in kernel source does **not** prove that a given build enables the module or that Proton uses it. |
| Linux 7.0 / 7.1 | 7.0 on 2026-04-13; 7.1 on 2026-06-14 | These are [release archive dates](https://cdn.kernel.org/pub/linux/kernel/v7.x/), not the introduction dates of the three interfaces above. I found no verified, broadly applicable new Proton synchronization API in these two releases. |
| Linux 7.2 | 2026-08-17 | The [release archive](https://cdn.kernel.org/pub/linux/kernel/v7.x/) and [7.2 `ntsync` source](https://github.com/torvalds/linux/blob/v7.2/drivers/misc/ntsync.c) show that `ntsync` now converts absolute monotonic timeouts from the caller's time namespace. The [fix commit](https://github.com/torvalds/linux/commit/180a232ea78003d1dc869b217b4e49106fd58e8f) says the initial time namespace takes the unchanged fast path. |

The 7.2 timeout fix is real Wine-related work, but it fixes early or late timeouts only for an `ntsync` user inside a time namespace with a monotonic clock offset ([fix commit and reproducer](https://github.com/torvalds/linux/commit/180a232ea78003d1dc869b217b4e49106fd58e8f)).
It was **not** in the [7.1 driver source](https://github.com/torvalds/linux/blob/v7.1/drivers/misc/ntsync.c), and it **is** in the [7.2 driver source](https://github.com/torvalds/linux/blob/v7.2/drivers/misc/ntsync.c).
Do not infer a native-desktop FPS change from this fix.

## Does Proton use the feature?

Valve's [Proton 10.0-4 documentation](https://github.com/ValveSoftware/Proton/blob/proton-10.0-4/README.md) describes `PROTON_NO_FSYNC` and says fsync is automatically disabled when `FUTEX_WAIT_MULTIPLE` support is absent.
The [Proton 11.0-2 launcher enables `WINEFSYNC` unless disabled](https://github.com/ValveSoftware/Proton/blob/proton-11.0-2/proton#L1723-L1746).
Valve's [Proton 11.0-2 documentation](https://github.com/ValveSoftware/Proton/blob/proton-11.0-2/README.md) still documents fsync and also documents `PROTON_NO_NTSYNC` as a way to disable `ntsync`.
The [upstream Wine 11.0 synchronization source](https://github.com/wine-mirror/wine/blob/wine-11.0/dlls/ntdll/unix/sync.c) implements Linux `ntsync` ioctls and falls back to server operations when its in-process device path is unavailable.
Together with [Proton 11's Wine 11.0 rebase](https://github.com/ValveSoftware/Proton/releases/tag/proton-11.0-1), this establishes an `ntsync`-capable code path, not proof that an unidentified installed Proton version and game actually use it on this host.
The [Proton 11.0-1 release](https://github.com/ValveSoftware/Proton/releases/tag/proton-11.0-1) dated 2026-07-07 rebases on Wine 11.0 and updates DXVK and vkd3d-proton; those are userspace changes, not benefits that require Linux 7.
The [Proton 11.0-2 release](https://github.com/ValveSoftware/Proton/releases/tag/proton-11.0-2) dated 2026-08-21 lists game-specific fixes, including an Exanima performance regression, but makes no 6.18-to-7.2 kernel FPS claim.

**Do not compare `ntsync` versus vanilla Wine's wineserver path and present the result as `ntsync` versus Proton fsync.**
The [kernel `ntsync` documentation](https://docs.kernel.org/6.18/userspace-api/ntsync.html) explains why it exists relative to userspace emulation, while [Valve documents an independent fsync path](https://github.com/ValveSoftware/Proton/blob/proton-10.0-4/README.md).
No performance percentage from a different Wine build, synchronization mode, game, GPU, or test setup establishes a gain for this machine.

## AMD and local NixOS context

The [Linux 7.1 changelog](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.1) includes an AMD display MCCS FreeSync capability fix and an AMD user-queue fix.
The [GFX11 interrupt-routing correction](https://github.com/torvalds/linux/commit/88e589cc811ba907209a426c426c469bcb4bb894) addresses misrouted kernel-queue completion interrupts with MES enabled; it is potentially relevant to RDNA3, but it is a fault fix, not a demonstrated Proton FPS improvement.
The [GFX12 companion change](https://github.com/torvalds/linux/commit/6c1f4f7ff08448e0e18cd7fc4e59d6c96a36f25d) targets a different GPU generation and must not be counted as a benefit for RDNA3.
The [7.1 AMD fixes](https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.1) and [7.2 GFX11 change](https://github.com/torvalds/linux/commit/88e589cc811ba907209a426c426c469bcb4bb894) justify testing only if a matching display, queue, or hang problem is observed; they do not prove that the local illegal-opcode hangs are fixed.

The repository enables [gaming on `nixos-desktop`](../../hosts/nixos-desktop/configuration.nix#L8-L21), uses [Steam, GE-Proton and a gamescope 1440p/120 Hz session](../../modules/nixos/gaming.nix#L23-L49), and comments out HDR while investigating RDNA3 hangs ([gaming module](../../modules/nixos/gaming.nix#L19-L21), [gamescope settings](../../modules/nixos/gaming.nix#L32-L41)).
The local `lspci -nn` output identifies a Navi 31 GPU (`1002:744c`), which covers the RX 7900 XT/XTX/GRE/7900M family; it does not by itself distinguish the exact card model ([earlier research note](./sunshine-moonlight-latency.md#local-context)).
The flake's [NixOS system `pkgs` comes from `nixos-26.05`](../../flake.nix#L10-L15) and [the desktop uses that stable package set](../../flake.nix#L205-L225), while [Steam and gamescope take `pkgs-latest`](../../modules/nixos/gaming.nix#L10-L15).
Before the kernel test was configured, the desktop did not explicitly select `boot.kernelPackages` or load `ntsync`. Nixpkgs [defaults `boot.kernelPackages` to the system `pkgs.linuxPackages`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/kernel.nix); evaluation returned 6.18.53 before the change. The desktop now selects [the system package set's 7.2 series](../../hosts/nixos-desktop/configuration.nix#L6) and [loads `ntsync`](../../modules/nixos/gaming.nix#L11). With the local lock file, evaluation returns 7.2.7 for the selected kernel ([26.05 package source](https://github.com/NixOS/nixpkgs/tree/nixos-26.05/pkgs/os-specific/linux/kernel)).
The running kernel is 6.18.49 (`uname -r`); the kernel archive listed 7.2.8 as stable and 6.18.54 as longterm on 2026-09-25 ([kernel.org](https://www.kernel.org/)).

`modinfo ntsync` finds `/run/booted-system/kernel-modules/lib/modules/6.18.49/kernel/drivers/misc/ntsync.ko.xz`, so the running 6.18.49 build has the module available. It is absent from `lsmod`, and `stat /dev/ntsync` reports no such file: it is not currently loaded. This can be addressed on 6.18, without a Linux 7 upgrade.
Do not assume that merely selecting Linux 7.2 provides a usable `/dev/ntsync` or switches a game to it; the explicit module setting is part of this test.
Confirm the active kernel config, device, and Proton mode before any synchronization claim.
The NixOS [kernel package option](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/kernel.nix) also ties external modules to the selected kernel; a kernel change is not a change to DXVK, Mesa, or Proton.

## Decision and limits

1. Keep a maintained 6.18 release if the games and display are stable; Linux 6.18 is listed as longterm while 7.2 is stable ([kernel.org, 2026-09-25](https://www.kernel.org/)).
2. If a repeatable AMD display or GPU-queue fault persists, compare supported 6.18 and 7.2 kernels with the same game, Proton build, Mesa stack, firmware, display mode, and settings; the [AMD commits](https://github.com/torvalds/linux/commit/88e589cc811ba907209a426c426c469bcb4bb894) make this a targeted fault test, not a predicted speedup.
3. Before attributing any difference to `ntsync`, verify `CONFIG_NTSYNC`, `/dev/ntsync`, the game-selected Proton version, and its active synchronization path ([kernel device API](https://docs.kernel.org/6.18/userspace-api/ntsync.html), [Proton 11 runtime controls](https://github.com/ValveSoftware/Proton/blob/proton-11.0-2/README.md)).

WineHQ's release site could not be retrieved directly during this research, so no claim here depends on an unverified WineHQ release-note quotation.
The installed Proton selection, active Mesa/firmware versions, game list, and reproducible FPS or frame-time data were not measured.
The Nix configuration now selects Linux 7.2 and loads `ntsync` for testing. No system was built or activated during this research.
