#!/usr/bin/env python3

import argparse
import contextlib
import dataclasses
import enum
import pathlib
import subprocess
import sys

import config_secrets
import diff
from exit_codes import *
from config_files import *
import sshfs


@dataclasses.dataclass
class Args:
    target: str
    target_connection_str: str
    fake_sshfs_dir: pathlib.Path | None
    dry_run: bool


def parse_args() -> Args:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--target", required=True, help="Hostname of the target device."
    )
    parser.add_argument(
        "--target-connection-str",
        default="",
        help="user@ip string for use in sshfs.",
    )
    parser.add_argument(
        "--fake_sshfs_dir",
        default="",
        help="Don't use sshfs, output files to this directory instead.",
    )
    parser.add_argument(
        "--dry-run",
        default=True,
        action=argparse.BooleanOptionalAction,
        help="Dry-run mode.",
    )
    args = parser.parse_args()
    fake_sshfs_dir = None
    if args.fake_sshfs_dir:
        fake_sshfs_dir = pathlib.Path(args.fake_sshfs_dir)
        if not fake_sshfs_dir.is_absolute():
            raise RuntimeError("Absolute path required for fake sshfs dir.")
        if not fake_sshfs_dir.exists():
            raise RuntimeError("Fake sshfs dir must exist")

    return Args(
        target=args.target,
        target_connection_str=(
            args.target_connection_str
            if args.target_connection_str
            else f"root@{args.target}.lan"
        ),
        fake_sshfs_dir=fake_sshfs_dir,
        dry_run=bool(args.dry_run),
    )


def prompt(prompt: str) -> str:
    print(prompt, end="")
    return input()


def main():
    args = parse_args()
    if args.dry_run:
        print("Operating in dry-run mode.")

    # file -> config_generator -> root of repo
    root_config_dir = pathlib.Path(__file__).parent.parent
    target_config_dir = root_config_dir / "devices" / args.target
    if not target_config_dir.exists():
        raise UnknownTargetError(f"Unknown target: {args.target}")

    secrets_file = root_config_dir / "secrets" / f"{args.target}.toml"
    secrets = config_secrets.load_secrets(secrets_file) if secrets_file.exists() else {}

    with contextlib.ExitStack() as stack:
        if not args.fake_sshfs_dir:
            d = stack.enter_context(temp_directory())
            stack.enter_context(sshfs.mount(args.target_connection_str, d))
        else:
            d = args.fake_sshfs_dir
            print(f"Not using sshfs, output directory: {d}")

        files = files_from_dir(target_config_dir, d, secrets)
        files += special_files(root_config_dir, d)
        process_files(args, files, secrets)


def special_files(root_config_dir: pathlib.Path, output_dir: pathlib.Path) -> Files:
    """Special files that don't follow the per-host structure."""
    return [
        # There should be a symlink from
        # `/etc/dropbear/authorized_keys` -> `/etc/config/authorized_keys`
        # that this takes advantage of.
        File.load(
            sot_path=root_config_dir / "devices/authorized_keys",
            target_path=output_dir / "authorized_keys",
            secrets={},
        )
    ]


def process_files(args: Args, files: Files, secrets: config_secrets.Secrets):
    for file in files:
        if file.target_contents is None:
            if args.dry_run:
                print(f"[dry-run] Would create {file.target_path}")
            else:
                file.target_path.write_text(file.sot_expanded_contents)
            continue

        while file.sot_expanded_contents != file.target_contents:
            print(f"Diff between {file.target_path} and {file.sot_path}:")
            print(diff.get_diff(file.target_contents, file.sot_expanded_contents))
            if args.dry_run:
                print(f"[dry-run] Would edit {file.sot_path} and {file.target_path}")
                break

            c = prompt("Overwrite (l)ocal, overwrite (t)arget, (e)dit, or (s)kip: ")
            if c in ("l", "t"):
                if prompt("Are you sure (y/n)? ") == "y":
                    if c == "l":
                        file.sot_path.write_text(file.target_contents)
                    else:
                        file.target_path.write_text(file.sot_expanded_contents)
            elif c == "s":
                break
            elif c == "e":
                subprocess.check_call(["vim", "-d", file.sot_path, file.target_path])
            file.reload_contents(secrets)


if __name__ == "__main__":
    try:
        main()
    except ExitError as e:
        print(e.message)
        sys.exit(e.code)
