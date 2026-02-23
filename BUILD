load("@rules_pkg//pkg:mappings.bzl", "pkg_files")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

pkg_files(
    name = "linux",
    srcs = ["//benchmarks/linux:vmlinux"],
    prefix = "benchmarks/linux",
)

pkg_files(
    name = "mibench_automotive_qsort",
    srcs = ["//benchmarks/mibench/automotive/qsort:all"],
    prefix = "benchmarks/mibench/automotive/qsort",
)

pkg_files(
    name = "mibench_automotive_basicmath",
    srcs = ["//benchmarks/mibench/automotive/basicmath:all"],
    prefix = "benchmarks/mibench/automotive/basicmath",
)

pkg_files(
    name = "mibench_automotive_bitcount",
    srcs = ["//benchmarks/mibench/automotive/bitcount:all"],
    prefix = "benchmarks/mibench/automotive/bitcount",
)

pkg_files(
    name = "mibench_automotive_susan",
    srcs = ["//benchmarks/mibench/automotive/susan:all"],
    prefix = "benchmarks/mibench/automotive/susan",
)

pkg_files(
    name = "mibench_consumer_jpeg",
    srcs = ["//benchmarks/mibench/consumer/jpeg:all"],
    prefix = "benchmarks/mibench/consumer/jpeg",
)

pkg_files(
    name = "rustc_perf",
    srcs = ["//benchmarks/rustc-perf:all"],
    prefix = "benchmarks/rustc-perf",
)
pkg_files(
    name = "llvm_bc_pkg",
    srcs = [":llvm_bitcode"],
    prefix = "benchmarks/llvm",
    visibility = ["//visibility:public"],
)
pkg_files(
    name = "sqlite_bc",
    srcs = ["//benchmarks/sqlite:all"],
    prefix = "benchmarks/sqlite",
)

pkg_tar(
    name = "bitcode_tar",
    srcs = [
        ":linux",
        ":mibench_automotive_qsort",
        ":mibench_automotive_basicmath",
        ":mibench_automotive_bitcount",
        ":mibench_automotive_susan",
        ":mibench_consumer_jpeg",
        ":rustc_perf",
        ":llvm_bc_pkg",
        ":sqlite_bc"
    ],
)

