# Графическое дерево документации Art

## Source of truth
- [`../../README.md`](../../README.md)
- [`../../formats/documentation_tree_rules_v0_2.yaml`](../../formats/documentation_tree_rules_v0_2.yaml)
- [`../../formats/documentation_tree_v0_2.yaml`](../../formats/documentation_tree_v0_2.yaml)
- [`../../scripts/ci/generate_documentation_tree.py`](../../scripts/ci/generate_documentation_tree.py)
- [`../../scripts/ci/check_documentation_tree_sync.sh`](../../scripts/ci/check_documentation_tree_sync.sh)

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
- Корень дерева: [`../../README.md`](../../README.md)
- Строк в корневом `README.md`: `198`
- Уникальных документов в дереве: `81`
- Каталоговых узлов в дереве: `3`
- Общих строк по документным узлам: `12548`
- Суммарных строк внутри каталоговых узлов: `2243`
- Всех связей в дереве: `177`
- Просканированных markdown-ссылок: `214`
- Прямых дочерних ссылок у корня: `53`
- Документов с признаком `ROOT-INFLUENCE`: `27`
- Каталоговых узлов без индексного документа: `0`

## Граф
```mermaid
graph TD
    N1["CHANGELOG.md\n15 строк"]
    N2["README.md\n198 строк"]
    N3["RELEASE_CHECKLIST.md\n33 строк"]
    N4["SECURITY.md\n15 строк"]
    N5["docs/ARCHITECTURE.md\n99 строк"]
    N6["docs/INTEGRATION.md\n67 строк\nROOT-INFLUENCE"]
    N7["docs/README.md\n136 строк\nROOT-INFLUENCE"]
    N8["docs/api/openapi.yaml\n82 строк"]
    N9["docs/contracts/v2/openapi.yaml\n199 строк"]
    N10["docs/contracts/v2/schemas/\nкаталог: 16 файлов\n1073 строк"]
    N11["docs/contracts/v2/schemas/README.md\n29 строк"]
    N12["docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md\n183 строк"]
    N13["docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md\n174 строк"]
    N14["docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md\n1493 строк\nROOT-INFLUENCE"]
    N15["docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md\n579 строк"]
    N16["docs/foundation/frontier_tech_radar.md\n46 строк"]
    N17["docs/foundation/lens_audit_report.md\n410 строк"]
    N18["docs/foundation/revolutionary_hypotheses.md\n173 строк"]
    N19["docs/governance/evidence/\nкаталог: 44 файлов\n1056 строк"]
    N20["docs/governance/evidence/README.md\n15 строк"]
    N21["docs/governance/evidence/evidence_ledger.yaml\n265 строк"]
    N22["docs/governance/evidence_policy.md\n29 строк"]
    N23["docs/governance/observability_gap_registry.md\n87 строк"]
    N24["docs/governance/release_decisions/\nкаталог: 2 файлов\n114 строк"]
    N25["docs/governance/release_decisions/README.md\n23 строк"]
    N26["docs/governance/release_decisions/latest_go_no_go.md\n91 строк"]
    N27["docs/ops/github_actions_queue_remediation_plan.md\n212 строк"]
    N28["docs/ops/go_no_go_template.md\n137 строк"]
    N29["docs/ops/platform-container-k8s-testing.md\n68 строк"]
    N30["docs/ops/platform-runtime-compatibility-matrix.md\n43 строк"]
    N31["docs/ops/platform-support.md\n98 строк\nROOT-INFLUENCE"]
    N32["docs/ops/platform-vm-testing.md\n54 строк"]
    N33["docs/portal/ART_VISUAL_LANGUAGE.md\n119 строк"]
    N34["docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md\n13 строк"]
    N35["docs/portal/DELIVERY_EVIDENCE.md\n26 строк"]
    N36["docs/portal/DOC_AUTHORITY.md\n19 строк"]
    N37["docs/portal/DOC_STYLE_GUIDE.md\n41 строк"]
    N38["docs/portal/GLOSSARY.md\n14 строк"]
    N39["docs/portal/INDEX.md\n75 строк"]
    N40["docs/portal/PRODUCT_GUARANTEES.md\n14 строк"]
    N41["docs/portal/SECURITY_POSTURE.md\n107 строк"]
    N42["docs/regart/art_bridge_runbook.md\n19 строк"]
    N43["docs/regart/upstream_error_format.md\n29 строк"]
    N44["docs/release/compat_matrix.md\n40 строк"]
    N45["docs/release/release_process.md\n50 строк\nROOT-INFLUENCE"]
    N46["docs/release/versioning.md\n35 строк"]
    N47["docs/runbooks/browser_surface_policy_degraded.md\n36 строк"]
    N48["docs/runbooks/ddos_suspected.md\n40 строк"]
    N49["docs/runbooks/ingress_shield_degraded.md\n41 строк"]
    N50["docs/runbooks/trust_boundary_violation.md\n36 строк"]
    N51["docs/security/fstec-certified-profile.md\n30 строк"]
    N52["docs/source/Art_v1_spec_final.md\n614 строк\nROOT-INFLUENCE"]
    N53["docs/source/FOUNDATION_CONSTITUTION_V0_2.md\n903 строк\nROOT-INFLUENCE"]
    N54["docs/source/README.md\n105 строк\nROOT-INFLUENCE"]
    N55["docs/source/REGART -  LangGraph  взаимодействие с Art описание.md\n313 строк\nROOT-INFLUENCE"]
    N56["docs/source/browser_surface_hardening_v0_2.md\n107 строк\nROOT-INFLUENCE"]
    N57["docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md\n332 строк\nROOT-INFLUENCE"]
    N58["docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md\n134 строк"]
    N59["docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md\n140 строк"]
    N60["docs/source/checklists/CHECKLIST_20_PACK_REGART.md\n140 строк"]
    N61["docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md\n199 строк"]
    N62["docs/source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md\n163 строк"]
    N63["docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md\n125 строк"]
    N64["docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md\n93 строк\nROOT-INFLUENCE"]
    N65["docs/source/checklists/README.md\n89 строк"]
    N66["docs/source/connected_system_visibility_v0_2.md\n193 строк\nROOT-INFLUENCE"]
    N67["docs/source/dna_core_determinism_performance_assurance.md\n138 строк\nROOT-INFLUENCE"]
    N68["docs/source/guard_self_observability_v0_2.md\n36 строк\nROOT-INFLUENCE"]
    N69["docs/source/ingress_perimeter_protection_v0_2.md\n149 строк"]
    N70["docs/source/monolith_budget_guard_v0_2.md\n89 строк"]
    N71["docs/source/protective_safeguards_catalog_v0_2.md\n181 строк\nROOT-INFLUENCE"]
    N72["docs/source/queue_integrity_protection_v0_2.md\n44 строк\nROOT-INFLUENCE"]
    N73["docs/source/regart_adversarial_integration_harness_v0_2.md\n174 строк\nROOT-INFLUENCE"]
    N74["docs/source/risk_register_v0_2.md\n59 строк\nROOT-INFLUENCE"]
    N75["docs/source/secure_actions_protocol_v2.md\n27 строк"]
    N76["docs/source/startup_config_safety_validator_v0_2.md\n39 строк\nROOT-INFLUENCE"]
    N77["docs/source/storage_pressure_protection_v0_2.md\n119 строк\nROOT-INFLUENCE"]
    N78["docs/source/trust_boundary_hardening_v0_2.md\n134 строк\nROOT-INFLUENCE"]
    N79["docs/testing/buyer_due_diligence_signal_triage_v0_2.md\n66 строк"]
    N80["docs/testing/defect_remediation_control_matrix_v0_2.md\n948 строк\nROOT-INFLUENCE"]
    N81["docs/testing/defect_remediation_ladder_v0_2.md\n305 строк\nROOT-INFLUENCE"]
    N82["docs/testing/production_adversarial_validation_law.md\n203 строк"]
    N83["docs/testing/test_system_audit_v0_2.md\n97 строк"]
    N84["formats/platform_support.yaml\n253 строк"]
    N2 --> N26
    N2 --> N3
    N2 --> N1
    N2 --> N35
    N2 --> N80
    N2 --> N81
    N2 --> N69
    N2 --> N78
    N2 --> N56
    N2 --> N77
    N2 --> N76
    N2 --> N72
    N2 --> N68
    N2 --> N70
    N2 --> N73
    N2 --> N66
    N2 --> N79
    N2 --> N52
    N2 --> N53
    N2 --> N57
    N2 --> N64
    N2 --> N74
    N2 --> N67
    N2 --> N71
    N2 --> N7
    N2 --> N8
    N2 --> N9
    N2 --> N10
    N2 --> N84
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
    N5 --> N80
    N5 --> N81
    N5 --> N6
    N6 --> N55
    N6 --> N52
    N6 --> N58
    N6 --> N59
    N6 --> N60
    N6 --> N73
    N6 --> N81
    N6 --> N42
    N6 --> N43
    N6 --> N80
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
    N7 --> N73
    N7 --> N66
    N7 --> N40
    N7 --> N41
    N7 --> N31
    N7 --> N30
    N7 --> N32
    N7 --> N29
    N7 --> N28
    N7 --> N27
    N7 --> N77
    N7 --> N76
    N7 --> N72
    N7 --> N68
    N7 --> N45
    N7 --> N46
    N7 --> N44
    N7 --> N35
    N7 --> N78
    N7 --> N56
    N7 --> N71
    N7 --> N22
    N7 --> N23
    N7 --> N21
    N7 --> N24
    N7 --> N65
    N7 --> N74
    N7 --> N67
    N7 --> N69
    N7 --> N82
    N7 --> N83
    N7 --> N80
    N7 --> N81
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
    N39 --> N81
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
    N39 --> N79
    N39 --> N41
    N39 --> N71
    N39 --> N69
    N39 --> N78
    N39 --> N56
    N39 --> N77
    N39 --> N76
    N39 --> N72
    N39 --> N68
    N39 --> N73
    N39 --> N66
    N39 --> N34
    N39 --> N36
    N39 --> N37
    N39 --> N8
    N39 --> N9
    N39 --> N75
    N39 --> N42
    N44 --> N46
    N44 --> N45
    N44 --> N31
    N44 --> N30
```

