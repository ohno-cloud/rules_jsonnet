[![Build status](https://badge.buildkite.com/c3449aba989713394a3237070971eb59b92ad19d6f69555a25.svg)](https://buildkite.com/bazel/rules-jsonnet-postsubmit)

# Jsonnet Rules

<div class="toc">
  <h2>Rules</h2>
  <ul>
    <li><a href="docs/jsonnet.md#jsonnet_library">jsonnet_library</a></li>
    <li><a href="docs/jsonnet.md#jsonnet_to_json">jsonnet_to_json</a></li>
    <li><a href="docs/jsonnet.md#jsonnet_to_json_test">jsonnet_to_json_test</a></li>
  </ul>
</div>

## Overview

These are build rules for working with [Jsonnet][jsonnet] files with Bazel.

[jsonnet]: https://jsonnet.org

## Setup

To use the Jsonnet rules as part of your Bazel project, please follow the
instructions on [the releases page](https://github.com/bazelbuild/rules_jsonnet/releases).

## Jsonnet Toolchains

This ruleset does not build or register a Jsonnet compiler by default. Register
one in your root module with the `jsonnet.toolchain` extension:

```starlark
bazel_dep(name = "rules_jsonnet", version = "...")

jsonnet = use_extension("@rules_jsonnet//jsonnet:extensions.bzl", "jsonnet")
jsonnet.toolchain(
    name = "jsonnet_go",
    compiler = "go",
    version = "0.22.0",
)
use_repo(jsonnet, "jsonnet_go_toolchains")

register_toolchains("@jsonnet_go_toolchains//:all")
```

The extension downloads prebuilt compilers. Supported compilers are:

| Jsonnet compiler | `compiler` value | Default version |
| ---------------- | ---------------- | --------------- |
| [go-jsonnet](https://github.com/google/go-jsonnet) | `go` | `0.22.0` |
| [jrsonnet](https://github.com/CertainLach/jrsonnet) | `jrsonnet` | `0.5.0-pre98` |
| [jsonnet](https://github.com/google/jsonnet) | `jsonnet` | `0.22.0` |

For jrsonnet, Linux downloads use the musl builds for portability.
The C++ jsonnet compiler is supported when upstream publishes matching
standalone binary release assets; current recent releases only publish source
archives.

You can also register a custom source-built or locally-provided compiler by
creating a `jsonnet_toolchain` target and registering it with
`register_toolchains`.

The version metadata used by the extension is generated in `jsonnet/version.bzl`.
Run `tools/update_toolchain_versions.sh` to refresh the known download URLs and
SHA256s. Override versions with `GO_JSONNET_VERSION`, `JRSONNET_VERSION`, or
`JSONNET_VERSION` when running the script.

## Rule usage

Please refer to [the StarDoc generated documentation](docs/jsonnet.md)
for instructions on how to use these rules.
