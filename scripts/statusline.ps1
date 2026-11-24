# claudez status line (Windows): model | context used
try { $in = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { $in = $null }
$parts = @(@($in.model.display_name, $in.model.id) | Where-Object { $_ } | Select-Object -First 1)
if (-not $parts) { $parts = @('GLM-5.3') }
if ($null -ne $in.context_window.used_percentage) {
  $parts += "ctx $([math]::Floor($in.context_window.used_percentage))%"
}
$parts -join ' | '
