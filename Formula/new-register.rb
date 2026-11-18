class NewRegister < Formula
  desc "Multi-volume MINC2/NIfTI viewer with tag-based registration (ImGui + Metal)"
  # Private repo — not publicly browsable, but this is the real fetch location.
  homepage "https://github.com/vfonov/vibe_register.git"
  url "https://github.com/vfonov/vibe_register.git",
      branch:   "main",
      revision: "45a53a0940f39b83e6d46d79f647177ebefe36dc"
  version "0.1.1-20261009" # project() VERSION in new_register/CMakeLists.txt, plus commit date

  # macOS only: new_register's CMakeLists.txt switches to a native Cocoa+Metal
  # backend on Apple (main_macos.mm + MetalBackend.mm) and only that path has
  # been packaged/tested here. The Linux path (GLFW + Vulkan/OpenGL2) needs a
  # different dependency set (vulkan-loader, glfw, ...) that this formula does
  # not declare.
  depends_on "cmake" => :build
  depends_on "glm"
  depends_on "hdf5"
  depends_on :macos
  depends_on "netcdf"
  depends_on "nlohmann-json"

  # ---------------------------------------------------------------------------
  # Pre-fetched git sources for dependencies with no standalone Homebrew
  # formula (Dear ImGui's docking branch, and the BIC-MNI/NIST-MNI MINC2
  # stack), plus Eigen — new_register's `find_package(Eigen3 ...)` accepts a
  # real Homebrew "eigen" install (5.x) too, but this formula deliberately
  # pins its own Eigen resource instead of `depends_on "eigen"`, for the same
  # fully offline/deterministic install property as imgui/libminc/
  # minc2-simple below.
  #
  # Each is staged into place at install time and handed to CMake via a
  # source-dir override (either the built-in FetchContent_SOURCE_DIR_<NAME>
  # mechanism for imgui, or the project's own LIBMINC_SOURCE_DIR /
  # MINC2_SIMPLE_SOURCE_DIR / EIGEN_SOURCE_DIR cache variables) so the actual
  # build runs with zero network access. See new_register/CMakeLists.txt.
  #
  # The project prefers an already-installed Eigen3 / LIBMINC / minc-toolkit
  # over these source dirs, so install() also turns those lookups off:
  # otherwise a Homebrew `eigen` (whose headers superenv hides, as it is not a
  # declared dependency) or a minc-toolkit under /opt/minc gets picked up
  # instead, breaking the build or linking the result against /opt/minc.
  # ---------------------------------------------------------------------------
  resource "imgui" do
    url "https://github.com/ocornut/imgui/archive/fd13a1e8923a0a7077b404fc36fd063b25a0c0b5.tar.gz"
    sha256 "5a7cca7ceff10b7d4d800d7e679d8a5295135567c1e9058f00d44d4e55da44e8"
  end

  resource "libminc" do
    url "https://github.com/BIC-MNI/libminc/archive/698494b2ec51b41cd1b30b0c961b5ec6597350de.tar.gz"
    sha256 "2ba0ef5d2923becdde1abf6975dc644f96645ffc794a6fc005fdcd8f7b3d6a1f"
  end

  resource "minc2-simple" do
    url "https://github.com/NIST-MNI/minc2-simple/archive/8f161e041ad968fc7bd71c0fba3fdba7f067b9e7.tar.gz"
    sha256 "1e94c61ab3a753bf86eec1613f4e7107ad10efbca011aa61dc4bcd2f0bb1a428"
  end

  resource "eigen" do
    url "https://gitlab.com/libeigen/eigen/-/archive/5.0.1/eigen-5.0.1.tar.gz"
    sha256 "e9c326dc8c05cd1e044c71f30f1b2e34a6161a3b6ecf445d56b53ff1669e3dec"
  end

  def install
    resource("imgui").stage        buildpath/"resources/imgui"
    resource("libminc").stage      buildpath/"resources/libminc"
    resource("minc2-simple").stage buildpath/"resources/minc2-simple"
    resource("eigen").stage        buildpath/"resources/eigen"

    args = %W[
      -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON
      -DFETCHCONTENT_SOURCE_DIR_IMGUI=#{buildpath}/resources/imgui
      -DLIBMINC_SOURCE_DIR=#{buildpath}/resources/libminc
      -DMINC2_SIMPLE_SOURCE_DIR=#{buildpath}/resources/minc2-simple
      -DEIGEN_SOURCE_DIR=#{buildpath}/resources/eigen
      -DCMAKE_DISABLE_FIND_PACKAGE_Eigen3=ON
      -DCMAKE_DISABLE_FIND_PACKAGE_LIBMINC=ON
      -DMINC_TOOLKIT_DIR=
      -DBUILD_TERMINAL_VIEWER=OFF
      -DBUILD_NEW_QC=OFF
      -DENABLE_TESTS=OFF
    ]

    system "cmake", "-S", "new_register", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--build", "build", "--target", "install"
  end

  test do
    # Both exit 0 on --help (unlike minc-toolkit's mincinfo, which exits 1).
    assert_match "Usage: new_register", shell_output("#{bin}/new_register --help 2>&1")
    assert_match "Usage: new_mincpik", shell_output("#{bin}/new_mincpik --help 2>&1")
  end
end
