import contextlib
import os
import pathlib
import subprocess
import sys


@contextlib.contextmanager
def mount(hostname: str, dir: pathlib.Path):
    """Context manager to mount/unmount sshfs"""
    try:
        r = subprocess.check_call(
            args=[
                "sshfs",
                "-o",
                f"uid={os.getuid()}",
                "-o",
                f"gid={os.getgid()}",
                "-o",
                "follow_symlinks",
                f"{hostname}:/etc/config",
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
