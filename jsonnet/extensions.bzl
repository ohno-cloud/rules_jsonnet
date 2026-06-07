load(
    "//jsonnet:version.bzl",
    "GO_JSONNET_DEFAULT_VERSION",
    "GO_JSONNET_TOOLCHAINS",
    "JRSONNET_DEFAULT_VERSION",
    "JRSONNET_TOOLCHAINS",
    "JSONNET_DEFAULT_VERSION",
    "JSONNET_TOOLCHAINS",
)

_GO_PLATFORM_INFO = {
    "darwin_amd64": struct(os = "osx", cpu = "x86_64"),
    "darwin_arm64": struct(os = "osx", cpu = "aarch64"),
    "linux_amd64": struct(os = "linux", cpu = "x86_64"),
    "linux_arm64": struct(os = "linux", cpu = "aarch64"),
}

_JRSONNET_PLATFORM_INFO = {
    "aarch64-darwin": struct(os = "osx", cpu = "aarch64"),
    "aarch64-linux-musl": struct(os = "linux", cpu = "aarch64"),
    "x86_64-linux-musl": struct(os = "linux", cpu = "x86_64"),
}

_JSONNET_PLATFORM_INFO = {
    "darwin_amd64": struct(os = "osx", cpu = "x86_64"),
    "darwin_arm64": struct(os = "osx", cpu = "aarch64"),
    "linux_amd64": struct(os = "linux", cpu = "x86_64"),
    "linux_arm64": struct(os = "linux", cpu = "aarch64"),
}

def _jsonnet_impl(module_ctx):
    for module in module_ctx.modules:
        for toolchain in module.tags.toolchain:
            _downloaded_jsonnet_toolchains_repo(
                name = toolchain.name + "_toolchains",
                compiler = toolchain.compiler,
                version = toolchain.version,
            )

jsonnet = module_extension(
    implementation = _jsonnet_impl,
    tag_classes = {
        "toolchain": tag_class(
            attrs = {
                "name": attr.string(mandatory = True),
                "compiler": attr.string(default = "go"),
                "version": attr.string(),
            },
        ),
    },
)

def _platform_constraints(platform_info):
    return [
        "@platforms//os:%s" % platform_info.os,
        "@platforms//cpu:%s" % platform_info.cpu,
    ]

def _toolchain_target(name, platform_info):
    constraints = _platform_constraints(platform_info)
    return """
toolchain(
    name = "{name}",
    exec_compatible_with = {constraints},
    toolchain = "//toolchain:{name}_impl",
    toolchain_type = "@rules_jsonnet//jsonnet:toolchain_type",
)
""".format(
        name = name,
        constraints = repr(constraints),
    )

def _toolchain_impl_target(name, compiler, create_directory_flags, manifest_file_support):
    return """
jsonnet_toolchain(
    name = "{name}_impl",
    compiler = "{compiler}",
    create_directory_flags = {create_directory_flags},
    manifest_file_support = {manifest_file_support},
)
""".format(
        name = name,
        compiler = compiler,
        create_directory_flags = repr(create_directory_flags),
        manifest_file_support = "True" if manifest_file_support else "False",
    )

def _download_toolchain_asset(ctx, asset, output):
    if asset.get("archive", False):
        ctx.download_and_extract(
            url = asset["url"],
            output = output,
            sha256 = asset["sha256"],
        )
    else:
        ctx.download(
            url = asset["url"],
            output = output + "/" + asset.get("binary", "jsonnet"),
            sha256 = asset["sha256"],
            executable = True,
        )

