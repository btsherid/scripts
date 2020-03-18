$Groups = (Get-ADGroup -Filter * -SearchBase "OU=BioInf,OU=UNC,DC=ad,DC=unc,DC=edu" | Select Name -ExpandProperty Name | Sort-Object)

Foreach ($i in $Groups)
{
$Group_Excluded = ""
$Group_Members = (Get-ADGroupMember -identity $i | Select Name -ExpandProperty Name | Sort-Object)
$Group_Description = (Get-ADGroup -properties info,description -Identity "$i"  | Select Description -ExpandProperty Description)
$Group_Owner = (Get-ADGroup -properties info,description -Identity "$i" | Select info -ExpandProperty info)
$Group_Distinguished_Name = (Get-ADGroup -properties DistinguishedName -Identity $i | Select DistinguishedName -ExpandProperty DistinguishedName)


if ($Group_Distinguished_Name -like '*Decommissioned*'){
    $Group_Excluded = "yes"
}

if ($Group_Members -And ! $Group_Excluded)
{
echo "===$i==="
echo "Description: $Group_Description"
echo $Group_Owner
echo $Group_Members
echo ""
}elseif (! $Group_Excluded){
echo "===$i==="
echo "No Members"
echo ""
}
}