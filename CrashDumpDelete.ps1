$Users=(ls "C:\Users\" | Select-Object -ExpandProperty Name)

Foreach ($i in $Users)
{

$CrashDump=(Test-Path "C:\Users\$i\Documents\My Tableau Repository\Logs\crashdumps")

if ($CrashDump -like '*True*'){
    Get-ChildItem -Path "C:\Users\$i\Documents\My Tableau Repository\Logs\crashdumps" -Include * -File -Recurse | foreach { $_.Delete()}
}


}