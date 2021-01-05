$Groups = (Get-ADGroup -Filter * -SearchBase "OU=BioInf,OU=UNC,DC=ad,DC=unc,DC=edu" | Select Name -ExpandProperty Name | Sort-Object)

echo ""
Foreach ($i in $Groups)
{
$Group_Excluded = ""
$Group_Members = (Get-ADGroupMember -identity $i | Select Name -ExpandProperty Name | Sort-Object)

$Group_Distinguished_Name = (Get-ADGroup -properties DistinguishedName -Identity $i | Select DistinguishedName -ExpandProperty DistinguishedName)


if ($Group_Distinguished_Name -like '*Decommissioned*'){
    $Group_Excluded = "yes"
}

if (! $Group_Members -And ! $Group_Excluded){
    echo $i
    echo ""
}
}