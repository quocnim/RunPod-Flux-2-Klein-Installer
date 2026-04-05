#!/bin/bash
echo "Starting Fully Automated Flux 2 Klein Setup..."

# 1. Enter permanent storage and get ComfyUI
cd /workspace
if [ ! -d "ComfyUI" ]; then
    echo "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd ComfyUI

# 2. Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -U pip setuptools wheel

# 3. Install Torch & Dependencies
pip install --index-url https://download.pytorch.org/whl/cu121 --extra-index-url https://pypi.org/simple torch==2.4.0+cu121 torchvision==0.19.0+cu121 torchaudio==2.4.0+cu121
pip uninstall -y opencv-python || true
pip install opencv-python-headless==4.12.0.88 "pillow>=11.0.0"
pip install gguf piexif librosa || true
pip install -U google-generativeai google-ai-generativelanguage || true

# 4. Navigate to custom_nodes and clone repositories
cd custom_nodes
[ ! -d "ComfyUI-Manager" ] && git clone https://github.com/ltdrdata/ComfyUI-Manager.git
[ ! -d "ComfyUI-GGUF" ] && git clone https://github.com/city96/ComfyUI-GGUF.git
[ ! -d "rgthree-comfy" ] && git clone https://github.com/rgthree/rgthree-comfy.git
[ ! -d "ComfyUI-Easy-Use" ] && git clone https://github.com/yolain/ComfyUI-Easy-Use.git
[ ! -d "ComfyUI-KJNodes" ] && git clone https://github.com/kijai/ComfyUI-KJNodes.git
[ ! -d "ComfyUI_essentials" ] && git clone https://github.com/cubiq/ComfyUI_essentials.git
[ ! -d "wlsh_nodes" ] && git clone https://github.com/wallish77/wlsh_nodes.git
[ ! -d "comfyui-vrgamedevgirl" ] && git clone https://github.com/vrgamegirl19/comfyui-vrgamedevgirl.git
[ ! -d "RES4LYF" ] && git clone https://github.com/ClownsharkBatwing/RES4LYF.git
[ ! -d "ComfyUI-Detail-Daemon" ] && git clone https://github.com/Jonseed/ComfyUI-Detail-Daemon.git
[ ! -d "comfyui_controlnet_aux" ] && git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git
[ ! -d "ComfyUI_LayerStyle" ] && git clone https://github.com/chflame163/ComfyUI_LayerStyle.git
cd ..

# 5. Install Node Dependencies
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt || true
pip install -r custom_nodes/ComfyUI-GGUF/requirements.txt || true
pip install -r custom_nodes/rgthree-comfy/requirements.txt || true
pip install -r custom_nodes/ComfyUI-Easy-Use/requirements.txt || true
pip install -r custom_nodes/ComfyUI-KJNodes/requirements.txt || true
pip install -r custom_nodes/ComfyUI_essentials/requirements.txt || true
pip install -r custom_nodes/wlsh_nodes/requirements.txt || true
pip install -r custom_nodes/comfyui-vrgamedevgirl/requirements.txt || true
pip install -r custom_nodes/RES4LYF/requirements.txt || true
pip install -r custom_nodes/ComfyUI-Detail-Daemon/requirements.txt || true
pip install -r custom_nodes/comfyui_controlnet_aux/requirements.txt || true
pip install -r custom_nodes/ComfyUI_LayerStyle/requirements.txt || true

echo "Dependencies installed! Proceeding to Model Downloads..."

# 6. Create Model Directories
mkdir -p models/text_encoders models/vae models/loras models/unet models/diffusion_models models/upscale_models

# 7. Download the Flux 2 Klein Models
HF_BASE="https://huggingface.co/Aitrepreneur/FLX/resolve/main"

echo "Downloading Text Encoders & VAE..."
wget -nc -q --show-progress -O models/text_encoders/qwen_3_8b_fp8mixed_abliterated.safetensors "$HF_BASE/qwen_3_8b_fp8mixed_abliterated.safetensors?download=true"
wget -nc -q --show-progress -O models/vae/flux2-vae.safetensors "$HF_BASE/flux2-vae.safetensors?download=true"

echo "Downloading LoRAs..."
for LORA in KLEIN-DETAILER.safetensors detail_slider_klein_9b_20260123_065513.safetensors uncrop_F2K9B.safetensors anime2real-semi.safetensors darkBeastFeb1826Latest_dbkBlitzV15.safetensors lenovo_flux_klein9b.safetensors nicegirls_flux_klein9b.safetensors; do
    wget -nc -q --show-progress -O "models/loras/$LORA" "$HF_BASE/$LORA?download=true"
done

echo "Downloading UNET & Diffusion (Q8_0 and FP8)..."
wget -nc -q --show-progress -O models/unet/flux-2-klein-9b-Q8_0.gguf "$HF_BASE/flux-2-klein-9b-Q8_0.gguf?download=true"
wget -nc -q --show-progress -O models/diffusion_models/flux-2-klein-9b-fp8.safetensors "$HF_BASE/flux-2-klein-9b-fp8.safetensors?download=true"

echo "Downloading Upscalers..."
wget -nc -q --show-progress -O models/upscale_models/4x-ClearRealityV1.pth "$HF_BASE/4x-ClearRealityV1.pth?download=true"
wget -nc -q --show-progress -O models/upscale_models/RealESRGAN_x4plus_anime_6B.pth "$HF_BASE/RealESRGAN_x4plus_anime_6B.pth?download=true"

echo "Setup Complete! Starting ComfyUI..."

# 8. Launch ComfyUI
python main.py --listen 0.0.0.0 --port 8188
