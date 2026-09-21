# Bundle

This folder contains binary executable files that should not be gitted.

To use this nvim config, the following tools are needed.

- `matlab-engine`: a python virtual environment that has [matlab.engine]( `https://ww2.mathworks.cn/help/matlab/matlab_external/install-the-matlab-engine-for-python.html`)
  installed.
- `tex-fmt`: for I'm now using my custom [`tex-fmt`](https://github.com/chenyu76/tex-fmt/)
- `julia-1.12.7`: official Linux x86_64 Julia runtime used by Mason's Julia LSP
  (configured in `lua/plugins/completion.lua`). The bundled SymbolServer fails
  to load with the system Julia 1.13. Project files use their project environment;
  standalone files use `~/.julia/environments/v1.12`.
  The LSP sets `JULIA_PROBE_LIBSTDCXX=0` because host C++ library probing hangs
  on this machine; this uses Julia's bundled C++ library instead.
  Download: https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.7-linux-x86_64.tar.gz
  SHA-256: `4e7e9e776634d24835250de67cde39b0d4af15bc432eb20697e6be6c28ea69e8`.
