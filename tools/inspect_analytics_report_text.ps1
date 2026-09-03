$ErrorActionPreference = 'Stop'

$path = "C:\Users\dieud\Documents\MOI\PROJETS\ALERTCONTACTS-V3\alertcontacts\docs\Rapport-Analytics-PostHog-AlertContacts-2026-09-03.docx"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($path)
try {
    $entry = $zip.GetEntry("word/document.xml")
    if ($null -eq $entry) { throw "Missing word/document.xml" }
    $reader = [System.IO.StreamReader]::new($entry.Open())
    try {
        [xml]$xml = $reader.ReadToEnd()
    } finally {
        $reader.Close()
    }

    $ns = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
    $ns.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
    $texts = $xml.SelectNodes("//w:t", $ns) | ForEach-Object { $_.'#text' }
    Write-Output "Text nodes: $($texts.Count)"
    Write-Output "First lines:"
    $texts | Select-Object -First 20
} finally {
    $zip.Dispose()
}
