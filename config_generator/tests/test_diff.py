import textwrap
import unittest

import diff

class TestDiff(unittest.TestCase):
    def test_print_diff(self):
        a = textwrap.dedent(
            """\
            foo bing
            bar baz
            """
        )
        b = textwrap.dedent(
            """\
            foo
            bar baz
            bop
            """
        )
        expected = textwrap.dedent(
            """\
            --- 
            +++ 
            @@ -1,2 +1,3 @@
            -foo bing
            +foo
             bar baz
            +bop"""
        )
        self.assertEqual(diff.get_diff(a, b, colourise=False), expected)
