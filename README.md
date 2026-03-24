# FPGA-Face-Recognition-OpenFR
FPGA-based real-time face recognition system

## 🚀 Overview
OpenFR is a real-time face recognition system based on FPGA and YOLO model, designed for edge computing scenarios.

## 🧠 Architecture
- Image Capture (Camera)
- Hardware Preprocessing (FPGA)
- YOLO Inference (TinyML)
- Post-processing (NMS)
- HDMI Display Output

## ⚙️ Features
- Real-time detection (~16 FPS)
- Low latency (~61 ms)
- INT8 quantized YOLO model
- DMA + AXI high-speed data pipeline
- Multi-face detection and visualization

## 🔧 Tech Stack
- FPGA (Ti60F225)
- Verilog
- YOLO (TinyML)
- AXI / DMA Architecture

## 📊 Performance
|  Metric  | Value |
|----------|-------|
|   FPS    |  16   |
| Latency  | ~61ms |
| Accuracy | >80%  |
