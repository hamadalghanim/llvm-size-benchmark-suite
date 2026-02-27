genrule(
    name = "ioq3",
    srcs = ["@ioq3_src//:all"],
    outs = ["ioquake3.bc", "ioq3ded.bc"],
    local = True,
    cmd = """
        set -e
        EXEC_ROOT="$$PWD"
        BUILD_DIR=$$(mktemp -d)
        trap 'err=$$?; rm -rf "$$BUILD_DIR"; exit $$err' EXIT

        cp -r $$EXEC_ROOT/external/ioq3_src/. $$BUILD_DIR/
        cd $$BUILD_DIR

        if ! command -v wllvm &>/dev/null; then
            pip install wllvm --break-system-packages --quiet
        fi

        export LLVM_COMPILER=clang
        export LLVM_COMPILER_PATH="$$EXEC_ROOT/external/llvm_base_toolchain_llvm/bin"
        export PATH="$$EXEC_ROOT/external/llvm_base_toolchain_llvm/bin:/usr/bin:/bin:$$PATH"
        export LLVM_CC_NAME=clang
        export LLVM_CXX_NAME=clang++

        cmake -S . -B build \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER=wllvm \
            -DCMAKE_C_FLAGS="-Oz" \
            -DBUILD_SERVER=ON \
            -DBUILD_CLIENT=ON \
            -DBUILD_GAME_LIBRARIES=OFF \
            -DBUILD_GAME_QVMS=OFF \
            -DUSE_OPENAL=OFF \
            -DUSE_CODEC_VORBIS=OFF \
            -DUSE_CODEC_OPUS=OFF \
            -DUSE_MUMBLE=OFF \
            -DUSE_VOIP=OFF \
            -DUSE_FREETYPE=OFF

        cmake --build build -- -j$$(nproc)

        # Show where binaries actually landed
        echo "=== Built binaries ==="
        find build -type f -executable | sort

        IOQ3=$$(find build -type f -executable -name "ioquake3" | head -1)
        DED=$$(find build -type f -executable -name "ioq3ded" | head -1)

        echo "ioquake3 -> $$IOQ3"
        echo "ioq3ded  -> $$DED"

        extract-bc "$$IOQ3"
        extract-bc "$$DED"

        cp "$${IOQ3}.bc" "$$EXEC_ROOT/$(location ioquake3.bc)"
        cp "$${DED}.bc"  "$$EXEC_ROOT/$(location ioq3ded.bc)"
    """,
    toolchains = ["@bazel_tools//tools/cpp:current_cc_toolchain"],
    visibility = ["//visibility:public"],
)