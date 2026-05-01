import difflib
import pathlib


def print_diff_paths(a: pathlib.Path, b: pathlib.Path, colourise: bool = True):
    get_diff(a.read_text(), b.read_text())


def print_diff(a: str, b: str, colourise: bool = True):
    print(get_diff(a, b, colourise), end="")


def get_diff(a: str, b: str, colourise: bool = True) -> str:
    a_lines = a.splitlines()
    b_lines = b.splitlines()
    if a_lines == b_lines:
        return "Files are identical."

    diff = difflib.unified_diff(a_lines, b_lines, lineterm="")
    return "\n".join(_colourify_line(line) if colourise else line for line in diff)


def _colourify_line(line: str) -> str:
    # https://stackoverflow.com/a/64404008/2193020
    if line.startswith("-"):
        return f"\033[38;2;255;0;0m{line}\033[38;2;255;255;255m"
    elif line.startswith("+"):
        return f"\033[38;2;0;255;0m{line}\033[38;2;255;255;255m"
    return line
