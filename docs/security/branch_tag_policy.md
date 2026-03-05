# Branch and tag policy

- direct push в `main` запрещён
- PR-only в `main`
- required reviews >= 1
- CODEOWNERS review обязателен
- force-push в `main` запрещён
- release tags защищены от перезаписи
- Verified commits only in main
- merge блокируется, если коммит не Verified

Required checks:
- sdlc-gate
- sast
- sca
- license
- secrets
