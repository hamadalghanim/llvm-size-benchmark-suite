load("//:bazel/bitcode.bzl", "bitcode_binary")

bitcode_binary(
    name = "bitcount",
    srcs = [
        "@mibench_automotive//:bitcount/bitarray.c",
        "@mibench_automotive//:bitcount/bitcnt_1.c",
        "@mibench_automotive//:bitcount/bitcnt_2.c",
        "@mibench_automotive//:bitcount/bitcnt_3.c",
        "@mibench_automotive//:bitcount/bitcnt_4.c",
        "@mibench_automotive//:bitcount/bitcnts.c",
        "@mibench_automotive//:bitcount/bitfiles.c",
        "@mibench_automotive//:bitcount/bitstrng.c",
        "@mibench_automotive//:bitcount/bstr_i.c",
    ],
    hdrs = [
        "@mibench_automotive//:bitcount/bitops.h",
        "@mibench_automotive//:bitcount/conio.h",
        "@mibench_automotive//:bitcount/extkword.h",
        "@mibench_automotive//:bitcount/sniptype.h",
    ]
)



filegroup(
    name = "all",
    srcs = [":bitcount"],
    visibility = ["//visibility:public"],
)
