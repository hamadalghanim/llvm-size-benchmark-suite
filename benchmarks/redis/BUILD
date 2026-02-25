genrule(
    name = "redis",
    srcs = ["@redis_src//:all"],
    outs = ["redis.bc"],
    cmd = """
        set -e
        EXEC_ROOT="$$PWD"
        BUILD_DIR=$$(mktemp -d)
        
        # Update trap to preserve the exit code of failing commands
        trap 'err=$$?; rm -rf "$$BUILD_DIR"; exit $$err' EXIT

        # Copy source — make requires in-tree build
        cp -r $$EXEC_ROOT/external/redis_src/. $$BUILD_DIR/
        cd $$BUILD_DIR

        pip install wllvm --break-system-packages --quiet

        export LLVM_COMPILER=clang
        export LLVM_COMPILER_PATH="$$EXEC_ROOT/external/llvm_base_toolchain_llvm/bin"
        export PATH="$$EXEC_ROOT/external/llvm_base_toolchain_llvm/bin:/usr/bin:/bin:$$PATH"
        export LLVM_CC_NAME=clang
        export LLVM_CXX_NAME=clang++

        sed -i 's/-pedantic//g' src/Makefile
        sed -i 's/-flto//g' src/Makefile
        sed -i 's/-Werror[^ ]*//g' src/Makefile
        sed -i 's/-O[0-9s]//g' src/Makefile

        # clang 14 rejects _Atomic function pointer init with NULL under gnu11
        sed -i 's/static redisAtomic run_on_thread_cb g_callback = NULL;/static redisAtomic run_on_thread_cb g_callback;/' src/threads_mngr.c

        make -j$$(nproc) \
            CC=wllvm \
            CXX=wllvm++ \
            MALLOC=libc \
            CFLAGS="-Oz" \
            CXXFLAGS="-Oz"

        # Run extract-bc without the -o flag
        extract-bc src/redis-server
        
        # Copy the generated .bc file to Bazel's expected output destination
        cp src/redis-server.bc "$$EXEC_ROOT/$@"
    """,
    toolchains = ["@bazel_tools//tools/cpp:current_cc_toolchain"],
    visibility = ["//visibility:public"],
)