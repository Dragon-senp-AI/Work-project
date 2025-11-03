#!/bin/bash

# Загрузка переменных из .env файла
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi
