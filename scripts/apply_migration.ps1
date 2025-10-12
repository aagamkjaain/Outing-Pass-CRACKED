# Apply the get_user_roles RPC function to your Supabase database

Write-Host "Applying get_user_roles RPC function to Supabase..." -ForegroundColor Cyan

# Read the SQL file
$sqlContent = Get-Content -Path "supabase\migrations\create_get_user_roles_function.sql" -Raw

# Get Supabase credentials from environment or prompt
$supabaseUrl = $env:REACT_APP_SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl) {
    $supabaseUrl = Read-Host "Enter your Supabase URL (e.g., https://xxx.supabase.co)"
}

if (-not $supabaseKey) {
    Write-Host "`nYou need the SERVICE_ROLE_KEY (not anon key) to create database functions." -ForegroundColor Yellow
    Write-Host "Find it in: Supabase Dashboard -> Project Settings -> API -> service_role key" -ForegroundColor Yellow
    $supabaseKey = Read-Host "Enter your Supabase SERVICE ROLE KEY"
}

# Execute SQL via REST API
try {
    $headers = @{
        "apikey" = $supabaseKey
        "Authorization" = "Bearer $supabaseKey"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        query = $sqlContent
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/exec" -Method Post -Headers $headers -Body $body
    
    Write-Host "`n✓ Successfully created get_user_roles function!" -ForegroundColor Green
    Write-Host "The new JWT-based role detection will now use this efficient single-call RPC." -ForegroundColor Green
} catch {
    Write-Host "`n✗ Failed to create function via REST API." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`nAlternative: Run the SQL directly in Supabase SQL Editor:" -ForegroundColor Yellow
    Write-Host "1. Go to: $supabaseUrl/project/_/sql" -ForegroundColor Yellow
    Write-Host "2. Copy the contents of: supabase\migrations\create_get_user_roles_function.sql" -ForegroundColor Yellow
    Write-Host "3. Paste and run in the SQL editor" -ForegroundColor Yellow
}
