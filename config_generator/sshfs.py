import contextlib
import os
import pathlib
import subprocess
import sys


@contextlib.contextmanager
def mount(target_connection_str: str, dir: pathlib.Path):
    """Context manager to mount/unmount sshfs"""
    try:
        subprocess.check_call(
            args=[
                "sshfs",
                "-o",
                f"uid={os.getuid()}",
                "-o",
                f"gid={os.getgid()}",
                f"{target_connection_str}:/",
                dir,
            ],
            stdout=sys.stdout,
            stderr=sys.stderr,
        )
        yield
    finally:
        subprocess.check_call(
            args=["umount", dir],
            stdout=sys.stdout,
            stderr=sys.stderr,
        )
