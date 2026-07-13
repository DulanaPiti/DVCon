# DVCon

DVCon is a small project to accelerate an object-detection machine-learning pipeline by designing and implementing a high-performance depthwise convolution engine and optimizing dataflows across the compute and memory hierarchy.

## Purpose

The repository's goal is to prototype hardware- and software-level techniques to speed up depthwise separable convolutions (commonly used in lightweight detection backbones) so inference runs faster and with lower power and memory bandwidth usage.

## Models and Components

This work targets pipelines that use lightweight backbones such as MobileNetV3 and task-driven modules like GGNN-based components. The emphasis is on the depthwise convolution kernel and system-level dataflow optimizations rather than full reimplementation of detection models.

## Key Objectives

- Implement an efficient depthwise convolution engine (hardware/accelerator or optimized CPU/GPU kernels).
- Explore data layouts, tiling, and memory access patterns to reduce bandwidth and increase reuse.
- Apply loop transformations, operator fusion, and quantization-friendly optimizations.
- Provide benchmarks and comparisons against baseline MobileNetV3-based detection pipelines.

## Getting started

1. Clone the repository.
2. Follow platform-specific build and run instructions (TBD in repository files).
3. Run benchmarks and compare to baseline implementations.

## Contributing

Issues, suggestions, and pull requests are welcome. Please describe experiments, benchmarks, and target platforms in PRs.

## License

See LICENSE if present or contact the repository owner for licensing details.
