load(
    "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    "CPP_COMPILE_ACTION_NAME",
)

BitcodeCcInfo = provider(
    "A provider that contains compile and linking information for bitcode",
    fields = [
        "cc_info",
        "bitcode",
    ],
)


BITCODE_BIN_ATTRS = {
    "srcs": attr.label_list(allow_files = True),
    "hdrs": attr.label_list(allow_files = True),
    "deps": attr.label_list(providers = [BitcodeCcInfo]),
    "copts": attr.string_list(default = []),
    "linkopts": attr.string_list(),
    "includes": attr.string_list(),
    "defines": attr.string_list(),
    "local_defines": attr.string_list(),
    "include_prefix": attr.string(),
    "_llvm_link": attr.label(
        default = "@llvm_base_toolchain_llvm//:bin/llvm-link",
        allow_single_file = True,
        executable = True,
        cfg = "host",
    ),
    "_cc_toolchain": attr.label(
        default = Label("@bazel_tools//tools/cpp:current_cc_toolchain"),
        providers = [cc_common.CcToolchainInfo],
        cfg = "host",
    ),
    "_bin_ext": attr.string(default = ".bc"),
    "_llvm_opt": attr.label(
        default = "@llvm_base_toolchain_llvm//:bin/opt",
        allow_single_file = True,
        executable = True,
        cfg = "host",
    ),
}

def _bitcode_library_common(ctx):
    cc_toolchain = ctx.attr._cc_toolchain[cc_common.CcToolchainInfo]
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    deps = ctx.attr.deps

    comp_ctx, outputs = cc_common.compile(
        name = ctx.label.name,
        actions = ctx.actions,
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        public_hdrs = ctx.files.hdrs,
        srcs = ctx.files.srcs,
        includes = ctx.attr.includes,
        defines = ctx.attr.defines,
        local_defines = ctx.attr.local_defines,
        include_prefix = ctx.attr.include_prefix,
        user_compile_flags = ctx.attr.copts + ["-emit-llvm", "-Oz"],
        compilation_contexts = [
            info[BitcodeCcInfo].cc_info.compilation_context
            for info in deps
        ],
    )
    bcobjects = outputs.pic_objects + outputs.objects
    transitive_deps = [dep[BitcodeCcInfo].bitcode for dep in deps]
    if len(bcobjects) == 0:
        return BitcodeCcInfo(
            cc_info = CcInfo(compilation_context = comp_ctx),
            bitcode = depset([], transitive = transitive_deps),
        )

    bcfile = ctx.actions.declare_file("_bclibs/{}.bc".format(ctx.label.name))

    args = ctx.actions.args()
    args.add_all(bcobjects)
    args.add_all(ctx.attr.linkopts)
    args.add_all(["-o", bcfile])

    ctx.actions.run(
        outputs = [bcfile],
        inputs = bcobjects,
        executable = ctx.executable._llvm_link,
        arguments = [args],
    )

    return BitcodeCcInfo(
        cc_info = CcInfo(compilation_context = comp_ctx),
        bitcode = depset(
            [bcfile],
            transitive = [dep[BitcodeCcInfo].bitcode for dep in deps],
        ),
    )
    
def _bitcode_binary(ctx):
    bcinfo = _bitcode_library_common(ctx)
    files = bcinfo.bitcode
    
    # Changed: write llvm-link output to a temp file
    linked_output = ctx.actions.declare_file(ctx.label.name + "_unopt.bc")
    args = ctx.actions.args()
    args.add_all(files)
    args.add_all(ctx.attr.linkopts)
    args.add_all(["-o", linked_output])
    ctx.actions.run(
        inputs = files,
        outputs = [linked_output],
        executable = ctx.executable._llvm_link,
        arguments = [args],
    )

    # New: run opt -passes=mergereturn on the linked output
    output = ctx.actions.declare_file(ctx.label.name + ".bc")
    opt_args = ctx.actions.args()
    opt_args.add("-passes=mergereturn")
    opt_args.add(linked_output)
    opt_args.add_all(["-o", output])
    ctx.actions.run(
        inputs = [linked_output],
        outputs = [output],
        executable = ctx.executable._llvm_opt,
        arguments = [opt_args],
    )

    return [
        DefaultInfo(files = depset([output])),
        OutputGroupInfo(
            bitcode = depset([output]),
        ),
    ]

bitcode_binary = rule(
    implementation = _bitcode_binary,
    attrs = BITCODE_BIN_ATTRS,
    fragments = ["cpp"],
)
