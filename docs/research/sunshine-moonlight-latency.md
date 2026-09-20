# Sunshine and Moonlight latency

Research date: 2026-09-20.

## Conclusion

The reported host latency of 21 ms and decoder latency of 10 ms do not prove a cause or an exact end-to-end delay.
No setting change has a verified or guaranteed millisecond gain for this session.
Identify the active client, decoder, stream, and host configuration before changing them.
This note records source research and proposed tests, not measurements from the TV.
No system configuration changes or builds were performed.

## Local context

The user reports an RX 7900 XTX, but the GPU model does not identify the active encoder backend.
The repository explicitly sets `encoder = vaapi`, `capture = kms`, and `vaapi_strict_rc_buffer = enabled` in [sunshine.nix, lines 14-18](../../modules/home-manager/sunshine.nix#L14-L18).
The gamescope session requests 2560x1440 at 120 Hz on HDMI-A-1 in [gaming.nix, lines 30-46](../../modules/nixos/gaming.nix#L30-L46).
That configuration comments out HDR environment variables and flags during RDNA3 illegal-opcode hangs.
The earlier [client comparison](./moonlight-tv-vs-aurora-tv.md) describes 4K120 HDR and an LG C3 with Moonlight TV.
Its 4K120 HDR description is stale for the current gamescope configuration.
The user subsequently confirmed switching to Aurora TV; the installed version and active decoder remain unconfirmed.
The active system generation, session, capture output, stream dimensions, HDR state, and client version remain unconfirmed.
Files in the repository do not establish which configuration the running process loaded.

## Host measurement

Sunshine's stable [v2026.914.233613 source](https://github.com/LizardByte/Sunshine/blob/v2026.914.233613/src/stream.cpp#L1575-L1603) computes host processing latency from `steady_clock::now() - *packet->frame_timestamp`.
It writes this value while preparing the video frame header, before later FEC and transmission work.
The verified [KMS implementation](https://github.com/LizardByte/Sunshine/blob/7e4a74010450f40f68e8b730f706ed83524d2a5e/src/platform/linux/kmsgrab.cpp#L1526-L1545) assigns the timestamp during framebuffer capture.
Thus, this interval includes capture work after that timestamp, conversion, encoding, and intervening waits, rather than isolated encoder execution.
It does not measure the game's earlier rendering or every stage of the capture operation.
The KMS citation pins a source revision; the installed Sunshine build must still be checked against its own source.

Moonlight-TV's [v1.6.36 overlay](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/streaming/streaming.controller.c#L86-L100) calculates host milliseconds as `totalCaptureLatency / submittedFrames / 10`.
The [protocol header](https://github.com/moonlight-stream/moonlight-common-c/blob/c86e0537d11566f9825d6323711ec61e3e702365/src/Limelight.h) defines `frameHostProcessingLatency` in tenths of a millisecond.
It specifies zero when latency is unavailable or not applicable, including repeated frames.
Those zeros can lower the displayed average, so an idle scene and a moving scene need not produce comparable host averages.
The [submission code](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/stream/video/session_video.c) accumulates host values before checking feed success, while the overlay divides by successful submissions.
Feed failures can therefore make the numerator and denominator cover different frame sets.
The reported 21 ms merits investigation, but does not identify encoding, GPU load, capture, or waiting as the cause.

## NDL measurement

This explanation applies to Moonlight-TV using the `ndl-webos5` backend, not every Moonlight client or decoder.
The [overlay source](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/streaming/streaming.controller.c#L95-L100) displays average submission time plus the backend's average decoder estimate.
The [submission path](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/stream/video/session_video.c) times the interval from complete frame assembly through return from `SS4S_PlayerVideoFeed()`.
The [NDL dependency pinned by v1.6.36](https://github.com/mariotaku/ss4s/blob/9cbad6a97b951aaf8d957b84f14b652ddb3dd5d2/modules/webos/ndl/webos5/ndl_video.c#L87-L94) supplies this estimate:

```c
float bufLen = renderBufferLength > 0 ? (float) renderBufferLength : 0.5f;
float latency = bufLen * (float) (now - context->lastFrameTime);
```

The interval is between successive feed timestamps, in microseconds, not measured hardware decode start and completion.
An empty render queue still contributes a 0.5-frame estimate.
At steady 120 FPS, this fallback is approximately 4.17 ms before submission time is added.
At steady 60 FPS, it is approximately 8.33 ms before submission time is added.
These values follow from the formula; they are not measurements from this TV.
Host stalls and irregular delivery can change this estimate without proving slower hardware decoding.
Do not calculate decoder throughput as `1000 / decoder_latency_ms` or infer a 100 FPS ceiling from 10 ms.

The [dependency pinned by the inspected current main revision](https://github.com/mariotaku/ss4s/blob/dfba721b85420ccabf91dac65be73984bf1865f9/modules/webos/ndl/webos5/ndl_video.c#L87-L94) retains the same NDL formula.
However, [main uses microsecond submission timing](https://github.com/mariotaku/moonlight-tv/blob/cf96ecc72cdab3aae7ba0698f463b89065ae7e3b/src/app/stream/video/session_video.c), while v1.6.36 uses milliseconds.
[SS4S defaults decoder averaging to one second](https://github.com/mariotaku/ss4s/blob/9cbad6a97b951aaf8d957b84f14b652ddb3dd5d2/src/player.c#L107-L121), so a single average can conceal spikes.
Confirm the version and backend before applying these formulas to the reported values.

## Aurora follow-up

Aurora [v1.2.9](https://github.com/GuiDev1994/aurora-tv/releases/tag/v1.2.9) is the latest release checked on 2026-09-20, not a confirmed installed version.
Its [overlay implementation](https://github.com/GuiDev1994/aurora-tv/blob/v1.2.9/src/app/ui/streaming/streaming.controller.c) separates submission time `S`, decoder estimate `D`, and host processing `En` in the compact view.
Despite the `En` label, the host value is not isolated encoder execution time.
The full view displays decoder latency as submission time plus decoder estimate, with both numbers visible.
Its displayed total is `network RTT + host processing + submission time + decoder estimate`.
That sum is not a measured physical button-to-screen delay and does not include the game's Internet server RTT.
The green/yellow/red indicator also uses that sum, so its color does not establish actual input latency.

Aurora's [pinned NDL dependency](https://github.com/GuiDev1994/ss4s/blob/af678d2643f41e07ac8ac92b4976119734229080/modules/webos/ndl/webos5/ndl_video.c) retains the buffer-length times feed-interval estimate and the 0.5-frame fallback for both HEVC and AV1 paths.
The 4.17 ms at 120 FPS and 8.33 ms at 60 FPS caveats therefore also apply to that Aurora backend.
Unlike Moonlight-TV's combined decoder value, Aurora's compact `D` excludes the separately shown submission time.
Obtain the Aurora version and full overlay before comparing the reported 10 ms with previous client measurements.
The Moonlight-TV baseline guidance below is conditional reference material, not confirmation of Aurora's active settings.

## Corrections and limits

Adding 21 ms and 10 ms does not produce an exact button-to-photon delay because the cited metrics do not cover all input, game, network, and display stages.
Network health cannot be inferred from host and decoder values alone; inspect RTT variation, received FPS, drops, and symptoms together.
The [protocol API](https://github.com/moonlight-stream/moonlight-common-c/blob/c86e0537d11566f9825d6323711ec61e3e702365/src/Limelight.h) describes RTT as an ENet control-stream estimate, not one-way video transit time.
A claimed 10 ms Bluetooth contribution was hypothetical, not measured on this controller and TV.
Internet game-server RTT must not be added to every local action as a mandatory delay.
[Epic's character movement documentation](https://dev.epicgames.com/documentation/en-us/unreal-engine/understanding-networked-movement-in-the-character-movement-component-for-unreal-engine) explains that autonomous proxies process movement locally, then send it to the server for reproduction and correction.
This is evidence for client prediction, not proof that every action in the unidentified game uses it.
The game client running on the streaming host is distinct from the Moonlight video client.

An RX 7900 XTX does not imply AMF; the local configuration explicitly selects Linux VAAPI.
HAGS and NVENC advice does not apply to that configured Linux VAAPI path.
Encoder presets and available options depend on the Sunshine version and backend, so generic preset advice cannot guarantee latency gains.
Preset changes are a future controlled experiment, not the primary fix before session identification and load tests.
AV1 is not universally faster: Moonlight-TV's [video settings](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/settings/panes/video.pane.c#L106-L116) warn that it "might be much slower than H265 or H264."

## webOS guidance

The upstream [FAQ](https://github.com/mariotaku/moonlight-tv/wiki/FAQs) recommends NDL over SMP and describes 35-40 Mbps as a quality/performance starting point.
These are upstream recommendations, not controlled C3 measurements or universal settings.
The [settings code](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/settings/panes/basic.pane.c) can offer 120 FPS, and [resolution settings](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/settings/panes/pref_res.c) include 3840x2160.
Selectable 4K120 does not prove sustained decoding or presentation on the actual TV.
[LG's webOS 23 specification](https://webostv.developer.lge.com/develop/specifications/video-audio-230) documents HEVC Main/Main10 at 3840x2160@60P and 60 Mbps, not guaranteed 4K120 app decoding.
That supported-format specification does not prove that private NDL operation cannot exceed it.
[Moonlight-TV negotiates Main10 when HDR and decoder capabilities permit](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/stream/session.c), but a checkbox does not establish an HDR source.
Leave HDR disabled while the local RDNA3 hang issue remains unresolved.
Do not prescribe switching clients, changing backends, or raising bitrate without measured evidence.

## Test priorities

1. Capture the full overlay and About screen, plus the matching active Sunshine session log.
Record versions, decoder ID, capture/encoder selection, codec, dimensions, requested and received FPS, bitrate, HDR, RTT variation, and drops.
Confirm the active generation and session rather than assuming the checked-in files are deployed.

2. Establish a repeatable moving-scene baseline using the actual working SDR session.
If it matches the local 1440p120 configuration and Moonlight-TV NDL is confirmed, HEVC with AV1 off and 35 Mbps is an example baseline, not a universal recommendation.
Record the existing decoder before any change, and do not force NDL solely because previous notes mentioned it.

3. Change only one setting per A/B pair and repeat the same scene for several minutes.
Record visible response, latency ranges, spikes, received FPS, and drops rather than one screenshot average.
Recheck bitrate after resolution or FPS changes because [Moonlight-TV can raise it automatically](https://github.com/mariotaku/moonlight-tv/blob/v1.6.36/src/app/ui/settings/panes/basic.pane.c).

4. At fixed stream settings, compare a lighter GPU scene, or separately lower game quality or apply a game FPS cap.
This tests sensitivity to game load without also changing the stream mode, but does not isolate every capture or encoder wait.

5. Test bitrate from 35 to 25 Mbps, then separately test 1440p versus 1080p at fixed stream FPS and bitrate.
Use equivalent lower values if the established baseline differs, and restore the baseline between pairs.
If reducing 120 to 60 FPS later, account for the NDL fallback changing from about 4.17 to 8.33 ms.

6. Compare Bluetooth with USB input if the same controller and client support both, keeping the input endpoint and stream unchanged.
Treat the difference as an observation, not an assumed 10 ms saving.

7. Test another existing Moonlight client at a matched mode if available, as the [upstream troubleshooting guide](https://github.com/mariotaku/moonlight-tv/wiki/Troubleshooting) suggests.
Compare host values, delivery, and visible response, but do not directly compare decoder metrics with different definitions.
This is an isolation test, not a recommendation to replace Moonlight-TV with Aurora or another client.

8. If the overlay and experienced delay disagree, film repeatable physical input and screen response, and compare with the overlay hidden.
Only measured results should determine the next experiment; these proposals establish neither a cause nor guaranteed millisecond gains.
