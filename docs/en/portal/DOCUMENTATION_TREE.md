# Графическое дерево документации Art

## Source of truth
- [`../../../README.md`](../../../README.md)
- [`../../../formats/documentation_tree_rules_v0_2.yaml`](../../../formats/documentation_tree_rules_v0_2.yaml)
- [`../../../formats/documentation_tree_v0_2.yaml`](../../../formats/documentation_tree_v0_2.yaml)
- [`../../../scripts/ci/generate_documentation_tree.py`](../../../scripts/ci/generate_documentation_tree.py)
- [`../../../scripts/ci/check_documentation_tree_sync.sh`](../../../scripts/ci/check_documentation_tree_sync.sh)

## Назначение
Это отдельный навигационно-контрольный слой документации.

Он не заменяет дерево принятия решений проекта.
Он показывает:
- как документация реально связана от корневого `README.md`;
- сколько документов входит в дерево;
- сколько строк в каждом документе;
- какие документы прямо влияют на корневой `README.md`;
- где возможен drift, который требует обновить корневой `README.md`.

## Что даёт этот слой
- быстрый вход в документацию без потери контекста;
- защиту от неучтённых изменений в ключевых документах;
- наглядную карту зависимостей;
- контроль того, что изменения смыслообразующих документов не проходят мимо корневого `README.md`.

## Сводка
- Корень дерева: [`../../../README.md`](../../../README.md)
- Строк в корневом `README.md`: `155`
- Уникальных документов в дереве: `59`
- Общих строк во всём дереве: `8477`
- Всех файловых связей в дереве: `122`
- Просканированных markdown-ссылок: `138`
- Прямых дочерних ссылок у корня: `33`
- Документов с признаком `ROOT-INFLUENCE`: `17`

