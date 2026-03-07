# Политика аутентичности и copyright-safe корпуса

## Source of truth
- `docs/source/FOUNDATION_CONSTITUTION_V0_2.md`
- `docs/source/checklists/CHECKLIST_00_MASTER_ART_REGART.md`
- `formats/authenticity_assets_allowlist.yaml`
- `scripts/ci/check_authenticity_assets.sh`

## Назначение
Эта политика запрещает попадание в проект сущностей, которые могут привести к претензиям правообладателей, vendor lock-in по брендовым материалам или спору о происхождении артефакта.

Жёсткое правило:
- репозиторий, runtime и демонстрационный контур проекта должны быть аутентичными;
- по умолчанию в проект нельзя добавлять чужие защищённые материалы;
- любое исключение требует явного машиночитаемого provenance и правового основания.

## Что считается рисковой сущностью
Под запретом по умолчанию:
- сторонние аудиофайлы, мелодии, сэмплы, voice clips;
- сторонние шрифты, иконки, иллюстрации, логотипы, брендовые знаки;
- чужие screenshots, product mockups, demo-media;
- куски текстов, шаблонов, runbooks или маркетинговых материалов с неочевидным происхождением;
- datasets и fixtures, происхождение и права на которые не доказаны;
- packs/payload/assets, происхождение которых не описано;
- runtime references на внешние CDN с медиа, шрифтами, иконками или UI-assets.

## Разрешённый baseline
Разрешены только следующие классы материалов:
1. Собственные оригинальные материалы проекта.
2. Процедурно или программно сгенерированные материалы проекта.
3. Синтетические тестовые/демо данные без внешнего авторского происхождения.
4. Внутренние evidence-артефакты, сгенерированные CI/тестами/браузером внутри проекта.
5. Явно разрешённые элементы из `formats/authenticity_assets_allowlist.yaml`.

## Обязательные правила для runtime
- По умолчанию runtime не должен зависеть от сторонних аудиофайлов, шрифтов, иконок, CDN и brand-assets.
- Все default audio effects должны быть процедурными или синтезированными внутри проекта.
- Все встроенные UI assets должны иметь подтверждённое project-owned происхождение.
- Нельзя вшивать в продукт “временно взятые” чужие материалы.

## Обязательные правила для демонстраций и документации
- Demo/showcase слой обязан использовать только project-owned или generated материалы.
- Screenshots/evidence допускаются только как generated evidence, а не как product runtime assets.
- Fixtures обязаны быть синтетическими или анонимизированными так, чтобы не создавать спор о правах и персональных данных.
- Нельзя копировать чужие product screenshots, UI fragments, diagrams, melodies, icon packs или text fragments без явной правовой базы.

## Пользовательский контент
- Пользователь может загружать собственные sounds/assets только как external user-supplied content.
- Проект обязан явно предупреждать: пользователь отвечает за права на загружаемый контент.
- Такой контент не становится частью baseline проекта и не должен коммититься в репозиторий.

## Машиночитаемый baseline
Единственный допустимый allowlist бинарных/media/icon assets фиксируется в:
- `formats/authenticity_assets_allowlist.yaml`

Любой tracked asset подходящего класса, не попавший в allowlist, считается нарушением политики.

## CI enforcement
- `scripts/ci/check_authenticity_assets.sh` обязан проверять tracked asset surface.
- Этот gate обязан быть частью security/supply-chain дисциплины.
- Green status запрещён, если найден неразрешённый бинарный/media/font/icon asset или runtime reference на запрещённый внешний asset/CDN path.

## Связь с checklist-программой
- Stage 04: supply-chain, provenance, legal-safe baseline.
- Stage 07: repo/public docs quality.
- Stage 19/20: packs и payload provenance.
- Stage 28/40: visual language, audio baseline, showcase layer.
- Stage 37: production hardening и release legality.

## Критерий PASS
Система считается соответствующей политике только если одновременно:
- все tracked медиа/иконки/fonts/runtime assets входят в allowlist;
- runtime по умолчанию не опирается на сторонние brand/media assets;
- default audio baseline процедурный или project-owned;
- демо и evidence разделены;
- user-supplied content не смешивается с baseline проекта.
