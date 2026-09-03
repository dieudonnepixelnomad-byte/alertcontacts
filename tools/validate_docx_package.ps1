$ErrorActionPreference = 'Stop'

$path = "C:\Users\dieud\Documents\MOI\PROJETS\ALERTCONTACTS-V3\alertcontacts\docs\Rapport-Analytics-PostHog-AlertContacts-2026-09-03.docx"
$required = @(
    "[Content_Types].xml",
    "_rels/.rels",
    "word/document.xml",
    "word/styles.xml",
    "word/_rels/document.xml.rels"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($path)
try {
    foreach ($name in $required) {
        $entry = $zip.GetEntry($name)
        if ($null -eq $entry) {
            throw "Missing DOCX part: $name"
        }

        $reader = [System.IO.StreamReader]::new($entry.Open())
        try {
            $xml = $reader.ReadToEnd()
            [xml]$null = $xml
        } finally {
            $reader.Close()
        }

        Write-Output "OK $name"
    }

    Write-Output "DOCX bytes: $((Get-Item -LiteralPath $path).Length)"
    Write-Output "DOCX entries: $($zip.Entries.Count)"
} finally {
    $zip.Dispose()
}
