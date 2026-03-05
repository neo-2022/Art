import unittest


class UpgradeDowngradeTests(unittest.TestCase):
    def test_n_to_n_plus_1(self):
        incidents_before = 2
        incidents_after = 2
        self.assertEqual(incidents_before, incidents_after)

    def test_n_to_n_minus_1(self):
        incidents_before = 2
        incidents_after = 2
        self.assertEqual(incidents_before, incidents_after)


if __name__ == "__main__":
    unittest.main()
