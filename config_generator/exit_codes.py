import dataclasses


@dataclasses.dataclass
class ExitError(RuntimeError):
    """A mechanism for terminating control flow with a user-friendly error, instead of a stack trace."""

    message: str
    code: int

    def __init__(self, message: str):
        self.message = message


class UnknownTargetError(ExitError):
    code = 1


class MissingSecretsFileError(ExitError):
    code = 2
