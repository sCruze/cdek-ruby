#!/usr/bin/env bash
# Создаёт аннотированный git-тег для текущей версии гема cdek.
#
# Использование (из корня репозитория cdek-ruby):
#   bin/tag_release.sh
#
# Что делает:
#   1. Читает версию из lib/cdek/version.rb.
#   2. Проверяет, что тега v<version> ещё нет.
#   3. Вытаскивает секцию CHANGELOG для этой версии в тело тега.
#   4. Создаёт аннотированный тег и пушит его в origin.

set -euo pipefail

if [[ ! -f lib/cdek/version.rb ]]; then
  echo "Ошибка: запускай из корня репозитория cdek-ruby (нет lib/cdek/version.rb)." >&2
  exit 1
fi

if [[ ! -f CHANGELOG.md ]]; then
  echo "Ошибка: CHANGELOG.md не найден в корне." >&2
  exit 1
fi

VERSION="$(ruby -Ilib -e 'require "cdek/version"; puts Cdek::VERSION')"
TAG="v${VERSION}"

if [[ -z "${VERSION}" ]]; then
  echo "Ошибка: не удалось прочитать Cdek::VERSION." >&2
  exit 1
fi

if git rev-parse --quiet --verify "refs/tags/${TAG}" >/dev/null; then
  echo "Тег ${TAG} уже существует локально. Удали его (git tag -d ${TAG}) и перезапусти, если нужно пересоздать." >&2
  exit 1
fi

# Незакоммиченные правки — стоп: тег должен указывать на чистый коммит.
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Ошибка: рабочее дерево не чистое. Закоммить или застэшь правки перед тегированием." >&2
  exit 1
fi

# Секция CHANGELOG для текущей версии — всё между "## <version>" и следующим "## ".
BODY="$(awk -v ver="${VERSION}" '
  $0 ~ "^## " ver "([^0-9].*)?$" { flag=1; next }
  flag && /^## / { exit }
  flag { print }
' CHANGELOG.md)"

if [[ -z "${BODY//[[:space:]]/}" ]]; then
  echo "Ошибка: секция '## ${VERSION}' пуста или не найдена в CHANGELOG.md." >&2
  exit 1
fi

git tag -a "${TAG}" -m "Release ${TAG}" -m "${BODY}"
echo "Локальный тег ${TAG} создан."

git push origin "${TAG}"
echo "Тег ${TAG} запушен в origin."
