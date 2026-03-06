# Secrets Scanning Policy

## Source of truth
- `docs/source/checklists/CHECKLIST_04 _Secure SDLC + Supply-chain.md`
- `.github/workflows/security_stage04.yml`
- `.github/workflows/ci.yml`
- `docs/security/allowlist.gitleaks.toml`

## Назначение
Этот документ фиксирует обязательную политику поиска секретов в репозитории Art. Политика блокирующая: secrets scanning не advisory и не informational, а release-blocking и merge-blocking контроль.

## Инструмент
- Единственный инструмент secrets scanning: `gitleaks`.
- В CI используется pinned action `gitleaks/gitleaks-action@<sha>`.
- Локальная инженерная проверка выполняется той же логикой, что и CI, без отдельной “упрощённой” политики.

## Обязательные точки запуска
- каждый `pull_request` в `main`;
- каждый `push` в `main`;
- любой release-oriented прогон, где есть публикация артефактов;
- локальный security smoke перед merge рекомендуется и описан отдельной командой ниже.

## Политика фейла
- любой найденный секрет блокирует merge;
- уровень “warning only” запрещён;
- silent bypass запрещён;
- отсутствие запуска secrets-gate считается ошибкой пайплайна;
- placeholder execution вида `echo "gitleaks placeholder"` запрещён.

## Allowlist policy
- исключения допускаются только через `docs/security/allowlist.gitleaks.toml`;
- allowlist не может быть placeholder-файлом;
- каждая запись allowlist обязана быть:
  - минимальной по области действия;
  - объяснимой;
  - привязанной к конкретному пути, regex или тестовому кейсу;
  - внесённой через code review;
- широкие allowlist-паттерны уровня “весь каталог”, “все md”, “все json” запрещены;
- временные исключения без даты и причины запрещены.

## Текущий baseline allowlist
- baseline allowlist по умолчанию пустой;
- если ложноположительные кейсы появятся позже, они добавляются адресно и только после review.

## Команды проверки
Локальный smoke:

```bash
gitleaks detect --source . --redact --config docs/security/allowlist.gitleaks.toml
```

Негативная проверка на тестовом секрете выполняется вне постоянного дерева репозитория или на временном файле, который удаляется сразу после проверки.

## Требования к CI
- workflow `security-stage04` обязан содержать реальный job `secrets`;
- job `secrets` обязан:
  - checkout с `fetch-depth: 0`;
  - запускать `gitleaks`;
  - использовать `docs/security/allowlist.gitleaks.toml`;
  - завершаться ошибкой при любом finding;
- job `gitleaks` в основном CI не отменяет и не ослабляет Stage04 policy, а дублирует её как baseline repository-wide gate.

## Требования к артефактам и аудиту
- изменения allowlist считаются security-sensitive изменениями;
- такие изменения должны быть видны в PR diff;
- при каждом изменении allowlist должна обновляться причина изменения в PR description или в связанном security note;
- скрывать false positive через удаление проверки вместо точечного allowlist запрещено.

## Запрещено
- placeholder-allowlist;
- allowlist без объяснимой причины;
- secrets-gate без реального запуска `gitleaks`;
- мягкий режим “не блокировать merge”;
- различающаяся политика для локального и CI-контуров.
