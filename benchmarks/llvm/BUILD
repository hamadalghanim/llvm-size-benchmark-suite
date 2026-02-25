genrule(
    name = "llvm_bitcode",
    srcs = ["@llvm_src//:all"],
    outs = ["clang.bc"],
    cmd = """
        set -e
        EXEC_ROOT="$$PWD"
        BUILD_DIR=$$(mktemp -d)
        trap "rm -rf $$BUILD_DIR" EXIT

        cd $$BUILD_DIR
        pip install wllvm --break-system-packages --quiet

        export LLVM_COMPILER=clang
        export LLVM_CC_NAME=clang
        export LLVM_CXX_NAME=clang++

        cmake "$$EXEC_ROOT/external/llvm_src/llvm" \
            -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CXX_FLAGS_RELEASE="-Os -DNDEBUG" \
            -DCMAKE_C_FLAGS_RELEASE="-Os -DNDEBUG" \
            -DLLVM_ENABLE_PROJECTS="clang" \
            -DCMAKE_C_COMPILER=wllvm \
            -DCMAKE_CXX_COMPILER=wllvm++ \
            -DLLVM_INCLUDE_TESTS=OFF \
            -DLLVM_BUILD_TOOLS=OFF

        ninja clang

        # Extract bitcode from the final binary
        extract-bc bin/clang -o "$$EXEC_ROOT/$@"
    """,
)

filegroup(
    name = "all",
    srcs = [":llvm_bitcode"],
    visibility = ["//visibility:public"],
)