#!/usr/bin/env python3

import argparse
import difflib
import enum
import pathlib
import socket
import string
import sys
import tomllib


class Exit(enum.IntEnum):
    SUCCESS = 0
    UNKNOWN_HOST = 1
    CONFIG_DIFF = 2
    EXISTING_CONFIG = 3
    WRONG_FILE_TYPE = 4


def get_special_symlinks(
    root_config_dir: pathlib.Path, hostname: str
) -> dict[pathlib.Path, pathlib.Path]:
    # Paths relative to the root config dir.
    ps = {
        "devices/authorized_keys": "/etc/dropbear/authorized_keys",
        f"devices/{hostname}/adguardhome.yaml.tmpl": "/etc/adguardhome/adguardhome.yaml",
    }
    return {root_config_dir / k: pathlib.Path(v) for k, v in ps.items()}


def load_secrets(hostname: str) -> dict[str, str]:
    file = pathlib.Path(
        {
            "openwrt": "/external_usb/secrets.toml",
        }.get(hostname, "/secrets/secrets.toml")
    )
    return tomllib.loads(file.read_text())


def parse_args():
    parser = argparse.ArgumentParser(prog="sync")
    parser.add_argument("--config_dir", default="/etc/config")
    parser.add_argument("--secrets_file", default="")
    parser.add_argument("--hostname", default="")
    return parser.parse_args()


def main() -> Exit:
    args = parse_args()
    hostname = args.hostname or socket.gethostname()

    root_config_dir = pathlib.Path(args.config_dir)
    host_config_dir = root_config_dir / f"devices/{hostname}"
    if not host_config_dir.exists():
        print(f"Unknown host: {hostname}")
        return Exit.UNKNOWN_HOST

    secrets = load_secrets(hostname)
    special_paths = get_special_symlinks(root_config_dir, hostname)

    source_files = set(host_config_dir.iterdir()).union(special_paths.keys())
    for host_config in sorted(source_files):
        if not host_config.is_file():
            continue

        dest_config = root_config_dir / host_config.name
        if special_path := special_paths.get(host_config):
            dest_config = special_path
        assert host_config.is_absolute()
        assert dest_config.is_absolute()

        is_template = host_config.suffix == ".tmpl"
        if is_template and dest_config.suffix == ".tmpl":
            dest_config = dest_config.with_suffix("")

        print(f"Processing {host_config} -> {dest_config}")

        if is_template:
            template = string.Template(host_config.read_text())
            new_content = template.safe_substitute(secrets)

            if dest_config.is_symlink():
                print("Expected normal file, found symlink: might be misconfigured.")
                return Exit.WRONG_FILE_TYPE

            if dest_config.exists():
                current_content = dest_config.read_text()
                if current_content != new_content:
                    print("Config already exists")
                    print_diff(new_content, current_content)
                    print("Overwrite (y/n)? ", end="", flush=True)
                    if input().lower() != "y":
                        return Exit.CONFIG_DIFF

            dest_config.write_text(new_content)
        else:
            if dest_config.exists(follow_symlinks=False):
                # Might already be symlinked to the right file.
                if dest_config.is_symlink() and dest_config.readlink() == host_config:
                    continue
                print("Config already exists, not symlinking")
                print_diff_paths(host_config, dest_config)
                return Exit.EXISTING_CONFIG
            elif dest_config.exists():
                print("Expected symlink, found normal file: might be misconfigured")
                return Exit.WRONG_FILE_TYPE

            dest_config.symlink_to(host_config)

    return Exit.SUCCESS


def print_diff_paths(a: pathlib.Path, b: pathlib.Path):
    print_diff(a.read_text(), b.read_text())


def print_diff(a: str, b: str):
    a_lines = a.splitlines(keepends=True)
    b_lines = b.splitlines(keepends=True)
    if a_lines == b_lines:
        print("Files are identical.")
    else:
        diff = difflib.context_diff(a_lines, b_lines)
        print("".join(diff), end="")


def symlink_if_not_already(src: pathlib.Path, dst: pathlib.Path) -> bool:
    """Returns false if the destination exists and isn't already symlinked."""
    if src.exists():
        # Might already be symlinked to the right file.
        return src.is_symlink() and src.readlink() == dst
    src.symlink_to(dst)
    return True


if __name__ == "__main__":
    sys.exit(main())