## Граф
```mermaid
graph TD
    N1["CHANGELOG.md\n15 строк"]
    N2["README.md\n155 строк"]
    N3["RELEASE_CHECKLIST.md\n25 строк"]
    N4["SECURITY.md\n15 строк"]
    N5["docs/ARCHITECTURE.md\n75 строк"]
    N6["docs/INTEGRATION.md\n47 строк\nROOT-INFLUENCE"]
    N7["docs/README.md\n100 строк\nROOT-INFLUENCE"]
    N8["docs/api/openapi.yaml\n82 строк"]
    N9["docs/contracts/v2/openapi.yaml\n199 строк"]
    N10["docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md\n183 строк"]
    N11["docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md\n174 строк"]
    N12["docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md\n764 строк\nROOT-INFLUENCE"]
    N13["docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md\n537 строк"]
    N14["docs/foundation/frontier_tech_radar.md\n46 строк"]
    N15["docs/foundation/lens_audit_report.md\n410 строк"]
    N16["docs/foundation/revolutionary_hypotheses.md\n173 строк"]
    N17["docs/governance/evidence/evidence_ledger.yaml\n265 строк"]
    N18["docs/governance/evidence_policy.md\n29 строк"]
    N19["docs/governance/observability_gap_registry.md\n68 строк"]
    N20["docs/governance/release_decisions/latest_go_no_go.md\n83 строк"]
    N21["docs/ops/github_actions_queue_remediation_plan.md\n212 строк"]
    N22["docs/ops/go_no_go_template.md\n129 строк"]
    N23["docs/ops/platform-container-k8s-testing.md\n68 строк"]
    N24["docs/ops/platform-runtime-compatibility-matrix.md\n43 строк"]
    N25["docs/ops/platform-support.md\n98 строк\nROOT-INFLUENCE"]
    N26["docs/ops/platform-vm-testing.md\n54 строк"]
    N27["docs/portal/ART_VISUAL_LANGUAGE.md\n119 строк"]
    N28["docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md\n13 строк"]
    N29["docs/portal/DELIVERY_EVIDENCE.md\n26 строк"]
    N30["docs/portal/DOC_AUTHORITY.md\n19 строк"]
    N31["docs/portal/DOC_STYLE_GUIDE.md\n22 строк"]
    N32["docs/portal/GLOSSARY.md\n14 строк"]
    N33["docs/portal/INDEX.md\n61 строк"]
    N34["docs/portal/PRODUCT_GUARANTEES.md\n14 строк"]
    N35["docs/portal/SECURITY_POSTURE.md\n14 строк"]
    N36["docs/regart/art_bridge_runbook.md\n19 строк"]
    N37["docs/regart/upstream_error_format.md\n29 строк"]
    N38["docs/release/compat_matrix.md\n40 строк"]
    N39["docs/release/release_process.md\n33 строк\nROOT-INFLUENCE"]
    N40["docs/release/versioning.md\n35 строк"]
    N41["docs/security/fstec-certified-profile.md\n30 строк"]
    N42["docs/source/Art_v1_spec_final.md\n614 строк\nROOT-INFLUENCE"]
    N43["docs/source/FOUNDATION_CONSTITUTION_V0_2.md\n693 строк\nROOT-INFLUENCE"]
    N44["docs/source/README.md\n57 строк\nROOT-INFLUENCE"]
    N45["docs/source/REGART -  LangGraph  взаимодействие с Art описание.md\n313 строк\nROOT-INFLUENCE"]
    N46["docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md\n290 строк\nROOT-INFLUENCE"]
    N47["docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md\n124 строк"]
    N48["docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md\n125 строк"]
    N49["docs/source/checklists/CHECKLIST_20_PACK_REGART.md\n125 строк"]
    N50["docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md\n78 строк\nROOT-INFLUENCE"]
    N51["docs/source/checklists/README.md\n89 строк"]
    N52["docs/source/dna_core_determinism_performance_assurance.md\n138 строк\nROOT-INFLUENCE"]
    N53["docs/source/risk_register_v0_2.md\n42 строк\nROOT-INFLUENCE"]
    N54["docs/source/secure_actions_protocol_v2.md\n27 строк"]
    N55["docs/testing/defect_remediation_control_matrix_v0_2.md\n414 строк\nROOT-INFLUENCE"]
    N56["docs/testing/defect_remediation_ladder_v0_2.md\n258 строк\nROOT-INFLUENCE"]
    N57["docs/testing/production_adversarial_validation_law.md\n203 строк"]
    N58["docs/testing/test_system_audit_v0_2.md\n97 строк"]
    N59["formats/platform_support.yaml\n253 строк"]
    N2 --> N20
    N2 --> N3
    N2 --> N1
    N2 --> N29
    N2 --> N42
    N2 --> N43
    N2 --> N46
    N2 --> N50
    N2 --> N53
    N2 --> N52
    N2 --> N7
    N2 --> N8
    N2 --> N9
    N2 --> N59
    N2 --> N25
    N2 --> N24
    N2 --> N26
    N2 --> N23
    N2 --> N41
    N2 --> N39
    N2 --> N40
    N2 --> N38
    N2 --> N22
    N2 --> N17
    N2 --> N12
    N2 --> N11
    N2 --> N10
    N2 --> N27
    N2 --> N33
    N2 --> N44
    N2 --> N51
    N2 --> N6
    N2 --> N4
    N5 --> N42
    N5 --> N43
    N5 --> N13
    N5 --> N46
    N5 --> N45
    N5 --> N55
    N5 --> N56
    N5 --> N6
    N6 --> N45
    N6 --> N42
    N6 --> N47
    N6 --> N48
    N6 --> N49
    N6 --> N56
    N6 --> N36
    N6 --> N37
    N7 --> N42
    N7 --> N43
    N7 --> N46
    N7 --> N44
    N7 --> N2
    N7 --> N33
    N7 --> N11
    N7 --> N10
    N7 --> N12
    N7 --> N13
    N7 --> N16
    N7 --> N14
    N7 --> N15
    N7 --> N5
    N7 --> N6
    N7 --> N34
    N7 --> N35
    N7 --> N25
    N7 --> N24
    N7 --> N26
    N7 --> N23
    N7 --> N22
    N7 --> N21
    N7 --> N39
    N7 --> N40
    N7 --> N38
    N7 --> N29
    N7 --> N18
    N7 --> N19
    N7 --> N17
    N7 --> N51
    N7 --> N53
    N7 --> N52
    N7 --> N57
    N7 --> N58
    N13 --> N43
    N13 --> N12
    N13 --> N42
    N13 --> N46
    N33 --> N7
    N33 --> N43
    N33 --> N46
    N33 --> N6
    N33 --> N12
    N33 --> N11
    N33 --> N10
    N33 --> N16
    N33 --> N14
    N33 --> N42
    N33 --> N45
    N33 --> N56
    N33 --> N5
    N33 --> N32
    N33 --> N34
    N33 --> N25
    N33 --> N26
    N33 --> N23
    N33 --> N22
    N33 --> N21
    N33 --> N27
    N33 --> N29
    N33 --> N35
    N33 --> N28
    N33 --> N30
    N33 --> N31
    N33 --> N8
    N33 --> N9
    N33 --> N54
    N33 --> N36
    N38 --> N40
    N38 --> N39
    N38 --> N25
    N38 --> N24
```

