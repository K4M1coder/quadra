param(
  [string]$Id,
  [switch]$ListIds,
  [string]$Path = 'g:\testprojects\original-products\quadra\Quadra Document Complet.html'
)
$raw = Get-Content $Path -Raw
$html = $raw -replace '\\u002F','/' -replace '\\u003C','<' -replace '\\u003E','>'
$html = $html -replace '\\"','"' -replace '\\n',"`n" -replace '\\t',"`t"
if ($ListIds) {
  [regex]::Matches($html, '<div id="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
  return
}
if (-not $Id) { throw "Fournir -Id ou -ListIds" }
$open = [regex]::Match($html, '<div id="' + [regex]::Escape($Id) + '"')
if (-not $open.Success) { throw "Section '$Id' introuvable" }
$pos = $open.Index; $depth = 0; $end = -1
foreach ($m in [regex]::Matches($html.Substring($pos), '<div\b|</div>')) {
  if ($m.Value -eq '</div>') { $depth-- } else { $depth++ }
  if ($depth -eq 0) { $end = $pos + $m.Index + $m.Length; break }
}
if ($end -lt 0) { throw "Fermeture du div '$Id' introuvable" }
$frag = $html.Substring($pos, $end - $pos)
$txt = $frag -replace '(?s)<(script|style)\b.*?</\1>',''
$txt = $txt -replace '</(div|p|li|tr|h[1-6]|section|table|thead|tbody)>', "`n"
$txt = $txt -replace '</(td|th)>', "`t" -replace '<br\s*/?>', "`n" -replace '<[^>]+>',''
$txt = $txt -replace '&nbsp;',' ' -replace '&amp;','&' -replace '&lt;','<' -replace '&gt;','>' -replace '&quot;','"' -replace '&#39;',"'"
$txt = $txt -replace '[ \t]+\r?\n', "`n" -replace '(\r?\n){3,}', "`n`n"
$txt.Trim()
