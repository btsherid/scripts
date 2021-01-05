$Groups = (Get-ADGroup -Filter * -SearchBase "OU=BioInf,OU=UNC,DC=ad,DC=unc,DC=edu" | Select Name -ExpandProperty Name | Sort-Object)
$Excluded_Groups = 'BioInf_Computer Admins','BioInf_Computers','BioInf_Dev_2008','BioInf_Dev_2012','BioInf_Dev_2016','BioInf_Machines','BioInf_Prod_2008','BioInf_Prod_2012','BioInf_Prod_2016','BioInf_Qualys Authenticated Scanned Computers','BioInf_Server Admins','BioInf_Servers','BioInf_Users','BioInf_VC','SW_BioInf_Microsoft_Configuration Manager Client_5.0.7711'
$Excluded_Accounts = '.adm','.svc'


Foreach ($i in $Groups)
{
    $Group_Distinguished_Name = (Get-ADGroup -properties DistinguishedName -Identity $i | Select DistinguishedName -ExpandProperty DistinguishedName)
    $Group_Excluded = ""
    if ($Group_Distinguished_Name -like '*Decommissioned*'){
    $Group_Excluded = "yes"
}
    if ($Excluded_Groups -notcontains $i -And ! $Group_Excluded)
    {
        $No_Disabled_Users = "True"
        $Group_Members= (Get-ADGroupMember -identity $i | Select SAMAccountName -ExpandProperty SAMAccountName)
        echo "===$i==="
        Foreach ($j in $Group_Members){
            $User_Disabled = (Get-ADUser -Identity $j -Properties Enabled | Select Enabled -ExpandProperty Enabled)
            if ($User_Disabled -like '*False*'){
                Get-ADUser -Identity $j | Select Name -ExpandProperty Name
                $No_Disabled_Users = "False"
                }
        
        }
    if ($No_Disabled_Users -like '*True*'){
        echo "None"
        }
    echo ""       
    }
}