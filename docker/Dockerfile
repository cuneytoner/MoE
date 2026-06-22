# ==============================================================================
# File: Dockerfile
# Description: Custom optimized ComfyUI instance running on top of official PyTorch.
# ==============================================================================

# Use the official PyTorch CUDA environment as base
FROM pytorch/pytorch:latest

# Install core build artifacts, tools, and system libraries required for media generation
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    libgl1-mesa-glx \
    libglib2.0-0 \
    gcc \
    g++ \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Establish clear clean working directory isolation
WORKDIR /workspace

# Clone the master ComfyUI repository natively using segmented parameters
RUN REPO_BASE="https://github.com" && \
    # REPO_PATH="/comfyanonymous/ComfyUI.git" && \
    REPO_PATH="/Comfy-Org/ComfyUI.git" && \
    git clone --progress "${REPO_BASE}${REPO_PATH}" .


    

# Upgrade Core PyTorch components directly to guarantee high runtime optimization
RUN pip install --pre --upgrade --no-cache-dir torch torchvision torchaudio --extra-index-url https://pytorch.org

# Install standard Python prerequisites completely
RUN pip install --no-cache-dir -r requirements.txt

# Secure local container permissions mapping to non-root UID
RUN chown -R 1000:1000 /workspace

# Expose internal interface port
EXPOSE 8188

# Launch parameters configured for 16GB VRAM safety rules
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--fp8_e4m3fn-text-enc", "--fp8_e4m3fn-unet", "--fp16-vae", "--use-pytorch-cross-attention", "--enable-dynamic-vram"]