## Дерево ссылок
- [`README.md`](../../../README.md) — `155` строк
  - [`docs/governance/release_decisions/latest_go_no_go.md`](../../governance/release_decisions/latest_go_no_go.md) — `83` строк
  - [`RELEASE_CHECKLIST.md`](../../../RELEASE_CHECKLIST.md) — `25` строк
  - [`CHANGELOG.md`](../../../CHANGELOG.md) — `15` строк
  - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
  - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
  - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`](../../source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md) — `78` строк `ROOT-INFLUENCE`
  - [`docs/source/risk_register_v0_2.md`](../../source/risk_register_v0_2.md) — `42` строк `ROOT-INFLUENCE`
  - [`docs/source/dna_core_determinism_performance_assurance.md`](../../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
  - [`docs/README.md`](../../README.md) — `100` строк `ROOT-INFLUENCE`
    - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
    - [`docs/source/README.md`](../../source/README.md) — `57` строк `ROOT-INFLUENCE`
    - [`README.md`](../../../README.md) — `155` строк `REUSED-LINK`
    - [`docs/portal/INDEX.md`](../../portal/INDEX.md) — `61` строк
      - [`docs/README.md`](../../README.md) — `100` строк `ROOT-INFLUENCE` `REUSED-LINK`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
      - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
      - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
      - [`docs/foundation/revolutionary_hypotheses.md`](../../foundation/revolutionary_hypotheses.md) — `173` строк
      - [`docs/foundation/frontier_tech_radar.md`](../../foundation/frontier_tech_radar.md) — `46` строк
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
      - [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) — `75` строк
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
        - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
          - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
          - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `414` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
        - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
          - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
          - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
          - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
          - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
          - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
          - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
      - [`docs/portal/GLOSSARY.md`](../../portal/GLOSSARY.md) — `14` строк
      - [`docs/portal/PRODUCT_GUARANTEES.md`](../../portal/PRODUCT_GUARANTEES.md) — `14` строк
      - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
      - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
      - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `129` строк
      - [`docs/ops/github_actions_queue_remediation_plan.md`](../../ops/github_actions_queue_remediation_plan.md) — `212` строк
      - [`docs/portal/ART_VISUAL_LANGUAGE.md`](../../portal/ART_VISUAL_LANGUAGE.md) — `119` строк
      - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
      - [`docs/portal/SECURITY_POSTURE.md`](../../portal/SECURITY_POSTURE.md) — `14` строк
      - [`docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md`](../../portal/COMPATIBILITY_MATRIX_ART_REGART.md) — `13` строк
      - [`docs/portal/DOC_AUTHORITY.md`](../../portal/DOC_AUTHORITY.md) — `19` строк
      - [`docs/portal/DOC_STYLE_GUIDE.md`](../../portal/DOC_STYLE_GUIDE.md) — `22` строк
      - [`docs/api/openapi.yaml`](../../api/openapi.yaml) — `82` строк
      - [`docs/contracts/v2/openapi.yaml`](../../contracts/v2/openapi.yaml) — `199` строк
      - [`docs/source/secure_actions_protocol_v2.md`](../../source/secure_actions_protocol_v2.md) — `27` строк
      - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
    - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
    - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
    - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
    - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
    - [`docs/foundation/revolutionary_hypotheses.md`](../../foundation/revolutionary_hypotheses.md) — `173` строк
    - [`docs/foundation/frontier_tech_radar.md`](../../foundation/frontier_tech_radar.md) — `46` строк
    - [`docs/foundation/lens_audit_report.md`](../../foundation/lens_audit_report.md) — `410` строк
    - [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) — `75` строк
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `414` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
    - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
      - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
      - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
      - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
      - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
    - [`docs/portal/PRODUCT_GUARANTEES.md`](../../portal/PRODUCT_GUARANTEES.md) — `14` строк
    - [`docs/portal/SECURITY_POSTURE.md`](../../portal/SECURITY_POSTURE.md) — `14` строк
    - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
    - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
    - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
    - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `129` строк
    - [`docs/ops/github_actions_queue_remediation_plan.md`](../../ops/github_actions_queue_remediation_plan.md) — `212` строк
    - [`docs/release/release_process.md`](../../release/release_process.md) — `33` строк `ROOT-INFLUENCE`
    - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
    - [`docs/release/compat_matrix.md`](../../release/compat_matrix.md) — `40` строк
      - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
      - [`docs/release/release_process.md`](../../release/release_process.md) — `33` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
    - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
    - [`docs/governance/evidence_policy.md`](../../governance/evidence_policy.md) — `29` строк
    - [`docs/governance/observability_gap_registry.md`](../../governance/observability_gap_registry.md) — `68` строк
    - [`docs/governance/evidence/evidence_ledger.yaml`](../../governance/evidence/evidence_ledger.yaml) — `265` строк
    - [`docs/source/checklists/README.md`](../../source/checklists/README.md) — `89` строк
    - [`docs/source/risk_register_v0_2.md`](../../source/risk_register_v0_2.md) — `42` строк `ROOT-INFLUENCE`
    - [`docs/source/dna_core_determinism_performance_assurance.md`](../../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
    - [`docs/testing/production_adversarial_validation_law.md`](../../testing/production_adversarial_validation_law.md) — `203` строк
    - [`docs/testing/test_system_audit_v0_2.md`](../../testing/test_system_audit_v0_2.md) — `97` строк
  - [`docs/api/openapi.yaml`](../../api/openapi.yaml) — `82` строк
  - [`docs/contracts/v2/openapi.yaml`](../../contracts/v2/openapi.yaml) — `199` строк
  - [`formats/platform_support.yaml`](../../../formats/platform_support.yaml) — `253` строк
  - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
  - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
  - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
  - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
  - [`docs/security/fstec-certified-profile.md`](../../security/fstec-certified-profile.md) — `30` строк
  - [`docs/release/release_process.md`](../../release/release_process.md) — `33` строк `ROOT-INFLUENCE`
  - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
  - [`docs/release/compat_matrix.md`](../../release/compat_matrix.md) — `40` строк
    - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
    - [`docs/release/release_process.md`](../../release/release_process.md) — `33` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
  - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `129` строк
  - [`docs/governance/evidence/evidence_ledger.yaml`](../../governance/evidence/evidence_ledger.yaml) — `265` строк
  - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
  - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
  - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
  - [`docs/portal/ART_VISUAL_LANGUAGE.md`](../../portal/ART_VISUAL_LANGUAGE.md) — `119` строк
  - [`docs/portal/INDEX.md`](../../portal/INDEX.md) — `61` строк
    - [`docs/README.md`](../../README.md) — `100` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
      - [`docs/source/README.md`](../../source/README.md) — `57` строк `ROOT-INFLUENCE`
      - [`README.md`](../../../README.md) — `155` строк `REUSED-LINK`
      - [`docs/portal/INDEX.md`](../../portal/INDEX.md) — `61` строк `REUSED-LINK`
      - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
      - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
      - [`docs/foundation/revolutionary_hypotheses.md`](../../foundation/revolutionary_hypotheses.md) — `173` строк
      - [`docs/foundation/frontier_tech_radar.md`](../../foundation/frontier_tech_radar.md) — `46` строк
      - [`docs/foundation/lens_audit_report.md`](../../foundation/lens_audit_report.md) — `410` строк
      - [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) — `75` строк
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
        - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
          - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
          - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `414` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
        - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
          - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
          - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
          - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
          - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
          - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
          - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
      - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
      - [`docs/portal/PRODUCT_GUARANTEES.md`](../../portal/PRODUCT_GUARANTEES.md) — `14` строк
      - [`docs/portal/SECURITY_POSTURE.md`](../../portal/SECURITY_POSTURE.md) — `14` строк
      - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
      - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
      - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
      - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `129` строк
      - [`docs/ops/github_actions_queue_remediation_plan.md`](../../ops/github_actions_queue_remediation_plan.md) — `212` строк
      - [`docs/release/release_process.md`](../../release/release_process.md) — `33` строк `ROOT-INFLUENCE`
      - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
      - [`docs/release/compat_matrix.md`](../../release/compat_matrix.md) — `40` строк
        - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
        - [`docs/release/release_process.md`](../../release/release_process.md) — `33` строк `ROOT-INFLUENCE`
        - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
        - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
      - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
      - [`docs/governance/evidence_policy.md`](../../governance/evidence_policy.md) — `29` строк
      - [`docs/governance/observability_gap_registry.md`](../../governance/observability_gap_registry.md) — `68` строк
      - [`docs/governance/evidence/evidence_ledger.yaml`](../../governance/evidence/evidence_ledger.yaml) — `265` строк
      - [`docs/source/checklists/README.md`](../../source/checklists/README.md) — `89` строк
      - [`docs/source/risk_register_v0_2.md`](../../source/risk_register_v0_2.md) — `42` строк `ROOT-INFLUENCE`
      - [`docs/source/dna_core_determinism_performance_assurance.md`](../../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
      - [`docs/testing/production_adversarial_validation_law.md`](../../testing/production_adversarial_validation_law.md) — `203` строк
      - [`docs/testing/test_system_audit_v0_2.md`](../../testing/test_system_audit_v0_2.md) — `97` строк
    - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
    - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
      - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
      - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
      - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
      - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
    - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
    - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
    - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
    - [`docs/foundation/revolutionary_hypotheses.md`](../../foundation/revolutionary_hypotheses.md) — `173` строк
    - [`docs/foundation/frontier_tech_radar.md`](../../foundation/frontier_tech_radar.md) — `46` строк
    - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
    - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
    - [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) — `75` строк
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `414` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
    - [`docs/portal/GLOSSARY.md`](../../portal/GLOSSARY.md) — `14` строк
    - [`docs/portal/PRODUCT_GUARANTEES.md`](../../portal/PRODUCT_GUARANTEES.md) — `14` строк
    - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
    - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
    - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `129` строк
    - [`docs/ops/github_actions_queue_remediation_plan.md`](../../ops/github_actions_queue_remediation_plan.md) — `212` строк
    - [`docs/portal/ART_VISUAL_LANGUAGE.md`](../../portal/ART_VISUAL_LANGUAGE.md) — `119` строк
    - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
    - [`docs/portal/SECURITY_POSTURE.md`](../../portal/SECURITY_POSTURE.md) — `14` строк
    - [`docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md`](../../portal/COMPATIBILITY_MATRIX_ART_REGART.md) — `13` строк
    - [`docs/portal/DOC_AUTHORITY.md`](../../portal/DOC_AUTHORITY.md) — `19` строк
    - [`docs/portal/DOC_STYLE_GUIDE.md`](../../portal/DOC_STYLE_GUIDE.md) — `22` строк
    - [`docs/api/openapi.yaml`](../../api/openapi.yaml) — `82` строк
    - [`docs/contracts/v2/openapi.yaml`](../../contracts/v2/openapi.yaml) — `199` строк
    - [`docs/source/secure_actions_protocol_v2.md`](../../source/secure_actions_protocol_v2.md) — `27` строк
    - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
  - [`docs/source/README.md`](../../source/README.md) — `57` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/README.md`](../../source/checklists/README.md) — `89` строк
  - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк `ROOT-INFLUENCE`
    - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
    - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
    - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
    - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
    - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк `ROOT-INFLUENCE`
    - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
    - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
  - [`SECURITY.md`](../../../SECURITY.md) — `15` строк

