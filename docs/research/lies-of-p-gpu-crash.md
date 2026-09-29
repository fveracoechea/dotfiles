# Lies of P GPU reset on Navi 31

Research date: 2026-09-27.

## Answer

Valve's **Proton 11.0-2** also crashed on this machine on 2026-09-27.
Proton Experimental remains an untested comparison, not a verified fix for Lies of P.
Valve released 11.0-2 on 2026-08-21 with a newer VKD3D-Proton build than 11.0-1 ([11.0-2 release](https://github.com/ValveSoftware/Proton/releases/tag/proton-11.0-2)).
Valve's [Experimental changelog, updated 2026-09-25](https://github.com/ValveSoftware/Proton/wiki/Changelog#available-in-proton-experimental-as-of-2026-09-25) includes all 11.0-2 changes plus newer development VKD3D-Proton, DXVK, and other components.
Neither Valve changelog identifies a Lies of P or Navi 31 illegal-opcode fix.
GE-Proton11-7, released 2026-09-16, also updated VKD3D-Proton and changed Wine-Wayland rendering, so "newer" alone does not predict the result ([GE release](https://github.com/GloriousEggroll/proton-ge-custom/releases/tag/GE-Proton11-7)).

If official Proton still resets the GPU, test a **60 FPS cap before broadly lowering graphics quality**.
A 2026-08-31 [first-hand Lies of P report](https://github.com/HansKristian-Work/vkd3d-proton/issues/3004#issuecomment-5484786109) on an RX 7900 XT describes the same `LOP-Win64-Shipping` / `vkd3d_queue` timeout and illegal opcode.
That reporter found 60 FPS stable, about 90 FPS apparently stable, and crashes around 100 FPS or above; Proton 10.0-4 still crashed, but later.
This is one user's observation, not a confirmed threshold for this machine or a proven cause.
VKD3D-Proton [documents `VKD3D_FRAME_RATE=60`](https://github.com/HansKristian-Work/vkd3d-proton/blob/v3.0.1/README.md#frame-rate-limit) as a per-game cap if a fixed in-game cap is unavailable.
After testing the cap, lower resolution or individual effects one at a time to check whether workload matters.
No source establishes a specific Lies of P quality preset as a fix.

## What the evidence does and does not show

- The supplied 2026-09-27 journal sequence names a graphics-ring timeout in the game's VKD3D queue, an illegal opcode, failed MES ring reset, a successful full GPU reset with VRAM loss, and then a Hyprland abort.
  This is a GPU reset with a lost graphics context, not evidence that Hyprland caused the initial hang.
  The matching [2026-05-15 GFX11 report](https://github.com/HansKristian-Work/vkd3d-proton/issues/3004#issuecomment-4459598571) contains the same order in another game, but matching logs do not establish a common root cause.
- The local Steam configuration selects `GE-Proton11-7-x86_64` for app 1627720 (`~/.local/share/Steam/config/config.vdf`).
  `lact cli -g 1 profile get` reports `Default` for the dedicated RX 7900 XTX now, but that does not establish its clock settings at the time of the crash.
  The repo disabled HDR in its separate gamescope Steam session (`modules/nixos/gaming.nix`); this crash occurred in Hyprland, so those gamescope flags do not show what the game used in this run.
- In the previous boot's Steam journal, Proton upgraded the Lies of P prefix from `GE-Proton11-7` to `11.0-100` at 14:17:39 and launched the game at 14:17:46.
  The locally installed official Proton 11.0 reports `proton-11.0-2c-x86_64` in its `version` file.
  At 14:49:19 the kernel again named `LOP-Win64-Shipp` and `vkd3d_queue` in a graphics-ring timeout and reported an illegal opcode, followed by GPU reset and VRAM loss.
  In the current boot, Steam upgraded the game prefix back to `GE-Proton11-7` at 14:56:46 before the next run.
- The [VKD3D-Proton issue opened 2026-05-10](https://github.com/HansKristian-Work/vkd3d-proton/issues/3004) includes Navi 31 reports across several games and Proton versions.
  A Lies of P report appears in its comments, but the issue is closed as not planned and contains conflicting results for mitigations.
  One user [reported `VKD3D_CONFIG=single_queue` helped STALKER 2](https://github.com/HansKristian-Work/vkd3d-proton/issues/3004#issuecomment-5450244246), while [another said it did not help Darktide](https://github.com/HansKristian-Work/vkd3d-proton/issues/3004#issuecomment-5455000332).
  The [VKD3D-Proton README](https://github.com/HansKristian-Work/vkd3d-proton/blob/v3.0.1/README.md#environment-variables) says this option disables asynchronous compute and transfer queues.
  It is a later, per-game diagnostic test, not a confirmed Lies of P fix.
- AMD's Linux firmware maintainers [reverted a GC 11.0.0 MES update](https://gitlab.com/kernel-firmware/linux-firmware/-/commit/0a5565a4a8881d95c55399ae6f95fb0ce3ceec75) and [other GC 11.0.0 firmware](https://gitlab.com/kernel-firmware/linux-firmware/-/commit/9a7c283fa0037c4db360214192d57aab1272d403) on 2026-09-18; the latter says the update "causes instability in some games."
  This is relevant to a GFX11/MES hang, but the commits do not name Lies of P or prove that this machine loaded the affected firmware.
  Check the *booted* firmware versions before attributing a result to these reverts.
- GE's [2025 Lies of P P-Organ report](https://github.com/GloriousEggroll/proton-ge-custom/issues/211) concerns a native Wine-Wayland cursor-capture crash on an NVIDIA GPU.
  GE [identified cursor capture as the cause](https://github.com/GloriousEggroll/proton-ge-custom/issues/211#issuecomment-3215764029).
  Its symptoms differ from this AMD graphics-ring reset; GE's [2026-09-16 Hyprland black-screen fixes](https://github.com/GloriousEggroll/proton-ge-custom/releases/tag/GE-Proton11-7) also do not claim to fix this reset.

## Controlled tests

1. Record the booted kernel, Mesa/RADV and amdgpu firmware versions, Vulkan device, game version, display mode, launch options, graphics preset, cap, and time or scene until failure.
   Save the relevant journal lines and the [Valve-supported `PROTON_LOG=1 %command%` log](https://github.com/ValveSoftware/Proton/blob/proton-11.0-2/README.md#runtime-config-options) for Steam app 1627720.
   A reset can kill the desktop, so collect logs after recovery and reboot before the next run.
2. Keep the same settings and route through the game.
   GE-Proton11-7 and Valve Proton 11.0-2 both produced the GPU hang on this machine; Experimental remains a possible comparison with the same kernel, Mesa, firmware, display mode, Vulkan driver, and no extra launch-option changes.
   Use repeated runs long enough to exceed the usual failure time, then repeat the first condition to check for random variation.
   Do not clear caches, alter the prefix, or change kernel and Proton together during this comparison.
3. On a build that still crashes, hold the Proton build and quality preset fixed and compare uncapped with 60 FPS, then 90 FPS if 60 remains stable.
   Use the game's cap or `VKD3D_FRAME_RATE=60 %command%` for a per-game launch option ([upstream documentation](https://github.com/HansKristian-Work/vkd3d-proton/blob/v3.0.1/README.md#frame-rate-limit)).
   If a cap helps, test one graphics setting at a time at the *same cap*; otherwise a lower preset also changes achieved FPS and cannot isolate the setting.
4. If the reset persists across official Proton builds and the cap, compare `VKD3D_CONFIG=single_queue %command%` with the same settings and cap, and measure any performance cost ([option definition](https://github.com/HansKristian-Work/vkd3d-proton/blob/v3.0.1/README.md#environment-variables)).
   Check whether the installed firmware package includes the [2026-09-18 reverts](https://gitlab.com/kernel-firmware/linux-firmware/-/commit/9a7c283fa0037c4db360214192d57aab1272d403) before any later firmware comparison; the package date alone may not establish which blobs the booted system loaded.

## Confidence and limits

High confidence in the published release dates, option meanings, firmware reversions, and the journal's reset sequence.
Moderate confidence that an FPS cap is a useful first workload test because one closely matching Lies of P report supports it.
Low confidence that any Proton switch, FPS cap, quality reduction, or `single_queue` will fix this machine.
The Mesa and amdgpu work-item pages linked from the [VKD3D-Proton discussion](https://github.com/HansKristian-Work/vkd3d-proton/issues/3004#issuecomment-5657790592) were blocked by their site's browser check, so their contents and proposed fixes were not verified.
No controlled game runs or verified booted firmware comparison were available for this research.