def _downloaded_toolchains(ctx, compiler_name, version, toolchains, platform_info, default_version, create_directory_flags, manifest_file_support):
    version = version or default_version
    if version not in toolchains:
        fail("Unsupported %s version '%s'. Supported versions: %s" % (compiler_name, version, sorted(toolchains.keys())))
    if not toolchains[version]:
        fail("No prebuilt %s binaries are known for version '%s'. Run the generator script after upstream publishes binary release assets." % (compiler_name, version))

    targets = []
    for platform, asset in toolchains[version].items():
        if platform not in platform_info:
            fail("Unsupported %s platform '%s' in version metadata" % (compiler_name, platform))
        target_name = "%s_%s" % (compiler_name.replace("-", "_"), platform.replace("-", "_"))
        output = "toolchain/%s" % target_name
        _download_toolchain_asset(ctx, asset, output)
        targets.append(target_name)

    return struct(
        targets = targets,
        root_build = "".join([
            _toolchain_target(
                name = "%s_%s" % (compiler_name.replace("-", "_"), platform.replace("-", "_")),
                platform_info = platform_info[platform],
            )
            for platform in toolchains[version]
        ]),
        toolchain_build = "".join([
            _toolchain_impl_target(
                name = "%s_%s" % (compiler_name.replace("-", "_"), platform.replace("-", "_")),
                compiler = "%s_%s/%s" % (compiler_name.replace("-", "_"), platform.replace("-", "_"), toolchains[version][platform].get("binary", "jsonnet")),
                create_directory_flags = create_directory_flags,
                manifest_file_support = manifest_file_support,
            )
            for platform in toolchains[version]
        ]),
    )

def _go_jsonnet_toolchains(ctx):
    return _downloaded_toolchains(
        ctx = ctx,
        compiler_name = "go_jsonnet",
        version = ctx.attr.version,
        toolchains = GO_JSONNET_TOOLCHAINS,
        platform_info = _GO_PLATFORM_INFO,
        default_version = GO_JSONNET_DEFAULT_VERSION,
        create_directory_flags = ["-c"],
        manifest_file_support = True,
    )

def _jrsonnet_toolchains(ctx):
    return _downloaded_toolchains(
        ctx = ctx,
        compiler_name = "jrsonnet",
        version = ctx.attr.version,
        toolchains = JRSONNET_TOOLCHAINS,
        platform_info = _JRSONNET_PLATFORM_INFO,
        default_version = JRSONNET_DEFAULT_VERSION,
        create_directory_flags = ["-c"],
        manifest_file_support = False,
    )

def _jsonnet_toolchains(ctx):
    return _downloaded_toolchains(
        ctx = ctx,
        compiler_name = "jsonnet",
        version = ctx.attr.version,
        toolchains = JSONNET_TOOLCHAINS,
        platform_info = _JSONNET_PLATFORM_INFO,
        default_version = JSONNET_DEFAULT_VERSION,
        create_directory_flags = [],
        manifest_file_support = True,
    )

def _downloaded_jsonnet_toolchains_repo_impl(ctx):
    compiler = ctx.attr.compiler
    if compiler == "go":
        toolchains = _go_jsonnet_toolchains(ctx)
    elif compiler == "jrsonnet":
        toolchains = _jrsonnet_toolchains(ctx)
    elif compiler == "jsonnet":
        toolchains = _jsonnet_toolchains(ctx)
    else:
        fail("Unsupported Jsonnet compiler '%s'. Supported compilers: go, jrsonnet, jsonnet" % compiler)

    ctx.file(
        "BUILD.bazel",
        content = """
package(default_visibility = ["//visibility:public"])

%s
""" % toolchains.root_build,
        executable = False,
    )
    ctx.file(
        "toolchain/BUILD.bazel",
        content = """
load("@rules_jsonnet//jsonnet:toolchain.bzl", "jsonnet_toolchain")

package(default_visibility = ["//visibility:public"])

%s
""" % toolchains.toolchain_build,
        executable = False,
    )

_downloaded_jsonnet_toolchains_repo = repository_rule(
    implementation = _downloaded_jsonnet_toolchains_repo_impl,
    attrs = {
        "compiler": attr.string(),
        "version": attr.string(),
    },
)
