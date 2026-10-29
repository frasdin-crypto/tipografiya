# Сборка БД типографии: схема + импорт CSV.
# Использование:  powershell -ExecutionPolicy Bypass -File .\build.ps1

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

function Find-Sqlite {
    $cmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $local = Join-Path $PSScriptRoot 'tools\sqlite3.exe'
    if (Test-Path $local) { return $local }

    return $null
}

function Install-SqliteLocal {
    $tools = Join-Path $PSScriptRoot 'tools'
    New-Item -ItemType Directory -Path $tools -Force | Out-Null
    $zip = Join-Path $env:TEMP 'sqlite-tools.zip'
    $url = 'https://www.sqlite.org/2024/sqlite-tools-win-x64-3460100.zip'
    Write-Host "Скачиваю SQLite: $url"
    Invoke-WebRequest -Uri $url -OutFile $zip
    $extract = Join-Path $env:TEMP 'sqlite-tools'
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $extract -Force
    $exe = Get-ChildItem -Path $extract -Filter sqlite3.exe -Recurse | Select-Object -First 1
    if (-not $exe) { throw 'sqlite3.exe не найден в архиве SQLite' }
    Copy-Item $exe.FullName (Join-Path $tools 'sqlite3.exe') -Force
    return (Join-Path $tools 'sqlite3.exe')
}

$sqlite = Find-Sqlite
if (-not $sqlite) {
    $sqlite = Install-SqliteLocal
}

$db = Join-Path $PSScriptRoot 'printshop.db'
if (Test-Path $db) { Remove-Item $db -Force }

Write-Host "Создаю схему..."
& $sqlite $db '.read schema.sql'
if ($LASTEXITCODE -ne 0) { throw "Ошибка schema.sql (код $LASTEXITCODE)" }

Write-Host "Импортирую CSV..."
& $sqlite $db '.read import.sql'
if ($LASTEXITCODE -ne 0) { throw "Ошибка import.sql (код $LASTEXITCODE)" }

Write-Host "Проверка строк:"
& $sqlite $db "SELECT 'clients' AS t, COUNT(*) AS n FROM clients UNION ALL SELECT 'orders', COUNT(*) FROM orders UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;"

Write-Host "Готово: $db"
Write-Host "Примеры запросов:  & `"$sqlite`" printshop.db `".read queries.sql`""
