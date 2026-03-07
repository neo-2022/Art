import tempfile
import unittest
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[2]
BUDGET = ROOT / 'formats/monolith_budget_guard_v0_2.yaml'

class MonolithBudgetGuardTests(unittest.TestCase):
    def test_budget_file_matches_real_line_counts(self):
        data = yaml.safe_load(BUDGET.read_text(encoding='utf-8'))
        self.assertTrue(data['critical_files'])
        for item in data['critical_files']:
            path = ROOT / item['path']
            self.assertTrue(path.exists(), item['path'])
            with path.open('r', encoding='utf-8') as handle:
                actual = sum(1 for _ in handle)
            self.assertEqual(actual, item['current_lines'], item['path'])
            self.assertLessEqual(actual, item['budget_lines'], item['path'])

    def test_budget_would_fail_on_growth(self):
        data = yaml.safe_load(BUDGET.read_text(encoding='utf-8'))
        sample = data['critical_files'][0]
        with (ROOT / sample['path']).open('r', encoding='utf-8') as handle:
            actual = sum(1 for _ in handle)
        grown = actual + 1
        self.assertGreater(grown, sample['budget_lines'])

    def test_budget_contains_defect_binding(self):
        data = yaml.safe_load(BUDGET.read_text(encoding='utf-8'))
        for item in data['critical_files']:
            self.assertTrue(item['defect_ids'])
            self.assertTrue(item['stages'])
            self.assertTrue(item['rationale'])

if __name__ == '__main__':
    unittest.main()
