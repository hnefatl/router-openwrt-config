import pathlib
import unittest

from config_files import *


def write(dir: pathlib.Path, filename: str, contents: str) -> pathlib.Path:
    path = dir / filename
    path.write_text(contents)
    return path


class TestFiles(unittest.TestCase):
    def setUp(self):
        super().setUp()
        self.maxDiff = 10000

    def test_temp_directory(self):
        with temp_directory() as d:
            self.assertTrue(d.exists())
        self.assertFalse(d.exists())

    def test_template(self):
        with temp_directory() as sot_dir, temp_directory() as target_dir:
            secrets = {"secret": "mysecret"}
            template_sot_file = write(
                sot_dir,
                "template.tmpl",
                'foo = "${secret}"',
            )
            template_expanded = 'foo = "mysecret"'
            template_target_file = write(
                target_dir,
                "template",
                template_expanded,
            )

            other_sot_file = write(sot_dir, "zzzother", "other")
            other_target_file = write(target_dir, "zzzother", "other")

            missing_in_target_file = write(sot_dir, "missing_in_target", "foo")
            write(target_dir, "missing_in_sot", "foo")

            files = files_from_dir(sot_dir, target_dir, secrets)

            self.assertListEqual(
                files,
                [
                    File(
                        sot_path=missing_in_target_file,
                        sot_expanded_contents="foo",
                        target_path=target_dir / "missing_in_target",
                        target_contents=None,
                    ),
                    File(
                        sot_path=template_sot_file,
                        sot_expanded_contents=template_expanded,
                        target_path=template_target_file,
                        target_contents=template_expanded,
                    ),
                    File(
                        sot_path=other_sot_file,
                        sot_expanded_contents="other",
                        target_path=other_target_file,
                        target_contents="other",
                    ),
                ],
            )

    def test_tabs(self):
        with temp_directory() as sot_dir, temp_directory() as target_dir:
            write(sot_dir, "foo", "    ")
            write(target_dir, "foo", "\t")
            files = files_from_dir(sot_dir, target_dir, {})

            self.assertListEqual(
                files,
                [
                    File(
                        sot_path=sot_dir / "foo",
                        sot_expanded_contents="    ",
                        target_path=target_dir / "foo",
                        target_contents="    ",
                    ),
                ],
            )

    def test_directories(self):
        with temp_directory() as sot_dir, temp_directory() as target_dir:
            d = sot_dir / "dir"
            d.mkdir()
            write(d, "foo", "foo")

            files = files_from_dir(sot_dir, target_dir, {})

            self.assertListEqual(
                files,
                [
                    File(
                        sot_path=d / "foo",
                        sot_expanded_contents="foo",
                        target_path=target_dir / "dir/foo",
                        target_contents=None,
                    ),
                ],
            )

    def test_write_target(self):
        with temp_directory() as d:
            f = File(
                sot_path=d / "foo",
                sot_expanded_contents="",
                target_path=d / "dir/foo",
                target_contents=None,
            )
            f.write_target("foo")
            self.assertEqual(f.target_path.read_text(), "foo")
