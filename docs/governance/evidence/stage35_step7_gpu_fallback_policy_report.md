# Stage35 GPU Profiling Matrix

- weak-vm: renderer=Intel(R) UHD Graphics 620, vram_mb=512, class=weak, fallback=read-only, reason=weak_gpu_or_vm_profile
- standard-laptop: renderer=Intel Iris Xe, vram_mb=2048, class=standard, fallback=advanced, reason=standard_profile
- strong-desktop: renderer=NVIDIA RTX, vram_mb=8192, class=strong, fallback=advanced, reason=high_vram_profile
