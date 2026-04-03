# video/ (local pipeline)

Optional; **not** Butler CI. Vendor trees `video/tools/**` stay as-is.

## Entry

- `video/run_video_ai_pipeline.ps1` — `-InputVideo`, `-Mode auto|advanced`, `-ConfigPath`, `-Strict`
- `video/video_gui.ps1` — GUI
- `video/advanced.config.example.json` → copy to `advanced.config.json`

## Quick

```powershell
pwsh -File .\video\video_gui.ps1
pwsh -File .\video\run_video_ai_pipeline.ps1 -InputVideo ".\input.mp4" -Mode auto
```

Strict advanced:

```powershell
Copy-Item .\video\advanced.config.example.json .\video\advanced.config.json
pwsh -File .\video\run_video_ai_pipeline.ps1 -InputVideo ".\input.mp4" -Mode advanced -ConfigPath ".\video\advanced.config.json" -Strict
```

## Deps

`ffmpeg`/`ffprobe` in PATH; optional `realesrgan-ncnn-vulkan.exe`, AnimeGAN/DeOldify scripts per config.

## Output

`video/jobs/<name>_<ts>/frames_24fps`, `.../outputs` (final MP4s).
