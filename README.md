# Flux 2 Klein Automated Installer for RunPod 🚀

This repository provides a 1-click installation script to set up ComfyUI with the Flux 2 Klein (9B) model on RunPod. It is configured for high VRAM GPUs and automatically downloads the Q8_0 and FP8 models.

## How to Set Up the RunPod Template

1. Go to **Templates** in RunPod and click **New Template**.
2. **Template Name:** `Flux 2 Klein Auto-Installer` 
3. **Container Image:** `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
4. **Container Disk:** `100 GB`
5. **Volume Disk:** `100 GB`
6. **Exposed HTTP Ports:** `8188`
7. **Docker Command:** Paste the following line exactly:

bash -c "wget -qO- https://raw.githubusercontent.com/bobthebuildercontainer-stack/RunPod-Flux-2-Klein-Installer/main/install_flux.sh | bash"

## How to Deploy
1. Go to **Pods** -> **Deploy**.
2. Select your GPU (e.g., H200).
3. Choose the `Flux 2 Klein Auto-Installer` template from your custom templates.
4. Click Deploy. The pod will boot, install all nodes, download the required models, and automatically start the UI.
5. Connect to **Port 8188**.
