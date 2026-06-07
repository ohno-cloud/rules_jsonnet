load("@rules_python//python:py_binary.bzl", "py_binary")
load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "bzl_srcs",
    srcs = ["@bazel_tools//tools:bzl_srcs"],
)

bzl_library(
    name = "docs",
    srcs = [
        "docs.bzl",
        "jsonnet.bzl",
        "toolchain.bzl",
    ],
    visibility = ["//visibility:public"],
    deps = [
        ":bzl_srcs",
        "@bazel_skylib//lib:paths",
        "@bazel_skylib//lib:shell",
    ],
)

starlark_doc_extract(
    name = "docs.extract",
    src = "docs.bzl",
    deps = [":docs"],
)

py_binary(
    name = "stamper",
    srcs = ["stamper.py"],
    main = "stamper.py",
    visibility = ["//visibility:public"],
)

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)
