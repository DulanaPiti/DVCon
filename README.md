# Project

This is a digital design project that aims to accelerate an object-detection machine-learning pipeline by designing and implementing a high-performance depthwise convolution engine and optimizing data[...]

## Purpose

The repository's goal is to prototype hardware-level techniques to speed up depthwise separable convolutions (commonly used in lightweight detection backbones) so inference runs faster and with low[...]

## Models and Components

This work targets pipelines that use lightweight backbones such as MobileNetV3 and task-driven modules like GGNN-based components. The emphasis is on the depthwise convolution kernel and system-le[...]

## Key Objectives

- Implement an efficient depthwise convolution engine (hardware/accelerator or optimized CPU/GPU kernels).
- Explore data layouts, tiling, and memory access patterns to reduce bandwidth and increase reuse.
- Provide benchmarks and comparisons against baseline MobileNetV3-based detection pipelines.

## Related machine-learning pipeline

The ML pipeline targeted for acceleration in this project is available here:

https://github.com/maneth-b03p/MobileNetV3-GGNN-Task-Driven-Object-Detection.git

This repository provides the MobileNetV3 backbone and GGNN-based task-driven detection components used as the baseline for benchmarking and integration.
