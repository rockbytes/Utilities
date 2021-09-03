# This script is to update the Source IP Addresses of a Network Security Group rule using the 
# IP list grabbed from Grafana (https://grafana.com/api/hosted-grafana/source-ips.txt).

param(
    [String][Parameter(Mandatory=$true)]$RuleName,
    [String][Parameter(Mandatory=$true)]$SecurityGroupName,
    [String][Parameter(Mandatory=$true)]$ResourceGroupName
)

# Login
$credential = Get-Credential
Connect-AzureRmAccount -Credential $Credential
    
# Get Network Security Group
$nsg = Get-AzureRmNetworkSecurityGroup -Name $SecurityGroupName -ResourceGroupName $ResourceGroupName

# Update the SourceIpAddress of the rule if needed
Update-SourceIpAddressWithGrafanaIps -nsg $nsg


function Update-SourceIpAddressWithGrafanaIps($nsg)
{
    # Get IP addresses from Grafana
    [System.Collections.Generic.List[String]]$ipList = Get-IpListFromGrafana
        
    # Update the source IPs of Network Security Group if needed
    foreach ($rule in $nsg.SecurityRules)
    {
        if ($rule.Name -eq $RuleName)
        {
            if (Compare-Object -ReferenceObject $rule.SourceAddressPrefix -DifferenceObject $ipList)
            {
                # Update the source IPs as they are not equal
                $rule.SourceAddressPrefix = $ipList
                Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg
            }
        
            break
        }
    }
}

function Get-IpListFromGrafana()
{
    $ipListUri = "https://grafana.com/api/hosted-grafana/source-ips.txt"
    $ipString = (Invoke-WebRequest -Uri $ipListUri -UseBasicParsing).ToString()
        
    return $ipString -split "\s"
}