## Дерево ссылок
- [`README.md`](../../README.md) — `198` строк
  - [`docs/governance/release_decisions/latest_go_no_go.md`](../governance/release_decisions/latest_go_no_go.md) — `91` строк
  - [`RELEASE_CHECKLIST.md`](../../RELEASE_CHECKLIST.md) — `33` строк
  - [`CHANGELOG.md`](../../CHANGELOG.md) — `15` строк
  - [`docs/portal/DELIVERY_EVIDENCE.md`](DELIVERY_EVIDENCE.md) — `26` строк
  - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
  - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
  - [`docs/source/ingress_perimeter_protection_v0_2.md`](../source/ingress_perimeter_protection_v0_2.md) — `149` строк
  - [`docs/source/trust_boundary_hardening_v0_2.md`](../source/trust_boundary_hardening_v0_2.md) — `134` строк `ROOT-INFLUENCE`
  - [`docs/source/browser_surface_hardening_v0_2.md`](../source/browser_surface_hardening_v0_2.md) — `107` строк `ROOT-INFLUENCE`
  - [`docs/source/storage_pressure_protection_v0_2.md`](../source/storage_pressure_protection_v0_2.md) — `119` строк `ROOT-INFLUENCE`
  - [`docs/source/startup_config_safety_validator_v0_2.md`](../source/startup_config_safety_validator_v0_2.md) — `39` строк `ROOT-INFLUENCE`
  - [`docs/source/queue_integrity_protection_v0_2.md`](../source/queue_integrity_protection_v0_2.md) — `44` строк `ROOT-INFLUENCE`
  - [`docs/source/guard_self_observability_v0_2.md`](../source/guard_self_observability_v0_2.md) — `36` строк `ROOT-INFLUENCE`
  - [`docs/source/monolith_budget_guard_v0_2.md`](../source/monolith_budget_guard_v0_2.md) — `89` строк
  - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
  - [`docs/source/connected_system_visibility_v0_2.md`](../source/connected_system_visibility_v0_2.md) — `193` строк `ROOT-INFLUENCE`
  - [`docs/testing/buyer_due_diligence_signal_triage_v0_2.md`](../testing/buyer_due_diligence_signal_triage_v0_2.md) — `66` строк
  - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
  - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`](../source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md) — `93` строк `ROOT-INFLUENCE`
  - [`docs/source/risk_register_v0_2.md`](../source/risk_register_v0_2.md) — `59` строк `ROOT-INFLUENCE`
  - [`docs/source/dna_core_determinism_performance_assurance.md`](../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
  - [`docs/source/protective_safeguards_catalog_v0_2.md`](../source/protective_safeguards_catalog_v0_2.md) — `181` строк `ROOT-INFLUENCE`
  - [`docs/README.md`](../README.md) — `136` строк `ROOT-INFLUENCE`
    - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
    - [`docs/source/README.md`](../source/README.md) — `105` строк `ROOT-INFLUENCE`
    - [`README.md`](../../README.md) — `198` строк `REUSED-LINK`
    - [`docs/portal/INDEX.md`](INDEX.md) — `75` строк
      - [`docs/README.md`](../README.md) — `136` строк `ROOT-INFLUENCE` `REUSED-LINK`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
        - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
      - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
      - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
      - [`docs/foundation/revolutionary_hypotheses.md`](../foundation/revolutionary_hypotheses.md) — `173` строк
      - [`docs/foundation/frontier_tech_radar.md`](../foundation/frontier_tech_radar.md) — `46` строк
      - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
      - [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) — `99` строк
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
        - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `579` строк
          - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
          - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
        - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
          - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
          - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
          - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
          - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
          - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
          - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
          - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
          - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
      - [`docs/portal/GLOSSARY.md`](GLOSSARY.md) — `14` строк
      - [`docs/portal/PRODUCT_GUARANTEES.md`](PRODUCT_GUARANTEES.md) — `14` строк
      - [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-vm-testing.md`](../ops/platform-vm-testing.md) — `54` строк
      - [`docs/ops/platform-container-k8s-testing.md`](../ops/platform-container-k8s-testing.md) — `68` строк
      - [`docs/ops/go_no_go_template.md`](../ops/go_no_go_template.md) — `137` строк
      - [`docs/ops/github_actions_queue_remediation_plan.md`](../ops/github_actions_queue_remediation_plan.md) — `212` строк
      - [`docs/portal/ART_VISUAL_LANGUAGE.md`](ART_VISUAL_LANGUAGE.md) — `119` строк
      - [`docs/portal/DELIVERY_EVIDENCE.md`](DELIVERY_EVIDENCE.md) — `26` строк
      - [`docs/testing/buyer_due_diligence_signal_triage_v0_2.md`](../testing/buyer_due_diligence_signal_triage_v0_2.md) — `66` строк
      - [`docs/portal/SECURITY_POSTURE.md`](SECURITY_POSTURE.md) — `107` строк
      - [`docs/source/protective_safeguards_catalog_v0_2.md`](../source/protective_safeguards_catalog_v0_2.md) — `181` строк `ROOT-INFLUENCE`
      - [`docs/source/ingress_perimeter_protection_v0_2.md`](../source/ingress_perimeter_protection_v0_2.md) — `149` строк
      - [`docs/source/trust_boundary_hardening_v0_2.md`](../source/trust_boundary_hardening_v0_2.md) — `134` строк `ROOT-INFLUENCE`
      - [`docs/source/browser_surface_hardening_v0_2.md`](../source/browser_surface_hardening_v0_2.md) — `107` строк `ROOT-INFLUENCE`
      - [`docs/source/storage_pressure_protection_v0_2.md`](../source/storage_pressure_protection_v0_2.md) — `119` строк `ROOT-INFLUENCE`
      - [`docs/source/startup_config_safety_validator_v0_2.md`](../source/startup_config_safety_validator_v0_2.md) — `39` строк `ROOT-INFLUENCE`
      - [`docs/source/queue_integrity_protection_v0_2.md`](../source/queue_integrity_protection_v0_2.md) — `44` строк `ROOT-INFLUENCE`
      - [`docs/source/guard_self_observability_v0_2.md`](../source/guard_self_observability_v0_2.md) — `36` строк `ROOT-INFLUENCE`
      - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
      - [`docs/source/connected_system_visibility_v0_2.md`](../source/connected_system_visibility_v0_2.md) — `193` строк `ROOT-INFLUENCE`
      - [`docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md`](COMPATIBILITY_MATRIX_ART_REGART.md) — `13` строк
      - [`docs/portal/DOC_AUTHORITY.md`](DOC_AUTHORITY.md) — `19` строк
      - [`docs/portal/DOC_STYLE_GUIDE.md`](DOC_STYLE_GUIDE.md) — `41` строк
      - [`docs/api/openapi.yaml`](../api/openapi.yaml) — `82` строк
      - [`docs/contracts/v2/openapi.yaml`](../contracts/v2/openapi.yaml) — `199` строк
      - [`docs/source/secure_actions_protocol_v2.md`](../source/secure_actions_protocol_v2.md) — `27` строк
      - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
    - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
    - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
    - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
    - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `579` строк
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
    - [`docs/foundation/revolutionary_hypotheses.md`](../foundation/revolutionary_hypotheses.md) — `173` строк
    - [`docs/foundation/frontier_tech_radar.md`](../foundation/frontier_tech_radar.md) — `46` строк
    - [`docs/foundation/lens_audit_report.md`](../foundation/lens_audit_report.md) — `410` строк
    - [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) — `99` строк
      - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `579` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
        - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
    - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
      - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
      - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
      - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
      - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
      - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
    - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
    - [`docs/source/connected_system_visibility_v0_2.md`](../source/connected_system_visibility_v0_2.md) — `193` строк `ROOT-INFLUENCE`
    - [`docs/portal/PRODUCT_GUARANTEES.md`](PRODUCT_GUARANTEES.md) — `14` строк
    - [`docs/portal/SECURITY_POSTURE.md`](SECURITY_POSTURE.md) — `107` строк
    - [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-runtime-compatibility-matrix.md`](../ops/platform-runtime-compatibility-matrix.md) — `43` строк
    - [`docs/ops/platform-vm-testing.md`](../ops/platform-vm-testing.md) — `54` строк
    - [`docs/ops/platform-container-k8s-testing.md`](../ops/platform-container-k8s-testing.md) — `68` строк
    - [`docs/ops/go_no_go_template.md`](../ops/go_no_go_template.md) — `137` строк
    - [`docs/ops/github_actions_queue_remediation_plan.md`](../ops/github_actions_queue_remediation_plan.md) — `212` строк
    - [`docs/source/storage_pressure_protection_v0_2.md`](../source/storage_pressure_protection_v0_2.md) — `119` строк `ROOT-INFLUENCE`
    - [`docs/source/startup_config_safety_validator_v0_2.md`](../source/startup_config_safety_validator_v0_2.md) — `39` строк `ROOT-INFLUENCE`
    - [`docs/source/queue_integrity_protection_v0_2.md`](../source/queue_integrity_protection_v0_2.md) — `44` строк `ROOT-INFLUENCE`
    - [`docs/source/guard_self_observability_v0_2.md`](../source/guard_self_observability_v0_2.md) — `36` строк `ROOT-INFLUENCE`
    - [`docs/release/release_process.md`](../release/release_process.md) — `50` строк `ROOT-INFLUENCE`
    - [`docs/release/versioning.md`](../release/versioning.md) — `35` строк
    - [`docs/release/compat_matrix.md`](../release/compat_matrix.md) — `40` строк
      - [`docs/release/versioning.md`](../release/versioning.md) — `35` строк
      - [`docs/release/release_process.md`](../release/release_process.md) — `50` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-runtime-compatibility-matrix.md`](../ops/platform-runtime-compatibility-matrix.md) — `43` строк
    - [`docs/portal/DELIVERY_EVIDENCE.md`](DELIVERY_EVIDENCE.md) — `26` строк
    - [`docs/source/trust_boundary_hardening_v0_2.md`](../source/trust_boundary_hardening_v0_2.md) — `134` строк `ROOT-INFLUENCE`
    - [`docs/source/browser_surface_hardening_v0_2.md`](../source/browser_surface_hardening_v0_2.md) — `107` строк `ROOT-INFLUENCE`
    - [`docs/source/protective_safeguards_catalog_v0_2.md`](../source/protective_safeguards_catalog_v0_2.md) — `181` строк `ROOT-INFLUENCE`
    - [`docs/governance/evidence_policy.md`](../governance/evidence_policy.md) — `29` строк
    - [`docs/governance/observability_gap_registry.md`](../governance/observability_gap_registry.md) — `87` строк
    - [`docs/governance/evidence/evidence_ledger.yaml`](../governance/evidence/evidence_ledger.yaml) — `265` строк
    - [`docs/governance/release_decisions/`](../governance/release_decisions/README.md) — `каталог`, файлов `2`, строк `114`
      - [`docs/governance/release_decisions/README.md`](../governance/release_decisions/README.md) — `23` строк
    - [`docs/source/checklists/README.md`](../source/checklists/README.md) — `89` строк
    - [`docs/source/risk_register_v0_2.md`](../source/risk_register_v0_2.md) — `59` строк `ROOT-INFLUENCE`
    - [`docs/source/dna_core_determinism_performance_assurance.md`](../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
    - [`docs/source/ingress_perimeter_protection_v0_2.md`](../source/ingress_perimeter_protection_v0_2.md) — `149` строк
    - [`docs/testing/production_adversarial_validation_law.md`](../testing/production_adversarial_validation_law.md) — `203` строк
    - [`docs/testing/test_system_audit_v0_2.md`](../testing/test_system_audit_v0_2.md) — `97` строк
    - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
    - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
  - [`docs/api/openapi.yaml`](../api/openapi.yaml) — `82` строк
  - [`docs/contracts/v2/openapi.yaml`](../contracts/v2/openapi.yaml) — `199` строк
  - [`docs/contracts/v2/schemas/`](../contracts/v2/schemas/README.md) — `каталог`, файлов `16`, строк `1073`
    - [`docs/contracts/v2/schemas/README.md`](../contracts/v2/schemas/README.md) — `29` строк
      - [`docs/contracts/v2/openapi.yaml`](../contracts/v2/openapi.yaml) — `199` строк
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md`](../source/checklists/CHECKLIST_28_CONSOLE_FOUNDATION_MONOREPO.md) — `199` строк
      - [`docs/source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md`](../source/checklists/CHECKLIST_29_EVENT_DNA_CORE_V2.md) — `163` строк
      - [`docs/source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md`](../source/checklists/CHECKLIST_30_EVIDENCE_CLAIMS_DIALOGIC_V2.md) — `125` строк
  - [`formats/platform_support.yaml`](../../formats/platform_support.yaml) — `253` строк
  - [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
  - [`docs/ops/platform-runtime-compatibility-matrix.md`](../ops/platform-runtime-compatibility-matrix.md) — `43` строк
  - [`docs/ops/platform-vm-testing.md`](../ops/platform-vm-testing.md) — `54` строк
  - [`docs/ops/platform-container-k8s-testing.md`](../ops/platform-container-k8s-testing.md) — `68` строк
  - [`docs/security/fstec-certified-profile.md`](../security/fstec-certified-profile.md) — `30` строк
  - [`docs/release/release_process.md`](../release/release_process.md) — `50` строк `ROOT-INFLUENCE`
  - [`docs/release/versioning.md`](../release/versioning.md) — `35` строк
  - [`docs/release/compat_matrix.md`](../release/compat_matrix.md) — `40` строк
    - [`docs/release/versioning.md`](../release/versioning.md) — `35` строк
    - [`docs/release/release_process.md`](../release/release_process.md) — `50` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-runtime-compatibility-matrix.md`](../ops/platform-runtime-compatibility-matrix.md) — `43` строк
  - [`docs/ops/go_no_go_template.md`](../ops/go_no_go_template.md) — `137` строк
  - [`docs/governance/evidence/evidence_ledger.yaml`](../governance/evidence/evidence_ledger.yaml) — `265` строк
  - [`docs/governance/evidence/`](../governance/evidence/README.md) — `каталог`, файлов `44`, строк `1056`
    - [`docs/governance/evidence/README.md`](../governance/evidence/README.md) — `15` строк
  - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
  - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
  - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
  - [`docs/portal/ART_VISUAL_LANGUAGE.md`](ART_VISUAL_LANGUAGE.md) — `119` строк
  - [`docs/portal/INDEX.md`](INDEX.md) — `75` строк
    - [`docs/README.md`](../README.md) — `136` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
      - [`docs/source/README.md`](../source/README.md) — `105` строк `ROOT-INFLUENCE`
      - [`README.md`](../../README.md) — `198` строк `REUSED-LINK`
      - [`docs/portal/INDEX.md`](INDEX.md) — `75` строк `REUSED-LINK`
      - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
      - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
      - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `579` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
      - [`docs/foundation/revolutionary_hypotheses.md`](../foundation/revolutionary_hypotheses.md) — `173` строк
      - [`docs/foundation/frontier_tech_radar.md`](../foundation/frontier_tech_radar.md) — `46` строк
      - [`docs/foundation/lens_audit_report.md`](../foundation/lens_audit_report.md) — `410` строк
      - [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) — `99` строк
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
        - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `579` строк
          - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
          - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
        - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
          - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
          - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
          - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
          - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
          - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
          - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
          - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
          - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
          - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
          - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
        - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
      - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
      - [`docs/source/connected_system_visibility_v0_2.md`](../source/connected_system_visibility_v0_2.md) — `193` строк `ROOT-INFLUENCE`
      - [`docs/portal/PRODUCT_GUARANTEES.md`](PRODUCT_GUARANTEES.md) — `14` строк
      - [`docs/portal/SECURITY_POSTURE.md`](SECURITY_POSTURE.md) — `107` строк
      - [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
      - [`docs/ops/platform-runtime-compatibility-matrix.md`](../ops/platform-runtime-compatibility-matrix.md) — `43` строк
      - [`docs/ops/platform-vm-testing.md`](../ops/platform-vm-testing.md) — `54` строк
      - [`docs/ops/platform-container-k8s-testing.md`](../ops/platform-container-k8s-testing.md) — `68` строк
      - [`docs/ops/go_no_go_template.md`](../ops/go_no_go_template.md) — `137` строк
      - [`docs/ops/github_actions_queue_remediation_plan.md`](../ops/github_actions_queue_remediation_plan.md) — `212` строк
      - [`docs/source/storage_pressure_protection_v0_2.md`](../source/storage_pressure_protection_v0_2.md) — `119` строк `ROOT-INFLUENCE`
      - [`docs/source/startup_config_safety_validator_v0_2.md`](../source/startup_config_safety_validator_v0_2.md) — `39` строк `ROOT-INFLUENCE`
      - [`docs/source/queue_integrity_protection_v0_2.md`](../source/queue_integrity_protection_v0_2.md) — `44` строк `ROOT-INFLUENCE`
      - [`docs/source/guard_self_observability_v0_2.md`](../source/guard_self_observability_v0_2.md) — `36` строк `ROOT-INFLUENCE`
      - [`docs/release/release_process.md`](../release/release_process.md) — `50` строк `ROOT-INFLUENCE`
      - [`docs/release/versioning.md`](../release/versioning.md) — `35` строк
      - [`docs/release/compat_matrix.md`](../release/compat_matrix.md) — `40` строк
        - [`docs/release/versioning.md`](../release/versioning.md) — `35` строк
        - [`docs/release/release_process.md`](../release/release_process.md) — `50` строк `ROOT-INFLUENCE`
        - [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
        - [`docs/ops/platform-runtime-compatibility-matrix.md`](../ops/platform-runtime-compatibility-matrix.md) — `43` строк
      - [`docs/portal/DELIVERY_EVIDENCE.md`](DELIVERY_EVIDENCE.md) — `26` строк
      - [`docs/source/trust_boundary_hardening_v0_2.md`](../source/trust_boundary_hardening_v0_2.md) — `134` строк `ROOT-INFLUENCE`
      - [`docs/source/browser_surface_hardening_v0_2.md`](../source/browser_surface_hardening_v0_2.md) — `107` строк `ROOT-INFLUENCE`
      - [`docs/source/protective_safeguards_catalog_v0_2.md`](../source/protective_safeguards_catalog_v0_2.md) — `181` строк `ROOT-INFLUENCE`
      - [`docs/governance/evidence_policy.md`](../governance/evidence_policy.md) — `29` строк
      - [`docs/governance/observability_gap_registry.md`](../governance/observability_gap_registry.md) — `87` строк
      - [`docs/governance/evidence/evidence_ledger.yaml`](../governance/evidence/evidence_ledger.yaml) — `265` строк
      - [`docs/governance/release_decisions/`](../governance/release_decisions/README.md) — `каталог`, файлов `2`, строк `114`
        - [`docs/governance/release_decisions/README.md`](../governance/release_decisions/README.md) — `23` строк
      - [`docs/source/checklists/README.md`](../source/checklists/README.md) — `89` строк
      - [`docs/source/risk_register_v0_2.md`](../source/risk_register_v0_2.md) — `59` строк `ROOT-INFLUENCE`
      - [`docs/source/dna_core_determinism_performance_assurance.md`](../source/dna_core_determinism_performance_assurance.md) — `138` строк `ROOT-INFLUENCE`
      - [`docs/source/ingress_perimeter_protection_v0_2.md`](../source/ingress_perimeter_protection_v0_2.md) — `149` строк
      - [`docs/testing/production_adversarial_validation_law.md`](../testing/production_adversarial_validation_law.md) — `203` строк
      - [`docs/testing/test_system_audit_v0_2.md`](../testing/test_system_audit_v0_2.md) — `97` строк
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
    - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
    - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
      - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
      - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
      - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
      - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
      - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
    - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
    - [`docs/foundation/AI_ENGINEERING_OPERATING_MODEL.md`](../foundation/AI_ENGINEERING_OPERATING_MODEL.md) — `174` строк
    - [`docs/foundation/ADVANCED_AUTOMATION_BACKLOG.md`](../foundation/ADVANCED_AUTOMATION_BACKLOG.md) — `183` строк
    - [`docs/foundation/revolutionary_hypotheses.md`](../foundation/revolutionary_hypotheses.md) — `173` строк
    - [`docs/foundation/frontier_tech_radar.md`](../foundation/frontier_tech_radar.md) — `46` строк
    - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
    - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
    - [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) — `99` строк
      - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
      - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
      - [`docs/foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md`](../foundation/UNIVERSAL_PROJECT_IDEOLOGY_TEMPLATE.md) — `579` строк
        - [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк `ROOT-INFLUENCE`
        - [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
      - [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк `ROOT-INFLUENCE`
      - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
      - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
      - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
        - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
        - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
        - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
        - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
        - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
        - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
        - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
        - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
        - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
        - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
    - [`docs/portal/GLOSSARY.md`](GLOSSARY.md) — `14` строк
    - [`docs/portal/PRODUCT_GUARANTEES.md`](PRODUCT_GUARANTEES.md) — `14` строк
    - [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк `ROOT-INFLUENCE`
    - [`docs/ops/platform-vm-testing.md`](../ops/platform-vm-testing.md) — `54` строк
    - [`docs/ops/platform-container-k8s-testing.md`](../ops/platform-container-k8s-testing.md) — `68` строк
    - [`docs/ops/go_no_go_template.md`](../ops/go_no_go_template.md) — `137` строк
    - [`docs/ops/github_actions_queue_remediation_plan.md`](../ops/github_actions_queue_remediation_plan.md) — `212` строк
    - [`docs/portal/ART_VISUAL_LANGUAGE.md`](ART_VISUAL_LANGUAGE.md) — `119` строк
    - [`docs/portal/DELIVERY_EVIDENCE.md`](DELIVERY_EVIDENCE.md) — `26` строк
    - [`docs/testing/buyer_due_diligence_signal_triage_v0_2.md`](../testing/buyer_due_diligence_signal_triage_v0_2.md) — `66` строк
    - [`docs/portal/SECURITY_POSTURE.md`](SECURITY_POSTURE.md) — `107` строк
    - [`docs/source/protective_safeguards_catalog_v0_2.md`](../source/protective_safeguards_catalog_v0_2.md) — `181` строк `ROOT-INFLUENCE`
    - [`docs/source/ingress_perimeter_protection_v0_2.md`](../source/ingress_perimeter_protection_v0_2.md) — `149` строк
    - [`docs/source/trust_boundary_hardening_v0_2.md`](../source/trust_boundary_hardening_v0_2.md) — `134` строк `ROOT-INFLUENCE`
    - [`docs/source/browser_surface_hardening_v0_2.md`](../source/browser_surface_hardening_v0_2.md) — `107` строк `ROOT-INFLUENCE`
    - [`docs/source/storage_pressure_protection_v0_2.md`](../source/storage_pressure_protection_v0_2.md) — `119` строк `ROOT-INFLUENCE`
    - [`docs/source/startup_config_safety_validator_v0_2.md`](../source/startup_config_safety_validator_v0_2.md) — `39` строк `ROOT-INFLUENCE`
    - [`docs/source/queue_integrity_protection_v0_2.md`](../source/queue_integrity_protection_v0_2.md) — `44` строк `ROOT-INFLUENCE`
    - [`docs/source/guard_self_observability_v0_2.md`](../source/guard_self_observability_v0_2.md) — `36` строк `ROOT-INFLUENCE`
    - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
    - [`docs/source/connected_system_visibility_v0_2.md`](../source/connected_system_visibility_v0_2.md) — `193` строк `ROOT-INFLUENCE`
    - [`docs/portal/COMPATIBILITY_MATRIX_ART_REGART.md`](COMPATIBILITY_MATRIX_ART_REGART.md) — `13` строк
    - [`docs/portal/DOC_AUTHORITY.md`](DOC_AUTHORITY.md) — `19` строк
    - [`docs/portal/DOC_STYLE_GUIDE.md`](DOC_STYLE_GUIDE.md) — `41` строк
    - [`docs/api/openapi.yaml`](../api/openapi.yaml) — `82` строк
    - [`docs/contracts/v2/openapi.yaml`](../contracts/v2/openapi.yaml) — `199` строк
    - [`docs/source/secure_actions_protocol_v2.md`](../source/secure_actions_protocol_v2.md) — `27` строк
    - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
  - [`docs/source/README.md`](../source/README.md) — `105` строк `ROOT-INFLUENCE`
  - [`docs/source/checklists/README.md`](../source/checklists/README.md) — `89` строк
  - [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк `ROOT-INFLUENCE`
    - [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк `ROOT-INFLUENCE`
    - [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк `ROOT-INFLUENCE`
    - [`docs/source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md`](../source/checklists/CHECKLIST_05_REGART_UI_GRAPH_RUN_DEBUGGER.md) — `134` строк
    - [`docs/source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md`](../source/checklists/CHECKLIST_06_REGART_ART_BRIDGE.md) — `140` строк
    - [`docs/source/checklists/CHECKLIST_20_PACK_REGART.md`](../source/checklists/CHECKLIST_20_PACK_REGART.md) — `140` строк
    - [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк `ROOT-INFLUENCE`
    - [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк `ROOT-INFLUENCE`
    - [`docs/regart/art_bridge_runbook.md`](../regart/art_bridge_runbook.md) — `19` строк
    - [`docs/regart/upstream_error_format.md`](../regart/upstream_error_format.md) — `29` строк
    - [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк `ROOT-INFLUENCE`
  - [`SECURITY.md`](../../SECURITY.md) — `15` строк
  - [`docs/runbooks/ddos_suspected.md`](../runbooks/ddos_suspected.md) — `40` строк
  - [`docs/runbooks/ingress_shield_degraded.md`](../runbooks/ingress_shield_degraded.md) — `41` строк
  - [`docs/runbooks/trust_boundary_violation.md`](../runbooks/trust_boundary_violation.md) — `36` строк
  - [`docs/runbooks/browser_surface_policy_degraded.md`](../runbooks/browser_surface_policy_degraded.md) — `36` строк

## Документы, влияющие на корневой README
Если изменяется любой документ из этого списка, а `README.md` не изменён, CI подаёт сигнал о рассинхроне.

- [`docs/INTEGRATION.md`](../INTEGRATION.md) — `67` строк
- [`docs/README.md`](../README.md) — `136` строк
- [`docs/foundation/PROJECT_HISTORY_AND_CONCEPTS.md`](../foundation/PROJECT_HISTORY_AND_CONCEPTS.md) — `1493` строк
- [`docs/ops/platform-support.md`](../ops/platform-support.md) — `98` строк
- `docs/packs/source_coverage.md` — `НЕ ПОПАЛ В ДЕРЕВО`
- [`docs/release/release_process.md`](../release/release_process.md) — `50` строк
- [`docs/source/Art_v1_spec_final.md`](../source/Art_v1_spec_final.md) — `614` строк
- [`docs/source/FOUNDATION_CONSTITUTION_V0_2.md`](../source/FOUNDATION_CONSTITUTION_V0_2.md) — `903` строк
- [`docs/source/README.md`](../source/README.md) — `105` строк
- [`docs/source/REGART -  LangGraph  взаимодействие с Art описание.md`](../source/REGART -  LangGraph  взаимодействие с Art описание.md) — `313` строк
- [`docs/source/browser_surface_hardening_v0_2.md`](../source/browser_surface_hardening_v0_2.md) — `107` строк
- [`docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`](../source/checklists/CHECKLIST_00_MASTER_ART_REGART.md) — `332` строк
- [`docs/source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md`](../source/checklists/CHECKLIST_38_STAGE_LADDER_ENFORCEMENT.md) — `93` строк
- `docs/source/checklists/TRACEABILITY_V0_2.md` — `НЕ ПОПАЛ В ДЕРЕВО`
- [`docs/source/connected_system_visibility_v0_2.md`](../source/connected_system_visibility_v0_2.md) — `193` строк
- [`docs/source/dna_core_determinism_performance_assurance.md`](../source/dna_core_determinism_performance_assurance.md) — `138` строк
- [`docs/source/guard_self_observability_v0_2.md`](../source/guard_self_observability_v0_2.md) — `36` строк
- [`docs/source/protective_safeguards_catalog_v0_2.md`](../source/protective_safeguards_catalog_v0_2.md) — `181` строк
- [`docs/source/queue_integrity_protection_v0_2.md`](../source/queue_integrity_protection_v0_2.md) — `44` строк
- [`docs/source/regart_adversarial_integration_harness_v0_2.md`](../source/regart_adversarial_integration_harness_v0_2.md) — `174` строк
- [`docs/source/risk_register_v0_2.md`](../source/risk_register_v0_2.md) — `59` строк
- [`docs/source/startup_config_safety_validator_v0_2.md`](../source/startup_config_safety_validator_v0_2.md) — `39` строк
- [`docs/source/storage_pressure_protection_v0_2.md`](../source/storage_pressure_protection_v0_2.md) — `119` строк
- [`docs/source/trust_boundary_hardening_v0_2.md`](../source/trust_boundary_hardening_v0_2.md) — `134` строк
- [`docs/testing/defect_remediation_control_matrix_v0_2.md`](../testing/defect_remediation_control_matrix_v0_2.md) — `948` строк
- [`docs/testing/defect_remediation_ladder_v0_2.md`](../testing/defect_remediation_ladder_v0_2.md) — `305` строк
- `formats/defect_remediation_control_matrix_v0_2.yaml` — `НЕ ПОПАЛ В ДЕРЕВО`

## Каталоговые узлы
Это специальные узлы дерева для ссылок на каталоги. Они считаются автоматически и показывают:
- сколько файлов внутри;
- сколько строк внутри;
- есть ли индексный документ, на который можно безопасно сослаться.

- [`docs/contracts/v2/schemas/`](../contracts/v2/schemas/README.md) — файлов `16`, строк `1073`
- [`docs/governance/evidence/`](../governance/evidence/README.md) — файлов `44`, строк `1056`
- [`docs/governance/release_decisions/`](../governance/release_decisions/README.md) — файлов `2`, строк `114`

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
