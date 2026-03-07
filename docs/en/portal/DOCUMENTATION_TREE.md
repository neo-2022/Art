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
- какие каталоговые узлы входят в дерево как самостоятельные сущности;
- какие документы прямо влияют на корневой `README.md`;
- где возможен drift, который требует обновить корневой `README.md`.

## Что даёт этот слой
- быстрый вход в документацию без потери контекста;
- защиту от неучтённых изменений в ключевых документах;
- наглядную карту зависимостей;
- контроль того, что изменения смыслообразующих документов не проходят мимо корневого `README.md`;
- отдельный контроль каталоговых узлов, которые раньше могли выпадать из дерева.

## Сводка
- Корень дерева: [`../../../README.md`](../../../README.md)
- Строк в корневом `README.md`: `179`
- Уникальных документов в дереве: `73`
- Каталоговых узлов в дереве: `3`
- Общих строк по документным узлам: `10141`
- Суммарных строк внутри каталоговых узлов: `2241`
- Всех связей в дереве: `151`
- Просканированных markdown-ссылок: `170`
- Прямых дочерних ссылок у корня: `45`
- Документов с признаком `ROOT-INFLUENCE`: `19`
- Каталоговых узлов без индексного документа: `0`

## Граф
```mermaid
graph TD
    N1["CHANGELOG.md\n15 строк"]
    N2["README.md\n179 строк"]
    N3["RELEASE_CHECKLIST.md\n31 строк"]
    N4["SECURITY.md\n15 строк"]
    N5["docs/ARCHITECTURE.md\n95 строк"]
    N6["docs/INTEGRATION.md\n48 строк\nROOT-INFLUENCE"]
    N7["docs/README.md\n103 строк\nROOT-INFLUENCE"]
    N8["docs/api/openapi.yaml\n82 строк"]
    N9["docs/contracts/v2/openapi.yaml\n199 строк"]
    N10["docs/contracts/v2/schemas/\nкаталог: 16 файлов\n1073 строк"]
    N11["docs/contracts/v2/schemas/README.md\n29 строк"]
    N12["docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md\n183 строк"]
    N13["docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md\n174 строк"]
    N14["docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md\n886 строк\nROOT-INFLUENCE"]
    N15["docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md\n537 строк"]
    N16["docs/foundation/frontier_tech_radar.md\n46 строк"]
    N17["docs/foundation/lens_audit_report.md\n410 строк"]
    N18["docs/foundation/revolutionary_hypotheses.md\n173 строк"]
    N19["docs/governance/evidence/\nкаталог: 44 файлов\n1056 строк"]
    N20["docs/governance/evidence/README.md\n15 строк"]
    N21["docs/governance/evidence/evidence_ledger.yaml\n265 строк"]
    N22["docs/governance/evidence_policy.md\n29 строк"]
    N23["docs/governance/observability_gap_registry.md\n72 строк"]
    N24["docs/governance/release_decisions/\nкаталог: 2 файлов\n112 строк"]
    N25["docs/governance/release_decisions/README.md\n23 строк"]
    N26["docs/governance/release_decisions/latest_go_no_go.md\n89 строк"]
    N27["docs/ops/github_actions_queue_remediation_plan.md\n212 строк"]
    N28["docs/ops/go_no_go_template.md\n133 строк"]
    N29["docs/ops/platform-container-k8s-testing.md\n68 строк"]
    N30["docs/ops/platform-runtime-compatibility-matrix.md\n43 строк"]
    N31["docs/ops/platform-support.md\n98 строк\nROOT-INFLUENCE"]
    N32["docs/ops/platform-vm-testing.md\n54 строк"]
    N33["docs/portal/ART_VISUAL_LANGUAGE.md\n119 строк"]
    N34["docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md\n13 строк"]
    N35["docs/portal/DELIVERY_EVIDENCE.md\n26 строк"]
    N36["docs/portal/DOC_AUTHORITY.md\n19 строк"]
    N37["docs/portal/DOC_STYLE_GUIDE.md\n22 строк"]
    N38["docs/portal/GLOSSARY.md\n14 строк"]
    N39["docs/portal/INDEX.md\n65 строк"]
    N40["docs/portal/PRODUCT_GUARANTEES.md\n14 строк"]
    N41["docs/portal/SECURITY_POSTURE.md\n67 строк"]
    N42["docs/regart/art_bridge_runbook.md\n19 строк"]
    N43["docs/regart/upstream_error_format.md\n29 строк"]
    N44["docs/release/compat_matrix.md\n40 строк"]
    N45["docs/release/release_process.md\n44 строк\nROOT-INFLUENCE"]
    N46["docs/release/versioning.md\n35 строк"]
    N47["docs/runbooks/browser_surface_policy_degraded.md\n36 строк"]
    N48["docs/runbooks/ddos_suspected.md\n40 строк"]
    N49["docs/runbooks/ingress_shield_degraded.md\n41 строк"]
    N50["docs/runbooks/trust_boundary_violation.md\n36 строк"]
    N51["docs/security/fstec-certified-profile.md\n30 строк"]
    N52["docs/source/Art_v1_spec_final.md\n614 строк\nROOT-INFLUENCE"]
    N53["docs/source/FOUNDATION_CONSTITUTION_V0_2.md\n739 строк\nROOT-INFLUENCE"]
    N54["docs/source/README.md\n77 строк\nROOT-INFLUENCE"]
    N55["docs/source/REGART -  LangGraph  взаимодействие с Art описание.md\n313 строк\nROOT-INFLUENCE"]
    N56["docs/source/browser_surface_hardening_v0_2.md\n104 строк\nROOT-INFLUENCE"]
    N57["docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md\n310 строк\nROOT-INFLUENCE"]
    N58["docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md\n124 строк"]
    N59["docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md\n125 строк"]
    N60["docs/source/checklists/CHECKLIST_20_PACK_REGART.md\n125 строк"]
    N61["docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md\n181 строк"]
    N62["docs/source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md\n163 строк"]
    N63["docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md\n125 строк"]
    N64["docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md\n78 строк\nROOT-INFLUENCE"]
    N65["docs/source/checklists/README.md\n89 строк"]
    N66["docs/source/dna_core_determinism_performance_assurance.md\n138 строк\nROOT-INFLUENCE"]
    N67["docs/source/ingress_perimeter_protection_v0_2.md\n149 строк"]
    N68["docs/source/risk_register_v0_2.md\n45 строк\nROOT-INFLUENCE"]
    N69["docs/source/secure_actions_protocol_v2.md\n27 строк"]
    N70["docs/source/trust_boundary_hardening_v0_2.md\n131 строк\nROOT-INFLUENCE"]
    N71["docs/testing/buyer_due_diligence_signal_triage_v0_2.md\n66 строк"]
    N72["docs/testing/defect_remediation_control_matrix_v0_2.md\n565 строк\nROOT-INFLUENCE"]
    N73["docs/testing/defect_remediation_ladder_v0_2.md\n285 строк\nROOT-INFLUENCE"]
    N74["docs/testing/production_adversarial_validation_law.md\n203 строк"]
    N75["docs/testing/test_system_audit_v0_2.md\n97 строк"]
    N76["formats/platform_support.yaml\n253 строк"]
    N2 --> N26
    N2 --> N3
    N2 --> N1
    N2 --> N35
    N2 --> N72
    N2 --> N73
    N2 --> N67
    N2 --> N70
    N2 --> N56
    N2 --> N71
    N2 --> N52
    N2 --> N53
    N2 --> N57
    N2 --> N64
    N2 --> N68
    N2 --> N66
    N2 --> N7
    N2 --> N8
    N2 --> N9
    N2 --> N10
    N2 --> N76
    N2 --> N31
    N2 --> N30
    N2 --> N32
    N2 --> N29
    N2 --> N51
    N2 --> N45
    N2 --> N46
    N2 --> N44
    N2 --> N28
    N2 --> N21
    N2 --> N19
    N2 --> N14
    N2 --> N13
    N2 --> N12
    N2 --> N33
    N2 --> N39
    N2 --> N54
    N2 --> N65
    N2 --> N6
    N2 --> N4
    N2 --> N48
    N2 --> N49
    N2 --> N50
    N2 --> N47
    N5 --> N52
    N5 --> N53
    N5 --> N15
    N5 --> N57
    N5 --> N55
    N5 --> N72
    N5 --> N73
    N5 --> N6
    N6 --> N55
    N6 --> N52
    N6 --> N58
    N6 --> N59
    N6 --> N60
    N6 --> N73
    N6 --> N42
    N6 --> N43
    N7 --> N52
    N7 --> N53
    N7 --> N57
    N7 --> N54
    N7 --> N2
    N7 --> N39
    N7 --> N13
    N7 --> N12
    N7 --> N14
    N7 --> N15
    N7 --> N18
    N7 --> N16
    N7 --> N17
    N7 --> N5
    N7 --> N6
    N7 --> N40
    N7 --> N41
    N7 --> N31
    N7 --> N30
    N7 --> N32
    N7 --> N29
    N7 --> N28
    N7 --> N27
    N7 --> N45
    N7 --> N46
    N7 --> N44
    N7 --> N35
    N7 --> N70
    N7 --> N56
    N7 --> N22
    N7 --> N23
    N7 --> N21
    N7 --> N24
    N7 --> N65
    N7 --> N68
    N7 --> N66
    N7 --> N67
    N7 --> N74
    N7 --> N75
    N10 --> N11
    N11 --> N9
    N11 --> N53
    N11 --> N52
    N11 --> N61
    N11 --> N62
    N11 --> N63
    N15 --> N53
    N15 --> N14
    N15 --> N52
    N15 --> N57
    N19 --> N20
    N24 --> N25
    N39 --> N7
    N39 --> N53
    N39 --> N57
    N39 --> N6
    N39 --> N14
    N39 --> N13
    N39 --> N12
    N39 --> N18
    N39 --> N16
    N39 --> N52
    N39 --> N55
    N39 --> N73
    N39 --> N5
    N39 --> N38
    N39 --> N40
    N39 --> N31
    N39 --> N32
    N39 --> N29
    N39 --> N28
    N39 --> N27
    N39 --> N33
    N39 --> N35
    N39 --> N71
    N39 --> N41
    N39 --> N67
    N39 --> N70
    N39 --> N56
    N39 --> N34
    N39 --> N36
    N39 --> N37
    N39 --> N8
    N39 --> N9
    N39 --> N69
    N39 --> N42
    N44 --> N46
    N44 --> N45
    N44 --> N31
    N44 --> N30
```

