genrule(
    name = "redis",
    srcs = ["@redis_src//:all"],
    outs = ["redis.bc"],
    cmd = """
        set -e
        EXEC_ROOT="$$PWD"
        BUILD_DIR=$$(mktemp -d)
        trap "rm -rf $$BUILD_DIR" EXIT

        # Copy source — make requires in-tree build
        cp -r $$EXEC_ROOT/external/redis_src/. $$BUILD_DIR/
        cd $$BUILD_DIR

        pip install wllvm --break-system-packages --quiet

        export LLVM_COMPILER=clang
        export LLVM_COMPILER_PATH="$$EXEC_ROOT/external/llvm_base_toolchain_llvm/bin"

        sed -i 's/-pedantic//g' src/Makefile
        sed -i 's/-flto//g' src/Makefile
        sed -i 's/-Werror[^ ]*//g' src/Makefile
        
        # clang 14 rejects _Atomic function pointer init with NULL under gnu11
        sed -i 's/static redisAtomic run_on_thread_cb g_callback = NULL;/static redisAtomic run_on_thread_cb g_callback;/' src/threads_mngr.c

        make -j$$(nproc) \
            CC=wllvm \
            MALLOC=libc

        extract-bc src/redis-server -o "$$EXEC_ROOT/$@"
    """,
    toolchains = ["@bazel_tools//tools/cpp:current_cc_toolchain"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "all",
    srcs = [":redis"],
    visibility = ["//visibility:public"],
)