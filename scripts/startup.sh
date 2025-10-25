#!/bin/bash

sudo apt-get update && sudo apt-get install -y --no-install-recommends \
   curl \
   gnupg2

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.0-1

sudo apt-get install -y \
      nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl restart docker

# Check if container exists
if sudo docker ps -a --format '{{.Names}}' | grep -q '^mujoco-playground$'; then
  echo "Container 'mujoco-playground' already exists. Starting it..."
  sudo docker start mujoco-playground
else
  echo "Creating and starting new container 'mujoco-playground'..."
  sudo docker run -d \
    --gpus all \
    -p 8888:8888 \
    --name mujoco-playground \
    -v $(pwd)/mujoco-playground:/workspace \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics \
    thinkinrocks/mujoco-playground:0.0.1
fi
