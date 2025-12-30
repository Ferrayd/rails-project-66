# Анализатор качества репозиториев

Проект, который помогает автоматически следить за качеством репозиториев на гитхабе. Он отслеживает изменения и прогоняет их через встроенные анализаторы. Затем формирует отчеты и отправляет их пользователю. 

### Hexlet tests and linter status:
[![Actions Status](https://github.com/Ferrayd/rails-project-66/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Ferrayd/rails-project-66/actions)
[![CI](https://github.com/Ferrayd/rails-project-66/actions/workflows/ci.yml/badge.svg)](https://github.com/Ferrayd/rails-project-66)

## Ссылка на проект
[Деплой на Render](https://rails-project-66-6m3i.onrender.com/)

## Локальный запуск

make install-without-production
```
(after that fill *.env* file with correct values)
## Start dev-server
```
make dev-start
```
## Start linters
```
make lint
```
## Start tests
```
make test
```
