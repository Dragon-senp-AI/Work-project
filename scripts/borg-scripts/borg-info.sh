#!/bin/bash

BORG_REPO="$HOME/Work-project/backups/borg-repo"

if [ -z "$1" ]; then
    echo "Использование: $0 <имя_архива>"
    echo ""
    echo "Доступные архивы:"
    borg list "$BORG_REPO"
    exit 1
fi

ARCHIVE_NAME="$1"

echo "=========================================="
echo "Информация об архиве: $ARCHIVE_NAME"
echo "=========================================="
echo ""

borg info "$BORG_REPO::$ARCHIVE_NAME"