import pathlib
import tomllib

Secrets = dict[str, str]

def load_secrets(file: pathlib.Path) -> Secrets:
    return tomllib.loads(file.read_text())
