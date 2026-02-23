load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_pkg",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.7.0/rules_pkg-0.7.0.tar.gz",
        "https://github.com/bazelbuild/rules_pkg/releases/download/0.7.0/rules_pkg-0.7.0.tar.gz",
    ],
    sha256 = "8a298e832762eda1830597d64fe7db58178aa84cd5926d76d5b744d6558941c2",
)
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
rules_pkg_dependencies()

BAZEL_TOOLCHAIN_TAG = "0.7.1"
BAZEL_TOOLCHAIN_SHA = "5613b430a6b7f6d0eb03011976df53abe7f4cc6c3ec43be066b679c4ad81e3bf"

http_archive(
    name = "com_grail_bazel_toolchain",
    sha256 = BAZEL_TOOLCHAIN_SHA,
    strip_prefix = "toolchains_llvm-{tag}".format(tag = BAZEL_TOOLCHAIN_TAG),
    canonical_id = BAZEL_TOOLCHAIN_TAG,
    url = "https://github.com/bazel-contrib/toolchains_llvm/archive/{tag}.tar.gz".format(tag = BAZEL_TOOLCHAIN_TAG),
)

load("@com_grail_bazel_toolchain//toolchain:deps.bzl", "bazel_toolchain_dependencies")

bazel_toolchain_dependencies()

load("@com_grail_bazel_toolchain//toolchain:rules.bzl", "llvm_toolchain")

llvm_toolchain(
    name = "llvm_base_toolchain",
    llvm_version = "14.0.0",
)

http_archive(
    name = "rules_rust",
    sha256 = "6bfe75125e74155955d8a9854a8811365e6c0f3d33ed700bc17f39e32522c822",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_rust/releases/download/0.9.0/rules_rust-v0.9.0.tar.gz",
        "https://github.com/bazelbuild/rules_rust/releases/download/0.9.0/rules_rust-v0.9.0.tar.gz",
    ],
)

load("@rules_rust//rust:repositories.bzl", "rules_rust_dependencies", "rust_register_toolchains")

rules_rust_dependencies()

rust_register_toolchains(version = "1.59.0")

# Benchmark source code

http_archive(
    name = "llvm_src",
    build_file_content = """
filegroup(
    name = "all",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
""",
    # Updated to the checksum Bazel found
    sha256 = "9a56d906a2c81f16f06efc493a646d497c53c2f4f28f0cb1f3c8da7f74350254",
    strip_prefix = "llvm-project-16.0.0.src",
    urls = [
        "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.0/llvm-project-16.0.0.src.tar.xz",
    ],
)
http_archive(
    name = "sqlite_src",
    url = "https://sqlite.org/2026/sqlite-amalgamation-3510200.zip",
    sha256 = "6e2a845a493026bdbad0618b2b5a0cf48584faab47384480ed9f592d912f23ec",
    strip_prefix = "sqlite-amalgamation-3510200",
    build_file_content = """
filegroup(
    name = "all",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
exports_files(["sqlite3.c", "sqlite3.h"])
""",
)
http_archive(
    name = "redis_src",
    url = "https://download.redis.io/redis-stable.tar.gz",
    strip_prefix = "redis-stable",
    build_file_content = """
filegroup(
    name = "all",
    srcs = glob(["**"], exclude = ["**/*.o", "**/*.a"]),
    visibility = ["//visibility:public"],
)
""",
)

http_archive(
    name = "mibench_automotive",
    sha256 = "d63e8dc1f15d93d1b7ee59aed4dfb38659cb78819ce94bd26f8ceaf4d149fad9",
    strip_prefix = "automotive",
    build_file_content = """exports_files(glob(["**"]))""",
    url = "https://vhosts.eecs.umich.edu/mibench/automotive.tar.gz",
)

http_archive(
    name = "mibench_consumer",
    sha256 = "86d76a66fa567953c7b814a6c6e816c6af0afab59610160acb8036899d03d1f9",
    strip_prefix = "consumer",
    build_file_content = """exports_files(glob(["**"]))""",
    url = "https://vhosts.eecs.umich.edu/mibench/consumer.tar.gz",
)

http_archive(
    name = "linux_kernel_src",
    sha256 = "6e3cd56ee83a9cb5ac3fde1442c40367ab67368946c4c93bbeb1c65664a0d3c5",
    strip_prefix = "linux-5.17.4",
    build_file_content = """
filegroup(
    name = "all",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
exports_files(glob(["**"]))
""",
    url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.17.4.tar.xz",
)

http_archive(
    name = "rustc_perf",
    sha256 = "b40dedbafcd8113d4283700f5ac52bded0ca58e846d8cbda1c446ee78f9e2920",
    strip_prefix = "rust-lang-rustc-perf-0fd5c19",
    type = "tgz",
    build_file_content = """
filegroup(
    name = "all",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"],
)
exports_files(glob(["**"]))
""",
    url = "https://github.com/rust-lang/rustc-perf/tarball/0fd5c1921c306ccb9df865630145d07c028cb3d5",
)
