# Moonlight TV vs Aurora TV for the LG OLED C3 streaming client

Research date: 2026-09-19.

## Verdict

Install Aurora v1.2.9 beside Moonlight TV v1.6.36 and run the trial below, but keep Moonlight TV as the fallback. Aurora is the stronger candidate for this setup because it explicitly targets LG C1 through C5 televisions, 4K at 120 FPS, HEVC Main10 HDR, and higher bitrate operation. It also has more detailed on-TV diagnostics. Those are project claims and implementation choices, not controlled proof on a C3 ([Aurora README](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md), [Aurora v1.0.0 release](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.0.0)).

Do not make Aurora the only client yet. It is a seven-month-old fork, it is 185 commits ahead of and 27 commits behind upstream, and most fork-specific commits come from two people. The C3 reports are useful warnings, but they do not isolate the client from the host, network, television firmware, or decoder. The two clients use different webOS application IDs, so there is no need to accept this maintenance risk before an A/B test ([GitHub comparison API](https://api.github.com/repos/mariotaku/moonlight-tv/compare/main...GuiDev1994:main), [Aurora contributor API](https://api.github.com/repos/GuiDev1994/aurora-tv/contributors?per_page=100), [Aurora Homebrew manifest](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/deploy/webosbrew/com.aurora.gamestream.yml#L17-L25)).

## Local requirements and setup

The client must preserve these local hard requirements:

- The stream is 3840x2160 at 120 Hz with true HDR10. Gamescope renders Steam Big Picture on the HDMI dummy plug, and Sunshine captures that output through KMS with VAAPI 10-bit HEVC ([ADR 0006](../adr/0006-stream-steam-session-via-hdmi-dummy-plug.md), [Polaris vs Sunshine research](./polaris-vs-sunshine.md)).
- Sunshine must start after gamescope has acquired DRM and presented on the dummy plug. Sunshine probes its encoder once at startup. Starting against a modeless connector causes `503: failed to initialize video capture/encoding` for either client. The client cannot correct this host failure ([ADR 0006](../adr/0006-stream-steam-session-via-hdmi-dummy-plug.md)).
- Sunshine runs only in the isolated Steam Session. Hyprland is not streamed. `output_name` stays unset because the Steam Session has no reachable Wayland display for name resolution, and the KMS backend selects the dummy plug as the first active plane ([ADR 0006](../adr/0006-stream-steam-session-via-hdmi-dummy-plug.md)).
- The host baseline remains Sunshine. The earlier host comparison found its current KMS, AMD VAAPI, true-HDR, NixOS packaging, and declarative configuration path stronger than Polaris for this machine ([Polaris vs Sunshine research](./polaris-vs-sunshine.md)). This client trial must not change the host at the same time.

The client also needs dependable controller input. Keyboard and mouse support are useful for Steam Session recovery and desktop-style launchers. Stable 5.1 audio is desirable, but it is not stated as a hard requirement in ADR 0006.

## Comparison

| Area | Moonlight TV | Aurora TV | Assessment for this setup |
|---|---|---|---|
| Project scope | General Moonlight client for LG webOS and other embedded targets ([README](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/README.md)) | Fork focused on LG webOS C1 through C5 and compatible sets ([README](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md)) | Aurora is more directly aligned with the C3 |
| 3840x2160 at 120 FPS | The settings include 3840x2160 and 120 FPS, subject to the detected panel and decoder limits ([resolution source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/settings/panes/pref_res.c#L37-L44), [FPS source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/settings/panes/basic.pane.c#L100-L107)) | README offers 4K and 120 FPS, and webOS stream setup clamps rates above 120 rather than below it ([README](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md), [session source](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/src/app/stream/session.c#L273-L292)) | Both can request the required mode. Aurora has more C-series tuning, but needs C3 validation |
| HEVC Main10 HDR10 | Negotiates HEVC Main10 when the decoder reports it ([session source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/stream/session.c#L44-L60)) | Advertises HDR10 PQ over HEVC Main10 and sets BT.2020, PQ, and limited range for HDR ([README](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md), [negotiation source](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/src/app/stream/session.c#L329-L358), [HDR mapping source](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/src/app/stream/session.c#L380-L398)) | Both fit the host format. Aurora states the intended HDR mapping more clearly |
| Bitrate | The UI follows the decoder-reported maximum. Upstream rejected a C3 request to exceed 65 Mbps as not planned ([settings source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/settings/panes/basic.pane.c#L118-L123), [issue #364](https://github.com/mariotaku/moonlight-tv/issues/364)) | README advertises up to 300 Mbps and recommends 120 to 180 Mbps initially, with 250 Mbps as a practical ceiling ([README](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md)) | Aurora provides a path to test above the upstream cap, but high values are outside LG's published webOS 23 limits |
| Diagnostics | Has a status overlay, performance statistics, soft keyboard, and virtual mouse. v1.6.36 simplified the performance overlay ([v1.6.36](https://github.com/mariotaku/moonlight-tv/releases/tag/v1.6.36), [overlay source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/streaming/streaming.controller.c), [input source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/settings/panes/input.pane.c)) | Adds compact and full performance views, bitrate and frame-loss data, an on-screen log, a full keyboard, and gamepad-driven virtual mouse controls ([README](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md)) | Aurora makes a C3 A/B test easier. The basic tools are not exclusive to Aurora |
| AV1 at 120 FPS | v1.6.36 can negotiate AV1 Main8 or Main10 when the decoder exposes it ([session source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/stream/session.c#L55-L60)) | v1.2.9 only negotiates AV1 at 60 FPS or below and tells users to use HEVC at 120 FPS ([session source](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/src/app/stream/session.c#L335-L341)) | Use HEVC. Aurora's restriction matches its maintainer's reported webOS latency experience |
| Audio | v1.6.36 made no listed surround-path change ([release](https://github.com/mariotaku/moonlight-tv/releases/tag/v1.6.36)) | A C3 user reported a 5.1 channel regression. The maintainer fixed it in v1.2.2, while v1.2.9 again restored the upstream Opus path after later changes ([issue #63](https://github.com/GuiDev1994/aurora-tv/issues/63), [v1.2.2](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.2.2), [v1.2.9](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.2.9)) | Test 5.1. The repeated Aurora changes show active repair and audio-path churn |
| Side-by-side install | App ID is `com.limelight.webos` ([CMake source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/CMakeLists.txt#L100-L105)) | App ID is `com.aurora.gamestream`, explicitly separate from Moonlight TV ([CMake source](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/CMakeLists.txt#L100-L105), [Homebrew manifest](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/deploy/webosbrew/com.aurora.gamestream.yml#L17-L25)) | Install and pair both. No replacement is needed during the trial |

One source inconsistency matters during testing. Aurora's README says the bitrate slider reaches 300 Mbps, but the v1.2.9 settings UI source sets its slider maximum to 400,000 Kbps. The automatic bitrate helper returns 300,000 Kbps ([README](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md), [settings UI source](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/src/app/ui/settings/panes/basic.pane.c#L153-L160), [bitrate helper](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/src/app/app_settings.c#L320-L328)). Treat 300 Mbps as an advertised target, not a verified or consistently enforced limit. The README itself warns that gains above 250 Mbps are usually small and packet loss becomes more likely.

## C3-specific evidence

LG specifies the C3 as a 3840x2160 OLED with a native 120 Hz panel, HDR10 support, and webOS 23 ([LG C3 product specification](https://www.lg.com/ca_en/tv-soundbars/oled-evo/oled65c3pua/)). The panel therefore matches the target output mode.

The documented webOS 23 application decoder envelope is narrower. LG documents 4K HEVC Main or Main10 at up to 60 FPS and 60 Mbps. It does not document 4K120 app decoding or 300 Mbps HEVC on this platform ([LG webOS 23 audio and video format specification](https://webostv.developer.lge.com/develop/specifications/video-audio-230)). Moonlight TV's maintainer cited that specification when closing the C3 high-bitrate request and reported a high crash chance above 65 Mbps and worsening performance above 40 Mbps ([issue #364 maintainer comments](https://github.com/mariotaku/moonlight-tv/issues/364#issuecomment-1932011117)). Aurora deliberately ignores the webOS decoder's conservative advertised bitrate cap, so its higher operating range depends on private decoder behavior and television-specific testing ([Aurora session source](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/src/app/stream/session.c#L316-L325)). LG's published limits are for its supported audio and video formats, not a controlled test of either GameStream client, so they are a risk boundary rather than proof that Aurora cannot work.

The issue trackers provide these C3 observations:

- Aurora issue #58 reports that one C3 became unstable above about 25 to 30 Mbps with two USB Ethernet adapters. The reporter also observed the behavior with the older Moonlight TV client. The maintainer closed it as a webOS or network limitation, not an Aurora defect ([issue #58](https://github.com/GuiDev1994/aurora-tv/issues/58), [maintainer closure](https://github.com/GuiDev1994/aurora-tv/issues/58#issuecomment-5192446111)). This report does not isolate the router, USB stack, decoder, client, or host.
- Aurora issue #63 reports incorrect 5.1 channel mapping on a C3 with Apollo after Aurora v1.1.10. The maintainer marked it fixed in v1.2.2 by preferring Opus again ([issue #63](https://github.com/GuiDev1994/aurora-tv/issues/63), [fix comment](https://github.com/GuiDev1994/aurora-tv/issues/63#issuecomment-5372212445)).
- Aurora issue #67 reports that the C3 displayed 8-bit output and oversaturated color when the user requested 10-bit SDR from Apollo. The reporter still reproduced it on v1.2.5. The maintainer attributed it to the host and closed the issue for no response, without a confirmed resolution ([issue #67](https://github.com/GuiDev1994/aurora-tv/issues/67), [last reproduction](https://github.com/GuiDev1994/aurora-tv/issues/67#issuecomment-5424884111), [closure](https://github.com/GuiDev1994/aurora-tv/issues/67#issuecomment-5560850301)). This setup requires HDR10 rather than 10-bit SDR, but the report is relevant to color-path maturity.
- Moonlight TV issue #364 came from a C3 user who wanted more than 65 Mbps for 4K120. Upstream closed the request as not planned because it considered the webOS decoder limit unsafe ([issue #364](https://github.com/mariotaku/moonlight-tv/issues/364)). This is a deliberate stability policy, not proof that the C3 cannot decode a higher GameStream bitrate.
- In Aurora discussion #1, the maintainer reported high AV1 input latency outside LG G-series televisions at 120 FPS ([maintainer reply](https://github.com/GuiDev1994/aurora-tv/discussions/1#discussioncomment-17724696)). Aurora now blocks AV1 negotiation above 60 FPS in code. This is maintainer experience rather than a controlled C3 comparison.

No reviewed primary source contains a controlled, same-host, same-network C3 comparison between Moonlight TV v1.6.36 and Aurora v1.2.9. Aurora's strongest published tuning evidence is for other C-series sets, especially C5. The C3 issue reports must not be read as benchmark results.

## Maintenance and releases

| Evidence as of 2026-09-19 | Moonlight TV | Aurora TV |
|---|---|---|
| Repository history | Created 2020-12-30 ([repository API](https://api.github.com/repos/mariotaku/moonlight-tv)) | Fork created 2026-02-22 ([repository API](https://api.github.com/repos/GuiDev1994/aurora-tv)) |
| Latest release | v1.6.36, published 2025-10-18 ([release](https://github.com/mariotaku/moonlight-tv/releases/tag/v1.6.36)) | v1.2.9, published 2026-09-10 ([release](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.2.9)) |
| Current branch activity | Main received an input fix on 2026-09-17, so development continued after the latest release ([commit](https://github.com/mariotaku/moonlight-tv/commit/cf96ecc72cdab3aae7ba0698f463b89065ae7e3b)) | Main last changed with v1.2.9's selective upstream port on 2026-09-10 ([commit](https://github.com/GuiDev1994/aurora-tv/commit/375ee6f710ee9254c0199d6be4dde574221886af)) |
| Fork divergence | Baseline | Aurora is 185 commits ahead and 27 behind ([comparison API](https://api.github.com/repos/mariotaku/moonlight-tv/compare/main...GuiDev1994:main)) |
| GitHub stars | 1,479 ([repository API](https://api.github.com/repos/mariotaku/moonlight-tv)) | 113 ([repository API](https://api.github.com/repos/GuiDev1994/aurora-tv)) |
| Fork-specific contributors | Not applicable | GuiDev1994 has 142 commits and KrisEnigma has 28. Every other listed contributor has 3 or fewer ([contributor API](https://api.github.com/repos/GuiDev1994/aurora-tv/contributors?per_page=100)) |

Aurora has shipped frequently since its first stable release on 2026-03-15, but the release notes also show repeated changes to frame pacing, bitrate policy, AV1, and 5.1 audio ([v1.0.0](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.0.0), [release history](https://github.com/GuiDev1994/aurora-tv/releases)). v1.2.9 describes its update as a "selective upstream port" rather than a merge, so the 27 commits behind upstream need manual review and porting. Moonlight TV has the larger and older project, but its release channel has not incorporated the active 2026 main-branch work.

## Concrete risks

1. Aurora operates outside LG's documented 4K60 and 60 Mbps webOS 23 decoder envelope. A setting that starts successfully can still develop frame loss, decoder backlog, a black screen, or input delay during a long session ([LG webOS 23 specification](https://webostv.developer.lge.com/develop/specifications/video-audio-230), [Aurora v1.2.4 observations](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.2.4)).
2. Aurora's C1 through C5 support statement is broader than its published controlled evidence. Its release notes contain substantial C5 testing, while the C3 evidence is a small set of user reports with several variables ([README](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md), [release history](https://github.com/GuiDev1994/aurora-tv/releases), [C3 issues](https://github.com/GuiDev1994/aurora-tv/issues?q=is%3Aissue%20C3)).
3. Higher bitrate does not by itself improve this setup. Issue #58 reports the same C3 network failure in Aurora and older Moonlight TV. Raising bitrate can expose the television's USB Ethernet path, Wi-Fi, router buffering, packet bursts, or decoder before it improves visible quality ([issue #58](https://github.com/GuiDev1994/aurora-tv/issues/58), [Aurora bitrate warning](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/README.md)).
4. Aurora has a small maintainer base and a diverged code line. Selective upstream ports can omit security, input, protocol, or webOS compatibility fixes ([comparison API](https://api.github.com/repos/mariotaku/moonlight-tv/compare/main...GuiDev1994:main), [contributor API](https://api.github.com/repos/GuiDev1994/aurora-tv/contributors?per_page=100), [v1.2.9 selective port](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.2.9)).
5. Aurora's audio and frame-pacing paths have changed across several releases. The v1.2.2 5.1 fix and the v1.2.9 Opus restoration require a fresh 5.1 check on the actual C3 and audio route ([v1.2.2](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.2.2), [v1.2.9](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.2.9)).
6. The unresolved 10-bit SDR report used Apollo, not this repository's Sunshine HDR10 path. It must not be treated as a Sunshine HDR failure, but it shows that host, transfer function, and bit-depth combinations can be misidentified ([issue #67](https://github.com/GuiDev1994/aurora-tv/issues/67)).
7. Neither client can repair Sunshine's one-time failed KMS probe. If both clients receive `503`, diagnose the Steam Session and service ordering before comparing client behavior ([ADR 0006](../adr/0006-stream-steam-session-via-hdmi-dummy-plug.md)).

## Side-by-side trial plan

### Prepare

1. Install Moonlight TV v1.6.36 and Aurora v1.2.9 at the same time. Confirm that webOS lists `com.limelight.webos` and `com.aurora.gamestream` separately.
2. Pair both clients to the same Sunshine instance. Do not change Sunshine, gamescope, the dummy plug, VAAPI, the network path, C3 picture settings, or game settings during a comparison pair.
3. Confirm the Steam Session is active before connecting. If a client gets `503`, stop the comparison and fix the host startup failure.
4. Use HEVC, 3840x2160, 120 FPS, HDR enabled, and the same audio mode in both clients. Disable AV1 and adaptive bitrate for the first pass.
5. Choose one repeatable game scene with a slow camera pan, a high-motion section, dark gradients, bright HDR highlights, and continuous controller input.

### Run the common baseline

Use 40 Mbps, then 60 Mbps in both clients. Alternate the order on the second run so decoder warm-up and host state do not always favor the same client.

| Check | Method | Pass condition |
|---|---|---|
| Required mode | Record each client overlay and Sunshine log at stream start | 3840x2160, 120 FPS, HEVC Main10, HDR requested |
| HDR | Check the C3 HDR indication and compare a known HDR scene | HDR mode engages, highlights and dark gradients are credible, no SDR washout or oversaturation |
| Frame delivery | Run the same scene for 30 minutes twice | No black screen, freeze, disconnect, accumulating video delay, or sustained frame loss |
| Latency | Record network RTT, host latency, decoder latency, total latency, and observed controller response every five minutes | No rising trend during the run. Compare the medians rather than one sample |
| Input | Test the primary controller, overlay shortcut, on-screen keyboard, virtual mouse, and Steam navigation | No stuck key, duplicate input, lost controller, or delayed input after stream recovery |
| Audio | Test stereo, then 5.1 if used locally, with a channel-identification sample | Correct channel mapping and no dropouts |
| Recovery | Suspend or end the stream, then reconnect three times | Each reconnect restores video, HDR, audio, and input without restarting the TV app |

### Run Aurora's high-bitrate test

Test Aurora at 80, 120, and 180 Mbps. Stop increasing when packet loss, decoder latency, frame pacing, or input response gets worse. Do not jump to 250 or 300 Mbps because the project permits it. Only test those values if 180 Mbps is stable for a two-hour session and a visual comparison shows a repeatable benefit.

Run Moonlight TV at its highest exposed stable value as the control. This is not an equal-bitrate comparison. It answers whether Aurora's relaxed cap produces a visible gain without breaking the C3 path.

### Decide

Use Aurora as the default only if it passes every local hard requirement and either produces a visible quality gain at a stable bitrate or gives lower, more stable end-to-end latency. Keep Moonlight TV installed for regression checks and recovery.

Keep Moonlight TV as the default if Aurora develops delay, color errors, audio mapping errors, disconnects, or frame loss, even when Aurora's overlay reports the requested mode. If both fail at the same bitrate and network path, investigate the C3 network or decoder boundary before attributing the result to either client.
