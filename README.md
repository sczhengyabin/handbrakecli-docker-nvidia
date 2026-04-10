# handbrakecli-nvidia

`handbrakecli-nvidia` is a Docker image based on Ubuntu, with a self-built `HandBrakeCLI` inside, designed for **NVIDIA GPU hardware transcoding** on Linux / NAS / Unraid / Docker environments.

The goal of this image is to:

- Run `HandBrakeCLI` inside a container
- Support NVIDIA `NVENC` hardware encoding
- Optionally support `NVDEC` hardware decoding, depending on build options and transcoding parameters
- Avoid Flatpak / GUI dependencies and make CLI automation easier

## Features

- Docker-based deployment
- Uses `HandBrakeCLI`
- Supports NVIDIA GPU acceleration
- Suitable for parameter-based CLI transcoding
- Supports using preset JSON files exported from HandBrake GUI
- Good for batch jobs, automation, and NAS use cases

---

## Requirements

Before using this image, make sure the host system already has:

- NVIDIA driver installed correctly
- Docker installed correctly
- NVIDIA Container Toolkit installed and configured correctly
- Working GPU access with `docker run --gpus all ...`

It is recommended to verify on the host first:

```bash
nvidia-smi
```

---

## Docker Hub

Image name:

```bash
sczhengyabin/handbrakecli-nvidia
```

Pull the image:

```bash
docker pull sczhengyabin/handbrakecli-nvidia:latest
```

---

## Quick Start

### Show version

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  sczhengyabin/handbrakecli-nvidia:latest \
  --version
```

### Show supported encoders in the current build

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  sczhengyabin/handbrakecli-nvidia:latest \
  --help | grep -i -E 'nvenc|nvdec|h264|h265|av1'
```

---

## Directory Mount Convention

It is recommended to mount a host directory to `/work` inside the container:

```bash
-v /path/to/videos:/work
```

For example, on the host:

```text
/path/to/videos/
  input.mp4
  output.mp4
  presets/
    mypreset.json
```

Inside the container it becomes:

```text
/work/input.mp4
/work/output.mp4
/work/presets/mypreset.json
```

---

# Usage 1: Direct transcoding with CLI parameters

This method is suitable when you want to:

- tune parameters manually
- write batch scripts
- avoid GUI presets
- explicitly control encoder, quality, format, and other settings

## Example 1: Transcode to MP4 with NVENC H.265

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  -v /path/to/videos:/work \
  sczhengyabin/handbrakecli-nvidia:latest \
  --enable-hw-decoding nvdec \
  -i /work/input.mkv \
  -o /work/output.mp4 \
  -f av_mp4 \
  -e nvenc_h265 \
  -q 24 \
  --vfr \
  -B 160
```

Explanation:

- `-i`: input file
- `-o`: output file
- `-f av_mp4`: MP4 container
- `-e nvenc_h265`: NVIDIA H.265 hardware encoder
- `-q 24`: constant quality mode; lower value usually means higher quality and larger file size
- `--vfr`: variable frame rate
- `-B 160`: audio bitrate set to 160 kbps

## Example 2: Transcode with NVENC H.264

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  -v /path/to/videos:/work \
  sczhengyabin/handbrakecli-nvidia:latest \
  --enable-hw-decoding nvdec \
  -i /work/input.mkv \
  -o /work/output.mp4 \
  -f av_mp4 \
  -e nvenc_h264 \
  -q 22 \
  --vfr \
  -B 160
```

This version is usually more compatible with older devices and general playback scenarios.

## Example 3: Limit output to 1080p

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  -v /path/to/videos:/work \
  sczhengyabin/handbrakecli-nvidia:latest \
  --enable-hw-decoding nvdec \
  -i /work/input.mkv \
  -o /work/output.mp4 \
  -f av_mp4 \
  -e nvenc_h265 \
  -q 24 \
  -w 1920 \
  -l 1080 \
  --crop 0:0:0:0 \
  --vfr
```

---

# Usage 2: Transcoding with preset JSON exported from HandBrake GUI

This method is suitable when you:

- already created a preset in HandBrake GUI on Windows or macOS
- want to reuse that preset in Docker or server environments
- do not want to manually translate every preset setting into CLI options

## 1. Export a preset from HandBrake GUI

Export your custom preset from HandBrake GUI as a `.json` file, for example:

```text
mypreset.json
```

Place it in your host directory, for example:

```text
/path/to/videos/presets/mypreset.json
```

## 2. Verify the preset can be recognized

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  -v /path/to/videos:/work \
  sczhengyabin/handbrakecli-nvidia:latest \
  --preset-import-file /work/presets/mypreset.json -z
```

This will list the preset names found in the JSON file.

## 3. Use the preset for transcoding

Assume your preset name is `NV28MP4`:

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  -v /path/to/videos:/work \
  sczhengyabin/handbrakecli-nvidia:latest \
  --enable-hw-decoding nvdec \
  --preset-import-file /work/presets/mypreset.json \
  -Z "NV28MP4" \
  -i /work/input.mkv \
  -o /work/output.mp4
```

---

## Preset usage notes

- The safest workflow is: **use `-z` first to list preset names, then call the preset by name**
- If the preset includes encoders or hardware features not available in the current build, transcoding may fail
- Presets exported from HandBrake GUI on Windows usually work with Linux CLI, but hardware-specific features still depend on the current build and host GPU environment

---

## FAQ

## 1. Why do I need `NVIDIA_DRIVER_CAPABILITIES=compute,utility,video`?

Because `--gpus all` alone is often not enough.  
To make NVIDIA video encode/decode related driver libraries available inside the container, the `video` capability usually needs to be enabled explicitly.

Recommended:

```bash
-e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video
```

## 2. `nvidia-smi` works, but HandBrake still cannot use NVENC

Please check:

- Whether the NVIDIA driver on the host is working properly
- Whether NVIDIA Container Toolkit is installed
- Whether `NVIDIA_DRIVER_CAPABILITIES=compute,utility,video` is included
- Whether the current build actually contains the required encoders

You can verify with:

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  sczhengyabin/handbrakecli-nvidia:latest \
  --help | grep -i nvenc
```

---

## Example: Batch transcoding

Here is a simple example that converts all `.mkv` files in a directory to `.mp4`:

```bash
for f in /path/to/videos/*.mkv; do
  base="$(basename "$f" .mkv)"
  docker run --rm \
    --gpus all \
    -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
    -v /path/to/videos:/work \
    sczhengyabin/handbrakecli-nvidia:latest \
    --enable-hw-decoding nvdec \
    -i "/work/${base}.mkv" \
    -o "/work/${base}.mp4" \
    -f av_mp4 \
    -e nvenc_h265 \
    -q 24 \
    --vfr
 done
```

---

## License

Please follow the license requirements of HandBrake itself and all related dependencies.  
The Docker build scripts and documentation in this repository may be used according to the license declared in the repository.

---

## Disclaimer

This image is only intended to make it easier to run `HandBrakeCLI` in container environments.  
Availability of NVIDIA hardware acceleration depends on:

- host drivers
- Docker / NVIDIA Container Toolkit configuration
- GPU model
- current HandBrake build options
- actual transcoding parameters
