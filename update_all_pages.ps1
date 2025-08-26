$files = Get-ChildItem -Path "Pages" -Filter "*.cs" -Recurse | Where-Object { $_.Name -notlike "*BasePageModel*" }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Skip if already using BasePageModel
    if ($content -match "BasePageModel") {
        continue
    }
    
    # Update class inheritance
    $content = $content -replace "public class (\w+) : PageModel", "public class `$1 : BasePageModel"
    
    # Update connection usage
    $content = $content -replace "using var connection = _connectionFactory\.CreateConnection\(\);", "using var connection = GetConnection();"
    
    Set-Content $file.FullName $content
    Write-Host "Updated: $($file.Name)"
}