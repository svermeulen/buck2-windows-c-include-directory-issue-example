# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under both the MIT license found in the
# LICENSE-MIT file in the root directory of this source tree and the Apache
# License, Version 2.0 found in the LICENSE-APACHE file in the root directory
# of this source tree.

load("@prelude//android:android_binary_resources_rules.bzl", "get_manifest")
load("@prelude//android:android_providers.bzl", "merge_android_packageable_info")
load("@prelude//java:java_providers.bzl", "get_all_java_packaging_deps")
load("@prelude//java:java_toolchain.bzl", "JavaToolchainInfo")
load("@prelude//utils:utils.bzl", "flatten")
load("@prelude//zip_file:zip_file_toolchain.bzl", "ZipFileToolchainInfo")

def android_aar_impl(ctx: AnalysisContext) -> list[Provider]:
    deps = ctx.attrs.deps

    java_packaging_deps = [packaging_dep for packaging_dep in get_all_java_packaging_deps(ctx, deps)]
    android_packageable_info = merge_android_packageable_info(ctx.label, ctx.actions, deps)

    android_manifest = get_manifest(ctx, android_packageable_info, manifest_entries = {})

    jars = [dep.jar for dep in java_packaging_deps if dep.jar]
    classes_jar = ctx.actions.declare_output("classes.jar")
    java_toolchain = ctx.attrs._java_toolchain[JavaToolchainInfo]
    classes_jar_cmd = cmd_args([
        java_toolchain.jar_builder,
        "--entries-to-jar",
        ctx.actions.write("classes_jar_entries.txt", jars),
        "--output",
        classes_jar.as_output(),
    ]).hidden(jars)

    ctx.actions.run(classes_jar_cmd, category = "create_classes_jar")

    zip_file_toolchain = ctx.attrs._zip_file_toolchain[ZipFileToolchainInfo]
    create_zip_tool = zip_file_toolchain.create_zip

    entries = [android_manifest, classes_jar]
    entries_file = ctx.actions.write("entries.txt", flatten([[entry, "ignored_short_path", "false"] for entry in entries]))

    aar = ctx.actions.declare_output("{}.aar".format(ctx.label.name))
    create_aar_cmd = cmd_args([
        create_zip_tool,
        "--output_path",
        aar.as_output(),
        "--entries_file",
        entries_file,
        "--on_duplicate_entry",
        "fail",
    ]).hidden(entries)

    ctx.actions.run(create_aar_cmd, category = "create_aar")

    return [DefaultInfo(default_outputs = [aar])]
