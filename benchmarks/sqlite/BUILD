genrule(
    name = "sqlite",
    srcs = ["@sqlite_src//:sqlite3.c", "@sqlite_src//:sqlite3.h"],
    outs = ["sqlite3.bc"],
    cmd = """
        external/llvm_base_toolchain_llvm/bin/clang \
            -emit-llvm -Oz -c \
            -I $$(dirname $(location @sqlite_src//:sqlite3.h)) \
            $(location @sqlite_src//:sqlite3.c) \
            -o $@
    """,
    toolchains = ["@bazel_tools//tools/cpp:current_cc_toolchain"],
    visibility = ["//visibility:public"],
)