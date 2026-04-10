# handbrakecli-nvidia

`handbrakecli-nvidia` 是一个基于 Ubuntu 的 Docker 镜像，内置自编译的 `HandBrakeCLI`，面向 **NVIDIA GPU 硬件转码** 场景，适合在 Linux / NAS / Unraid / Docker 环境中使用。

这个镜像的目标是：

- 在容器中使用 `HandBrakeCLI`
- 支持 NVIDIA `NVENC` 硬件编码
- 可选支持 `NVDEC` 硬件解码（取决于构建方式和转码参数）
- 避开 Flatpak / GUI 依赖，更适合自动化和脚本批量处理

## 特性

- 基于 Docker，方便部署
- 使用 `HandBrakeCLI`
- 支持 NVIDIA GPU 加速
- 适合命令行参数化转码
- 支持导入 HandBrake GUI 导出的 preset JSON 进行转码
- 适合批处理、自动化任务、NAS 场景

---

## 前提条件

在使用本镜像前，请确认宿主机已经满足以下条件：

- 已正确安装 NVIDIA 驱动
- 已正确安装 Docker
- 已正确安装并配置 NVIDIA Container Toolkit
- `docker run --gpus all ...` 可以正常使用 GPU

建议先在宿主机验证：

```bash
nvidia-smi
```

---

## Docker Hub

镜像地址：

```bash
sczhengyabin/handbrakecli-nvidia
```

拉取镜像：

```bash
docker pull sczhengyabin/handbrakecli-nvidia:latest
```

---

## 快速开始

### 查看版本

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  sczhengyabin/handbrakecli-nvidia:latest \
  --version
```

### 查看当前 build 支持的编码器

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  sczhengyabin/handbrakecli-nvidia:latest \
  --help | grep -i -E 'nvenc|nvdec|h264|h265|av1'
```

---

## 挂载目录约定

推荐把宿主机目录挂载到容器中的 `/work`：

```bash
-v /path/to/videos:/work
```

例如你的宿主机目录结构：

```text
/path/to/videos/
  input.mp4
  output.mp4
  presets/
    mypreset.json
```

容器内就对应为：

```text
/work/input.mp4
/work/output.mp4
/work/presets/mypreset.json
```

---

# 用法一：使用命令行参数直接转码

这种方式适合：

- 手工调参数
- 写脚本批量转码
- 不依赖 GUI preset
- 想清楚控制编码器、质量、容器格式等

## 例 1：使用 NVENC H.265 转码为 MP4

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

说明：

- `-i`：输入文件
- `-o`：输出文件
- `-f av_mp4`：输出 MP4 容器
- `-e nvenc_h265`：使用 NVIDIA H.265 硬件编码
- `-q 24`：恒定质量模式，数值越小画质越高、体积通常越大
- `--vfr`：可变帧率
- `-B 160`：音频码率 160 kbps

## 例 2：使用 NVENC H.264 转码

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

这个版本通常兼容性更好，适合老设备或通用播放场景。

## 例 3：限制输出为 1080p

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

# 用法二：使用 HandBrake GUI 导出的 preset JSON 转码

这种方式适合：

- 已经在 Windows / macOS GUI 里调好了 preset
- 想在服务器 / Docker 环境复用 GUI 预设
- 不想手工把 preset 参数一个个改成 CLI 参数

## 1. 在 GUI 中导出 preset

先在 HandBrake GUI 中导出自定义 preset，得到一个 `.json` 文件，例如：

```text
mypreset.json
```

然后把它放到宿主机目录中，例如：

```text
/path/to/videos/presets/mypreset.json
```

## 2. 先查看 preset 是否能被识别

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  -v /path/to/videos:/work \
  sczhengyabin/handbrakecli-nvidia:latest \
  --preset-import-file /work/presets/mypreset.json -z
```

这会列出导入后的 preset 名称。

## 3. 使用 preset 进行转码

假设你的 preset 名称叫 `NV28MP4`：

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

## preset 使用建议

- 最稳妥的方式是：**先用 `-z` 列出 preset 名称，再按名称调用**
- 如果 preset 中包含当前 build 不支持的编码器或硬件能力，转码时可能会失败
- Windows GUI 导出的 preset 一般可以在 Linux CLI 中使用，但硬件相关选项仍取决于当前容器 build 和宿主机 GPU 环境

---

## 常见问题

## 1. 为什么要加 `NVIDIA_DRIVER_CAPABILITIES=compute,utility,video`

因为仅有 `--gpus all` 往往还不够。  
为了让容器访问 NVIDIA 视频编码/解码相关驱动库，通常需要显式开启 `video` capability。

推荐始终带上：

```bash
-e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video
```

## 2. `nvidia-smi` 能用，但 HandBrake 仍然不能用 NVENC

请检查：

- 宿主机 NVIDIA 驱动是否正常
- 是否已安装 NVIDIA Container Toolkit
- 是否添加了 `NVIDIA_DRIVER_CAPABILITIES=compute,utility,video`
- 当前 build 是否真的包含所需编码器

可用下面命令确认：

```bash
docker run --rm -it \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
  sczhengyabin/handbrakecli-nvidia:latest \
  --help | grep -i nvenc
```

---

## 示例：批量转码

下面是一个简单的批量脚本示例，把当前目录下所有 `.mkv` 转成 `.mp4`：

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

## 许可

请遵循 HandBrake 本身及相关依赖项目的许可要求。  
本镜像仓库中的 Docker 构建脚本和说明文档可按仓库中声明的许可证使用。

---

## 免责声明

本镜像仅用于方便在容器环境中运行 `HandBrakeCLI`。  
NVIDIA 硬件加速的可用性取决于：

- 宿主机驱动
- Docker / NVIDIA Container Toolkit 配置
- GPU 型号
- HandBrake 当前 build 选项
- 实际转码参数
