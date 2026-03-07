# Documentation Drift Control v0.2

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/portal/DOCUMENTATION_TREE.md`
- `formats/documentation_tree_v0_2.yaml`
- `formats/root_decision_tree_dependencies.yaml`
- `scripts/ci/check_documentation_tree_sync.sh`
- `scripts/ci/check_root_decision_tree_sync.sh`

## Что это такое
Это предохранитель от рассинхронизации документации.

## Простыми словами
Если меняется важный документ, проект должен автоматически понимать:
- что изменилось;
- насколько изменилось;
- какие ещё документы теперь нужно пересмотреть.

## Что он защищает
- корень документации;
- ствол проекта;
- README и обзорный слой;
- stage-документы;
- навигацию и дерево документации.

## Что обязан делать guard
- пересчитывать документное дерево;
- считать строки по документам и по дереву;
- показывать путь влияния на `README.md`;
- валить CI, если зависимые документы не синхронизированы.

## Observability и реакция
Gap:
- `observability_gap.documentation_drift_detected`

## Связанные runbooks
- `docs/runbooks/documentation_drift_detected.md`
