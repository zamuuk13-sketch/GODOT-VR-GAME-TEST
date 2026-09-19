$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$assets = Join-Path $root "handtracking/src/main/assets"
New-Item -ItemType Directory -Force -Path $assets | Out-Null

$url = "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task"
$out = Join-Path $assets "hand_landmarker.task"

Write-Host "Downloading MediaPipe Hand Landmarker model..."
Invoke-WebRequest -Uri $url -OutFile $out
Write-Host "Saved: $out"
