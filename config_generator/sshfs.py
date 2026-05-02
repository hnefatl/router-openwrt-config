import contextlib
import os
import pathlib
import subprocess


@contextlib.contextmanager
def mount(hostname: str, dir: pathlib.Path):
    """Context manager to mount/unmount sshfs"""
    try:
        subprocess.check_call(
            args=[
                "sshfs",
                "-o",
                f"uid={os.getuid()}",
                "-o",
                f"gid={os.getgid()}",
                f"{hostname}:/etc/config",
                dir,
            ]
        )
        yield
    finally:
        subprocess.check_call(args=["umount", dir])
