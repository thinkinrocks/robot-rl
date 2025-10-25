#!/bin/bash

sudo docker run \
  --gpus all \
  -p 8888:8888 \
  --name mujoco-playground \
  -v $(pwd)/mujoco-playground:/workspace \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics \
  thinkinrocks/mujoco-playground:0.0.1
