def _unpack_nix_image_impl(ctx):
    output_dir = ctx.actions.declare_directory("layout")

    wrapper = ctx.actions.declare_file(ctx.label.name + "_wrapper.sh")
    ctx.actions.write(
        output = wrapper,
        content = """#!/usr/bin/env bash
set -euo pipefail

STREAM="{generator_script}"
OUT="{output_dir}"
SCRIPT="{docker_to_oci}"

mkdir -p "$OUT"
"$STREAM" > "$OUT/docker.tar"

bash "$SCRIPT" "$OUT/docker.tar" "$OUT"
""".format(
            output_dir=output_dir.path,
            generator_script=ctx.executable.generator_script.path,
            docker_to_oci=ctx.file._docker_to_oci.path,
        ),
        is_executable = True,
    )

    ctx.actions.run(
        inputs = [ctx.executable.generator_script, ctx.file._docker_to_oci],
        outputs = [output_dir],
        executable = wrapper,
        use_default_shell_env = True,
        execution_requirements = {
            "no-sandbox": "1",
        },
    )

    return [DefaultInfo(files = depset([output_dir]))]

unpack_nix_image = rule(
    implementation = _unpack_nix_image_impl,
    attrs = {
        "generator_script": attr.label(
            allow_single_file = True,
            mandatory = True,
            executable = True,
            cfg = "exec",
        ),
        "_docker_to_oci": attr.label(
            allow_single_file = True,
            default = "//tools/oci:docker_to_oci.sh",
        ),
    },
)

