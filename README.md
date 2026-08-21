# vfonov/register

A [Homebrew](https://brew.sh) tap with a formula for `new_register`, a
multi-volume MINC2/NIfTI viewer with tag-based registration (Vulkan/OpenGL2
on Linux, native Cocoa+Metal on macOS).

## Install

```sh
brew tap vfonov/register
brew install --build-from-source new-register
```

`--build-from-source` is required: there is no pre-built bottle.

## Formulae

### `new-register`

Builds `new_register` and `new_mincpik` (macOS/Metal only — the Linux GLFW +
Vulkan/OpenGL2 path is not packaged here). `hdf5`, `netcdf`, `glm`, and
`nlohmann-json` come from Homebrew. `new_register`'s `find_package(Eigen3 ...)`
now accepts a real Homebrew `eigen` install too (Eigen jumped from the 3.4
series straight to 5.0, and Homebrew's `eigen` formula is 5.x) — but this
formula still pins its own Eigen 5.0.1 as a `resource` rather than declaring
`depends_on "eigen"`, for the same fully offline/deterministic build as the
other pinned dependencies below. Dear ImGui (docking branch), libminc,
minc2-simple, and Eigen have no usable Homebrew package (Eigen has one, it's
just deliberately not used here), so each is declared as a pinned-commit
`resource` and staged into place at install time via CMake's
`FETCHCONTENT_SOURCE_DIR_<NAME>` and this project's own `LIBMINC_SOURCE_DIR` /
`MINC2_SIMPLE_SOURCE_DIR` / `EIGEN_SOURCE_DIR` overrides, so the actual build
runs with no network access.

`mriv` (the terminal viewer subproject) and `new_qc` (the standalone image QC
viewer) are not built by this formula — both are excluded via
`-DBUILD_TERMINAL_VIEWER=OFF -DBUILD_NEW_QC=OFF`.

## Updating the pinned revision

The formula pins `new_register`'s source to a specific commit via
`revision:`. To follow a newer commit, update `revision:` (and `version`) in
`Formula/new-register.rb`, then `brew reinstall --build-from-source
new-register`. If the pinned CMakeLists.txt dependency versions move too
(imgui docking branch, libminc/minc2-simple `develop` branches, Eigen), the
matching `resource` urls/sha256s need updating as well.

## License

The formula in this tap is released under the BSD-2-Clause license. The
packaged software (`new_register`, in the private `vibe_register` repo) has
its own license terms.
