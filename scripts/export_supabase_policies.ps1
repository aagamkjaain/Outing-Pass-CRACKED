<#
Export Supabase Postgres RLS policies and functions to files.

Usage (PowerShell):
  - Ensure you have `psql` installed and on PATH (Postgres client).
  - Set the connection string in env var PGCONN, e.g.:
      $env:PGCONN = 'postgres://postgres:password@db.host.supabase.co:5432/postgres?sslmode=require'
  - Run this script from repository root in PowerShell:
      .\scripts\export_supabase_policies.ps1

If you don't have psql, you can run the SQL snippets below in the Supabase SQL editor and copy the output.
This script will create `scripts\exports\` and write three files:
  - rls_policies.sql          (human friendly SELECT output)
  - rls_table_flags.sql       (table row-security flags)
  - functions_definitions.sql (full function definitions via pg_get_functiondef)

Security: this script reads PGCONN from env only and does not send secrets anywhere.
#>

$ErrorActionPreference = 'Stop'

$pgconn = $env:PGCONN
if (-not $pgconn) {
    Write-Host "ERROR: PGCONN env var not set. Set it to your Postgres connection string (see header comments)." -ForegroundColor Red
    exit 1
}

# ensure output dir exists
$exportDir = Join-Path -Path $PSScriptRoot -ChildPath 'exports'
if (-not (Test-Path $exportDir)) { New-Item -ItemType Directory -Path $exportDir | Out-Null }

# check psql
$psql = 'psql'
try {
    $which = & $psql --version 2>$null
} catch {
    Write-Host "psql not found on PATH. Install PostgreSQL client tools or run the SQL from Supabase SQL editor." -ForegroundColor Yellow
    Write-Host "Provided SQL snippets are printed at the end of this script." -ForegroundColor Yellow
    $psql = $null
}

# SQL queries
$policiesQuery = @"
-- RLS policies (schema, table, policy_name, command, permissive, roles, USING, WITH CHECK)
SELECT
  n.nspname AS schema,
  c.relname AS table,
  p.polname AS policy_name,
  p.polcmd AS command,
  p.polpermissive AS permissive,
  pg_get_expr(p.polqual, p.polrelid) AS using_expr,
  pg_get_expr(p.polwithcheck, p.polrelid) AS with_check_expr,
  (SELECT array_agg(rolname) FROM pg_roles r JOIN unnest(coalesce(p.polroles, ARRAY[]::text[])) rr ON TRUE WHERE r.rolname = rr) AS roles
FROM pg_policy p
JOIN pg_class c ON p.polrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
ORDER BY schema, table, policy_name;
"@

$tableFlagsQuery = @"
-- Tables with row security flags
SELECT
  n.nspname AS schema,
  c.relname AS table,
  c.relrowsecurity AS row_security_enabled,
  c.relforcerowsecurity AS force_row_security
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'r'
ORDER BY schema, table;
"@

$functionsQuery = @"
-- Function definitions (schema, name, definition)
SELECT
  n.nspname AS schema,
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT IN ('pg_catalog','information_schema')
ORDER BY schema, function_name;
"@

if ($psql) {
    Write-Host "Running queries via psql and saving outputs to $exportDir"

    $polFile = Join-Path $exportDir 'rls_policies.sql'
    $tableFile = Join-Path $exportDir 'rls_table_flags.sql'
    $fnFile = Join-Path $exportDir 'functions_definitions.sql'

    & $psql $pgconn -c "$policiesQuery" -P pager=off | Out-File -FilePath $polFile -Encoding utf8
    Write-Host "Wrote $polFile"

    & $psql $pgconn -c "$tableFlagsQuery" -P pager=off | Out-File -FilePath $tableFile -Encoding utf8
    Write-Host "Wrote $tableFile"

    & $psql $pgconn -c "$functionsQuery" -P pager=off | Out-File -FilePath $fnFile -Encoding utf8
    Write-Host "Wrote $fnFile"

    Write-Host "Export complete. Inspect the files in scripts\exports\" -ForegroundColor Green
} else {
    Write-Host "\npsql not available. Use the following SQL snippets in the Supabase SQL editor (copy-paste)." -ForegroundColor Yellow
    Write-Host "---- RLS policies SQL ----" -ForegroundColor Cyan
    Write-Host $policiesQuery
    Write-Host "---- Table flags SQL ----" -ForegroundColor Cyan
    Write-Host $tableFlagsQuery
    Write-Host "---- Functions SQL ----" -ForegroundColor Cyan
    Write-Host $functionsQuery
}

Write-Host "If you paste the results here (or attach the files from scripts/exports), I can parse and reconcile the live RLS/policies with your local SQL files." -ForegroundColor Green
