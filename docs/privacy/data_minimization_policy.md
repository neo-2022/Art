# Data minimization policy

- no HTTP bodies by default.
- Разрешён только allowlist HTTP-полей контекста.
- headers/cookies вне allowlist запрещены к записи.
- message/payload/context проходят policy drop/redact.