## Документы, влияющие на корневой README
Если изменяется любой документ из этого списка, а `README.md` не изменён, CI подаёт сигнал о рассинхроне.

- [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `47` строк
- [`docs/README.md`](../../README.md) — `100` строк
- [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `764` строк
- [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк
- [`docs/release/release_process.md`](../../release/release_process.md) — `33` строк
- [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк
- [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `693` строк
- [`docs/source/README.md`](../../source/README.md) — `57` строк
- [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк
- [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `290` строк
- [`docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`](../../source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md) — `78` строк
- `docs/source/checklists/TRACEABILITY_V0_2.md` — `НЕ ПОПАЛ В ДЕРЕВО`
- [`docs/source/dna_core_determinism_performance_assurance.md`](../../source/dna_core_determinism_performance_assurance.md) — `138` строк
- [`docs/source/risk_register_v0_2.md`](../../source/risk_register_v0_2.md) — `42` строк
- [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `414` строк
- [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `258` строк
- `formats/defect_remediation_control_matrix_v0_2.yaml` — `НЕ ПОПАЛ В ДЕРЕВО`

## Пропущенные directory-ссылки
Это ссылки в markdown на каталоги, а не на отдельные файлы. Они не включаются в дерево как отдельные вершины.

- `README.md` -> `docs/contracts/v2/schemas`
- `README.md` -> `docs/governance/evidence`
- `docs/README.md` -> `docs/governance/release_decisions`

## Missing targets
Если здесь появится запись, значит в документации есть ссылка на файл, который не найден.

- нет

## Статус
- Статус дерева: `ACTIVE`
- Корень документационного дерева: `README.md`
- Контроль рассинхрона: `ENABLED`