## Дерево ссылок
- [`README.md`](../../../README.md) — `179` строк
  - [`docs/governance/release_decisions/latest_go_no_go.md`](../../governance/release_decisions/latest_go_no_go.md) — `89` строк
  - [`RELEASE_CHECKLIST.md`](../../../RELEASE_CHECKLIST.md) — `31` строк
  - [`CHANGELOG.md`](../../../CHANGELOG.md) — `15` строк
  - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
  - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `565` строк `ROOT-INFLUENCE`
  - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
  - [`docs/source/ingress_perimeter_protection_v0_2.md`](../../source/ingress_perimeter_protection_v0_2.md) — `149` строк
  - [`docs/source/trust_boundary_hardening_v0_2.md`](../../source/trust_boundary_hardening_v0_2.md) — `131` строк `ROOT-INFLUENCE`
  - [`docs/source/browser_surface_hardening_v0_2.md`](../../source/browser_surface_hardening_v0_2.md) — `104` строк `ROOT-INFLUENCE`
  - [`docs/testing/buyer_due_diligence_signal_triage_v0_2.md`](../../testing/buyer_due_diligence_signal_triage_v0_2.md) — `66` строк
  - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
  - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`](../../source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md) — `78` строк `ROOT-INFLUENCE`
  - [`docs/source/risk_register_v0_2.md`](../../source/risk_register_v0_2.md) — `45` строк `ROOT-INFLUENCE`
  - [`docs/source/dna_core_determinism_performance_assurance.md`](../../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
  - [`docs/README.md`](../../README.md) — `103` строк `ROOT-INFLUENCE`
    - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
    - [`docs/source/README.md`](../../source/README.md) — `77` строк `ROOT-INFLUENCE`
    - [`README.md`](../../../README.md) — `179` строк `REUSED-LINK`
    - [`docs/portal/INDEX.md`](../../portal/INDEX.md) — `65` строк
      - [`docs/README.md`](../../README.md) — `103` строк `ROOT-INFLUENCE` `REUSED-LINK`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
      - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
      - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
      - [`docs/foundation/revolutionary_hypotheses.md`](../../foundation/revolutionary_hypotheses.md) — `173` строк
      - [`docs/foundation/frontier_tech_radar.md`](../../foundation/frontier_tech_radar.md) — `46` строк
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
      - [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) — `95` строк
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
        - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
          - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
          - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `565` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
        - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
          - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
          - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
          - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
          - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
          - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
          - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
      - [`docs/portal/GLOSSARY.md`](../../portal/GLOSSARY.md) — `14` строк
      - [`docs/portal/PRODUCT_GUARANTEES.md`](../../portal/PRODUCT_GUARANTEES.md) — `14` строк
      - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
      - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
      - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `133` строк
      - [`docs/ops/github_actions_queue_remediation_plan.md`](../../ops/github_actions_queue_remediation_plan.md) — `212` строк
      - [`docs/portal/ART_VISUAL_LANGUAGE.md`](../../portal/ART_VISUAL_LANGUAGE.md) — `119` строк
      - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
      - [`docs/testing/buyer_due_diligence_signal_triage_v0_2.md`](../../testing/buyer_due_diligence_signal_triage_v0_2.md) — `66` строк
      - [`docs/portal/SECURITY_POSTURE.md`](../../portal/SECURITY_POSTURE.md) — `67` строк
      - [`docs/source/ingress_perimeter_protection_v0_2.md`](../../source/ingress_perimeter_protection_v0_2.md) — `149` строк
      - [`docs/source/trust_boundary_hardening_v0_2.md`](../../source/trust_boundary_hardening_v0_2.md) — `131` строк `ROOT-INFLUENCE`
      - [`docs/source/browser_surface_hardening_v0_2.md`](../../source/browser_surface_hardening_v0_2.md) — `104` строк `ROOT-INFLUENCE`
      - [`docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md`](../../portal/COMPATIBILITY_MATRIX_ART_REGART.md) — `13` строк
      - [`docs/portal/DOC_AUTHORITY.md`](../../portal/DOC_AUTHORITY.md) — `19` строк
      - [`docs/portal/DOC_STYLE_GUIDE.md`](../../portal/DOC_STYLE_GUIDE.md) — `22` строк
      - [`docs/api/openapi.yaml`](../../api/openapi.yaml) — `82` строк
      - [`docs/contracts/v2/openapi.yaml`](../../contracts/v2/openapi.yaml) — `199` строк
      - [`docs/source/secure_actions_protocol_v2.md`](../../source/secure_actions_protocol_v2.md) — `27` строк
      - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
    - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
    - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
    - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
    - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
    - [`docs/foundation/revolutionary_hypotheses.md`](../../foundation/revolutionary_hypotheses.md) — `173` строк
    - [`docs/foundation/frontier_tech_radar.md`](../../foundation/frontier_tech_radar.md) — `46` строк
    - [`docs/foundation/lens_audit_report.md`](../../foundation/lens_audit_report.md) — `410` строк
    - [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) — `95` строк
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `565` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
    - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
      - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
      - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
      - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
      - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
    - [`docs/portal/PRODUCT_GUARANTEES.md`](../../portal/PRODUCT_GUARANTEES.md) — `14` строк
    - [`docs/portal/SECURITY_POSTURE.md`](../../portal/SECURITY_POSTURE.md) — `67` строк
    - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
    - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
    - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
    - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `133` строк
    - [`docs/ops/github_actions_queue_remediation_plan.md`](../../ops/github_actions_queue_remediation_plan.md) — `212` строк
    - [`docs/release/release_process.md`](../../release/release_process.md) — `44` строк `ROOT-INFLUENCE`
    - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
    - [`docs/release/compat_matrix.md`](../../release/compat_matrix.md) — `40` строк
      - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
      - [`docs/release/release_process.md`](../../release/release_process.md) — `44` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
    - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
    - [`docs/source/trust_boundary_hardening_v0_2.md`](../../source/trust_boundary_hardening_v0_2.md) — `131` строк `ROOT-INFLUENCE`
    - [`docs/source/browser_surface_hardening_v0_2.md`](../../source/browser_surface_hardening_v0_2.md) — `104` строк `ROOT-INFLUENCE`
    - [`docs/governance/evidence_policy.md`](../../governance/evidence_policy.md) — `29` строк
    - [`docs/governance/observability_gap_registry.md`](../../governance/observability_gap_registry.md) — `72` строк
    - [`docs/governance/evidence/evidence_ledger.yaml`](../../governance/evidence/evidence_ledger.yaml) — `265` строк
    - [`docs/governance/release_decisions/`](../../governance/release_decisions/README.md) — `каталог`, файлов `2`, строк `112`
      - [`docs/governance/release_decisions/README.md`](../../governance/release_decisions/README.md) — `23` строк
    - [`docs/source/checklists/README.md`](../../source/checklists/README.md) — `89` строк
    - [`docs/source/risk_register_v0_2.md`](../../source/risk_register_v0_2.md) — `45` строк `ROOT-INFLUENCE`
    - [`docs/source/dna_core_determinism_performance_assurance.md`](../../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
    - [`docs/source/ingress_perimeter_protection_v0_2.md`](../../source/ingress_perimeter_protection_v0_2.md) — `149` строк
    - [`docs/testing/production_adversarial_validation_law.md`](../../testing/production_adversarial_validation_law.md) — `203` строк
    - [`docs/testing/test_system_audit_v0_2.md`](../../testing/test_system_audit_v0_2.md) — `97` строк
  - [`docs/api/openapi.yaml`](../../api/openapi.yaml) — `82` строк
  - [`docs/contracts/v2/openapi.yaml`](../../contracts/v2/openapi.yaml) — `199` строк
  - [`docs/contracts/v2/schemas/`](../../contracts/v2/schemas/README.md) — `каталог`, файлов `16`, строк `1073`
    - [`docs/contracts/v2/schemas/README.md`](../../contracts/v2/schemas/README.md) — `29` строк
      - [`docs/contracts/v2/openapi.yaml`](../../contracts/v2/openapi.yaml) — `199` строк
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`](../../source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md) — `181` строк
      - [`docs/source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md`](../../source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md) — `163` строк
      - [`docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`](../../source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md) — `125` строк
  - [`formats/platform_support.yaml`](../../../formats/platform_support.yaml) — `253` строк
  - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
  - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
  - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
  - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
  - [`docs/security/fstec-certified-profile.md`](../../security/fstec-certified-profile.md) — `30` строк
  - [`docs/release/release_process.md`](../../release/release_process.md) — `44` строк `ROOT-INFLUENCE`
  - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
  - [`docs/release/compat_matrix.md`](../../release/compat_matrix.md) — `40` строк
    - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
    - [`docs/release/release_process.md`](../../release/release_process.md) — `44` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
  - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `133` строк
  - [`docs/governance/evidence/evidence_ledger.yaml`](../../governance/evidence/evidence_ledger.yaml) — `265` строк
  - [`docs/governance/evidence/`](../../governance/evidence/README.md) — `каталог`, файлов `44`, строк `1056`
    - [`docs/governance/evidence/README.md`](../../governance/evidence/README.md) — `15` строк
  - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
  - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
  - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
  - [`docs/portal/ART_VISUAL_LANGUAGE.md`](../../portal/ART_VISUAL_LANGUAGE.md) — `119` строк
  - [`docs/portal/INDEX.md`](../../portal/INDEX.md) — `65` строк
    - [`docs/README.md`](../../README.md) — `103` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
      - [`docs/source/README.md`](../../source/README.md) — `77` строк `ROOT-INFLUENCE`
      - [`README.md`](../../../README.md) — `179` строк `REUSED-LINK`
      - [`docs/portal/INDEX.md`](../../portal/INDEX.md) — `65` строк `REUSED-LINK`
      - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
      - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
      - [`docs/foundation/revolutionary_hypotheses.md`](../../foundation/revolutionary_hypotheses.md) — `173` строк
      - [`docs/foundation/frontier_tech_radar.md`](../../foundation/frontier_tech_radar.md) — `46` строк
      - [`docs/foundation/lens_audit_report.md`](../../foundation/lens_audit_report.md) — `410` строк
      - [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) — `95` строк
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
        - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
          - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
          - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `565` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
        - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
          - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
          - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
          - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
          - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
          - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
          - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
      - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
      - [`docs/portal/PRODUCT_GUARANTEES.md`](../../portal/PRODUCT_GUARANTEES.md) — `14` строк
      - [`docs/portal/SECURITY_POSTURE.md`](../../portal/SECURITY_POSTURE.md) — `67` строк
      - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
      - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
      - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
      - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `133` строк
      - [`docs/ops/github_actions_queue_remediation_plan.md`](../../ops/github_actions_queue_remediation_plan.md) — `212` строк
      - [`docs/release/release_process.md`](../../release/release_process.md) — `44` строк `ROOT-INFLUENCE`
      - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
      - [`docs/release/compat_matrix.md`](../../release/compat_matrix.md) — `40` строк
        - [`docs/release/versioning.md`](../../release/versioning.md) — `35` строк
        - [`docs/release/release_process.md`](../../release/release_process.md) — `44` строк `ROOT-INFLUENCE`
        - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
        - [`docs/ops/platform-runtime-compatibility-matrix.md`](../../ops/platform-runtime-compatibility-matrix.md) — `43` строк
      - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
      - [`docs/source/trust_boundary_hardening_v0_2.md`](../../source/trust_boundary_hardening_v0_2.md) — `131` строк `ROOT-INFLUENCE`
      - [`docs/source/browser_surface_hardening_v0_2.md`](../../source/browser_surface_hardening_v0_2.md) — `104` строк `ROOT-INFLUENCE`
      - [`docs/governance/evidence_policy.md`](../../governance/evidence_policy.md) — `29` строк
      - [`docs/governance/observability_gap_registry.md`](../../governance/observability_gap_registry.md) — `72` строк
      - [`docs/governance/evidence/evidence_ledger.yaml`](../../governance/evidence/evidence_ledger.yaml) — `265` строк
      - [`docs/governance/release_decisions/`](../../governance/release_decisions/README.md) — `каталог`, файлов `2`, строк `112`
        - [`docs/governance/release_decisions/README.md`](../../governance/release_decisions/README.md) — `23` строк
      - [`docs/source/checklists/README.md`](../../source/checklists/README.md) — `89` строк
      - [`docs/source/risk_register_v0_2.md`](../../source/risk_register_v0_2.md) — `45` строк `ROOT-INFLUENCE`
      - [`docs/source/dna_core_determinism_performance_assurance.md`](../../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
      - [`docs/source/ingress_perimeter_protection_v0_2.md`](../../source/ingress_perimeter_protection_v0_2.md) — `149` строк
      - [`docs/testing/production_adversarial_validation_law.md`](../../testing/production_adversarial_validation_law.md) — `203` строк
      - [`docs/testing/test_system_audit_v0_2.md`](../../testing/test_system_audit_v0_2.md) — `97` строк
    - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
    - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
      - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
      - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
      - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
      - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
    - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
    - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
    - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
    - [`docs/foundation/revolutionary_hypotheses.md`](../../foundation/revolutionary_hypotheses.md) — `173` строк
    - [`docs/foundation/frontier_tech_radar.md`](../../foundation/frontier_tech_radar.md) — `46` строк
    - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
    - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
    - [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md) — `95` строк
      - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `537` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `565` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
    - [`docs/portal/GLOSSARY.md`](../../portal/GLOSSARY.md) — `14` строк
    - [`docs/portal/PRODUCT_GUARANTEES.md`](../../portal/PRODUCT_GUARANTEES.md) — `14` строк
    - [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-vm-testing.md`](../../ops/platform-vm-testing.md) — `54` строк
    - [`docs/ops/platform-container-k8s-testing.md`](../../ops/platform-container-k8s-testing.md) — `68` строк
    - [`docs/ops/go_no_go_template.md`](../../ops/go_no_go_template.md) — `133` строк
    - [`docs/ops/github_actions_queue_remediation_plan.md`](../../ops/github_actions_queue_remediation_plan.md) — `212` строк
    - [`docs/portal/ART_VISUAL_LANGUAGE.md`](../../portal/ART_VISUAL_LANGUAGE.md) — `119` строк
    - [`docs/portal/DELIVERY_EVIDENCE.md`](../../portal/DELIVERY_EVIDENCE.md) — `26` строк
    - [`docs/testing/buyer_due_diligence_signal_triage_v0_2.md`](../../testing/buyer_due_diligence_signal_triage_v0_2.md) — `66` строк
    - [`docs/portal/SECURITY_POSTURE.md`](../../portal/SECURITY_POSTURE.md) — `67` строк
    - [`docs/source/ingress_perimeter_protection_v0_2.md`](../../source/ingress_perimeter_protection_v0_2.md) — `149` строк
    - [`docs/source/trust_boundary_hardening_v0_2.md`](../../source/trust_boundary_hardening_v0_2.md) — `131` строк `ROOT-INFLUENCE`
    - [`docs/source/browser_surface_hardening_v0_2.md`](../../source/browser_surface_hardening_v0_2.md) — `104` строк `ROOT-INFLUENCE`
    - [`docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md`](../../portal/COMPATIBILITY_MATRIX_ART_REGART.md) — `13` строк
    - [`docs/portal/DOC_AUTHORITY.md`](../../portal/DOC_AUTHORITY.md) — `19` строк
    - [`docs/portal/DOC_STYLE_GUIDE.md`](../../portal/DOC_STYLE_GUIDE.md) — `22` строк
    - [`docs/api/openapi.yaml`](../../api/openapi.yaml) — `82` строк
    - [`docs/contracts/v2/openapi.yaml`](../../contracts/v2/openapi.yaml) — `199` строк
    - [`docs/source/secure_actions_protocol_v2.md`](../../source/secure_actions_protocol_v2.md) — `27` строк
    - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
  - [`docs/source/README.md`](../../source/README.md) — `77` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/README.md`](../../source/checklists/README.md) — `89` строк
  - [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк `ROOT-INFLUENCE`
    - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
    - [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `124` строк
    - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `125` строк
    - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../../source/checklists/CHECKLIST_20_PACK_REGART.md) — `125` строк
    - [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк `ROOT-INFLUENCE`
    - [`docs/regart/art_bridge_runbook.md`](../../regart/art_bridge_runbook.md) — `19` строк
    - [`docs/regart/upstream_error_format.md`](../../regart/upstream_error_format.md) — `29` строк
  - [`SECURITY.md`](../../../SECURITY.md) — `15` строк
  - [`docs/runbooks/ddos_suspected.md`](../../runbooks/ddos_suspected.md) — `40` строк
  - [`docs/runbooks/ingress_shield_degraded.md`](../../runbooks/ingress_shield_degraded.md) — `41` строк
  - [`docs/runbooks/trust_boundary_violation.md`](../../runbooks/trust_boundary_violation.md) — `36` строк
  - [`docs/runbooks/browser_surface_policy_degraded.md`](../../runbooks/browser_surface_policy_degraded.md) — `36` строк

## Документы, влияющие на корневой README
Если изменяется любой документ из этого списка, а `README.md` не изменён, CI подаёт сигнал о рассинхроне.

- [`docs/INTEGRATION.md`](../../INTEGRATION.md) — `48` строк
- [`docs/README.md`](../../README.md) — `103` строк
- [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `886` строк
- [`docs/ops/platform-support.md`](../../ops/platform-support.md) — `98` строк
- [`docs/release/release_process.md`](../../release/release_process.md) — `44` строк
- [`docs/source/Art_v1_spec_final.md`](../../source/Art_v1_spec_final.md) — `614` строк
- [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../../source/FOUNDATION_CONSTITUTION_V0_2.md) — `739` строк
- [`docs/source/README.md`](../../source/README.md) — `77` строк
- [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк
- [`docs/source/browser_surface_hardening_v0_2.md`](../../source/browser_surface_hardening_v0_2.md) — `104` строк
- [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `310` строк
- [`docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`](../../source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md) — `78` строк
- `docs/source/checklists/TRACEABILITY_V0_2.md` — `НЕ ПОПАЛ В ДЕРЕВО`
- [`docs/source/dna_core_determinism_performance_assurance.md`](../../source/dna_core_determinism_performance_assurance.md) — `138` строк
- [`docs/source/risk_register_v0_2.md`](../../source/risk_register_v0_2.md) — `45` строк
- [`docs/source/trust_boundary_hardening_v0_2.md`](../../source/trust_boundary_hardening_v0_2.md) — `131` строк
- [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../../testing/defect_remediation_control_matrix_v0_2.md) — `565` строк
- [`docs/testing/defect_remediation_ladder_v0_2.md`](../../testing/defect_remediation_ladder_v0_2.md) — `285` строк
- `formats/defect_remediation_control_matrix_v0_2.yaml` — `НЕ ПОПАЛ В ДЕРЕВО`

## Каталоговые узлы
Это специальные узлы дерева для ссылок на каталоги. Они считаются автоматически и показывают:
- сколько файлов внутри;
- сколько строк внутри;
- есть ли индексный документ, на который можно безопасно сослаться.

- [`docs/contracts/v2/schemas/`](../../contracts/v2/schemas/README.md) — файлов `16`, строк `1073`
- [`docs/governance/evidence/`](../../governance/evidence/README.md) — файлов `44`, строк `1056`
- [`docs/governance/release_decisions/`](../../governance/release_decisions/README.md) — файлов `2`, строк `112`

## Каталоговые узлы без индексного документа
Если здесь появляется запись, дерево считается дефектным: каталог есть в ссылках, но не имеет реального индексного документа.

- нет

## Missing targets
Если здесь появится запись, значит в документации есть ссылка на файл, который не найден.

- нет

## Статус
- Статус дерева: `ACTIVE`
- Корень документационного дерева: `README.md`
- Контроль рассинхрона: `ENABLED`
