#!/bin/bash
# ============================================================================
#  Fully Automated Flux 2 Klein Setup — idempotent edition.
#  Runs on every pod boot but skips finished work, so with a RunPod NETWORK
#  VOLUME mounted at /workspace, second+ boots are near-instant.
#
#  Markers (delete to force a re-run):
#    /workspace/ComfyUI/.base_deps_done            -> base/core python deps
#    /workspace/ComfyUI/custom_nodes/<node>/.deps_done -> that node's requirements
#  Add a new custom node to the NODES list and it auto-clones + installs on the
#  next boot WITHOUT touching any marker.
# ============================================================================
echo "Starting Fully Automated Flux 2 Klein Setup..."

# 1. Enter permanent storage and get ComfyUI (clone only if missing)
cd /workspace || exit 1
if [ ! -d "ComfyUI/.git" ]; then
    echo "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd ComfyUI || exit 1

# 2. Create venv only if missing, then activate
[ -d "venv" ] || python3 -m venv venv
source venv/bin/activate

# ---------------------------------------------------------------------------
#  3. BASE + CORE DEPS — one-time, gated by .base_deps_done.
# ---------------------------------------------------------------------------
if [ ! -f ".base_deps_done" ]; then
    echo "Installing base + core deps (first boot / forced re-run)..."
    pip install -U pip setuptools wheel

    # Torch — only (re)install if the exact pinned build isn't already present.
    # This is the 799MB download that otherwise repeats on every boot.
    if ! python -c "import torch,sys; sys.exit(0 if torch.__version__=='2.4.0+cu121' else 1)" 2>/dev/null; then
        echo "Installing pinned torch 2.4.0+cu121..."
        pip install --index-url https://download.pytorch.org/whl/cu121 --extra-index-url https://pypi.org/simple \
            torch==2.4.0+cu121 torchvision==0.19.0+cu121 torchaudio==2.4.0+cu121
    else
        echo "torch 2.4.0+cu121 already present — skipping."
    fi
    pip uninstall -y opencv-python 2>/dev/null || true
    pip install opencv-python-headless==4.12.0.88 "pillow>=11.0.0"
    pip install gguf piexif librosa || true
    pip install -U google-generativeai google-ai-generativelanguage || true

    # ComfyUI's own core deps — the bit the original script skipped (fixes the
    # 'No module named sqlalchemy' boot crash from the app/assets database).
    # torch is already satisfied, so unpinned reqs won't re-pull it.
    pip install -r requirements.txt sqlalchemy alembic || true

    touch ".base_deps_done"
    echo "Base + core deps complete."
else
    echo "Base deps present (.base_deps_done) — skipping."
    # safety net in case the marker predates the sqlalchemy fix:
    python -c "import sqlalchemy" 2>/dev/null || pip install sqlalchemy alembic
fi

# ---------------------------------------------------------------------------
#  4. CUSTOM NODES — always loops the list; clones missing nodes and installs
#     each node's requirements once (per-node .deps_done marker). Add a node
#     here and it auto-installs next boot, no marker juggling needed.
# ---------------------------------------------------------------------------
NODES=(
    "ComfyUI-Manager        https://github.com/ltdrdata/ComfyUI-Manager.git"
    "ComfyUI-GGUF           https://github.com/city96/ComfyUI-GGUF.git"
    "rgthree-comfy          https://github.com/rgthree/rgthree-comfy.git"
    "ComfyUI-Easy-Use       https://github.com/yolain/ComfyUI-Easy-Use.git"
    "ComfyUI-KJNodes        https://github.com/kijai/ComfyUI-KJNodes.git"
    "ComfyUI_essentials     https://github.com/cubiq/ComfyUI_essentials.git"
    "wlsh_nodes             https://github.com/wallish77/wlsh_nodes.git"
    "comfyui-vrgamedevgirl  https://github.com/vrgamegirl19/comfyui-vrgamedevgirl.git"
    "RES4LYF                https://github.com/ClownsharkBatwing/RES4LYF.git"
    "ComfyUI-Detail-Daemon  https://github.com/Jonseed/ComfyUI-Detail-Daemon.git"
    "comfyui_controlnet_aux https://github.com/Fannovel16/comfyui_controlnet_aux.git"
    "ComfyUI_LayerStyle     https://github.com/chflame163/ComfyUI_LayerStyle.git"
)
cd custom_nodes || exit 1
for entry in "${NODES[@]}"; do
    # shellcheck disable=SC2086
    set -- $entry            # split "dir url" on whitespace
    dir="$1"; url="$2"
    [ -d "$dir" ] || { echo "Cloning $dir..."; git clone "$url"; }
    if [ -f "$dir/requirements.txt" ] && [ ! -f "$dir/.deps_done" ]; then
        echo "Installing deps for $dir..."
        pip install -r "$dir/requirements.txt" && touch "$dir/.deps_done"
    fi
done
cd ..

echo "Dependencies ready! Proceeding to Model Downloads..."

# ---------------------------------------------------------------------------
#  5. MODELS — wget -nc skips any file that already exists on the volume.
# ---------------------------------------------------------------------------
mkdir -p models/text_encoders models/vae models/loras models/unet models/diffusion_models models/upscale_models
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

# 6. Launch ComfyUI (exec = clean foreground process for the container)
exec python main.py --listen 0.0.0.0 --port 8188
