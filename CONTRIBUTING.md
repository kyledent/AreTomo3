# Contributing to AreTomo3

## Where to send changes

**Open pull requests against `develop`, not `main`.** New work lands on
`develop`, and `main` is updated only by merging `develop` into it for a
release. A pull request against `main` would have to be rebased before it
could be merged.

## Reporting problems

Use the issue forms. For a crash or a wrong result, include:

- the AreTomo3 version (`AreTomo3 --version`), or the commit you built;
- the GPU model, driver version and CUDA toolkit version;
- the full command line and the end of the log;
- whether an earlier version works on the same data.

For a build failure, include the makefile you used, the CUDA toolkit and
`gcc --version`, and the first error in the output (not only the last).

Report security issues privately, as described in [SECURITY.md](SECURITY.md).

## Building

```
make exe -f makefile11 CUDAHOME=/path/to/cuda-12.x
```

| Makefile     | CUDA toolkit tested in CI | GPU architectures              |
|--------------|---------------------------|--------------------------------|
| `makefile`   | 12.1                      | sm_61 to sm_75                 |
| `makefile11` | 12.1, 12.8                | sm_61 to sm_90                 |
| `makefile12` | 12.4                      | sm_70 to sm_90                 |
| `makefile13` | 13.0                      | sm_80 to sm_90, sm_100, sm_120 |

The support libraries in `LibSrc/Lib` are prebuilt. To rebuild them from
source, run `make -C LibSrc/Util && make -C LibSrc/Mrcfile` first.

## Adding a source file

The four makefiles list their sources separately. **Add a new file to all of
them.** CI runs `.github/scripts/check_makefile_sources.py`, which fails if
the lists differ, and then builds with each makefile.

## Continuous integration

Every push and pull request is compiled with each makefile in the
`nvidia/cuda` development images. The builds need no GPU, so they run on
standard runners, and they do not run AreTomo3 itself.
