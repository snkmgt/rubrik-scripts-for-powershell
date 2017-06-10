#requires -Version 3
function Connect
{
    [CmdletBinding()]
    Param(
    
        [String]$Brik,
        [String]$Username,
        [String]$Password
    )

    Process {

        try 
        {
            $return = Connect-Rubrik -Server $Brik -Username $Username -Password (ConvertTo-SecureString -String $Password -AsPlainText -Force) -ErrorAction Stop
        }
        catch
        {
            Write-Host -Object $_
        }

        return $return
    }
}

function RemoveMount
{
    try
    {
        Get-RubrikMount | Remove-RubrikMount -Confirm:$false
    }
    catch
    {
        Write-Host -Object $_
    }
}

function RemoveProtectionVM
{
    [regex]$slaFilter = SLARegex
    
    foreach ($vm in Get-RubrikVM)
    {
        $sla = $vm.effectivesladomainname

        if ($sla -notmatch $slaFilter)
        {
            try
            {
                Write-Verbose -Message "Removing protection from $($vm.name) which is currently $sla"
                $vm | Protect-RubrikVM -DoNotProtect -Confirm:$false
            }
            catch
            {
                Write-Host -Object $_
            }
        }
    }
}

function RemoveProtectionDB
{
    [regex]$slaFilter = SLARegex
    
    foreach ($db in Get-RubrikDatabase)
    {
        $sla = $db.effectivesladomainname        

        if ($sla -notmatch $slaFilter)
        {
            try
            {
                Write-Verbose -Message "Removing protection from $($db.name) which is currently $sla"
                $db | Protect-RubrikDatabase -DoNotProtect -Confirm:$false
            }
            catch
            {
                Write-Host -Object $_
            }
        }
    }
}

function RemoveProtectionFileset
{
    [regex]$slaFilter = SLARegex
    
    foreach ($fileset in Get-RubrikFileset)
    {
        $sla = $fileset.effectivesladomainname        

        if ($sla -notmatch $slaFilter -and $sla -ne $null)
        {
            try
            {
                Write-Verbose -Message "Removing protection from $($fileset.name) which is currently $sla"
                $fileset | Protect-RubrikFileset -DoNotProtect -Confirm:$false
            }
            catch
            {
                Write-Host -Object $_
            }
        }
    }
}

function RemoveSLA
{
    [regex]$slaFilter = SLARegex

    foreach ($sla in (Get-RubrikSLA).name)
    {
        if ($sla -notmatch $slaFilter)
        {
            try
            {
                Get-RubrikSLA -SLA $sla | Remove-RubrikSLA -Confirm:$false
            }
            catch 
            {
                Write-Host -Object $_
            }
        }
    }
}

function RemoveReport
{

foreach ($report in Get-RubrikReport -Type Custom)
    {

    if ($report.reportName -notlike "*DND*")
        {
        Write-Verbose -Message "Removing report $($report.reportName)" -Verbose
        $report | Remove-RubrikReport -Confirm:$false
        }
    }
}


function ReportCleanup
{
    $ver = Get-RubrikVersion

    $slalist = (Get-RubrikSLA -PrimaryClusterID 'local' | Sort-Object -Property Name)
    [string]$slanames = $null
    foreach ($sla in $slalist)
    {
        $slanames += $sla.Name
        if ($sla.name -ne $slalist[-1].name) 
        {
            $slanames += ', '
        }
    }

    [array]$mountlist = Get-RubrikMount

    $url = 'https://hooks.slack.com/services/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'

    $body = @{
        text        = "Cleanup Report: $Brik ($($ver.id))"
        attachments = @(
            @{
                fallback = 'SE Lab Summary Report'
                color    = 'good'
                fields   = @(
                    @{
                        title = 'Cluster Version'
                        value = $ver.version
                        short = 'true'
                    }

                    @{
                        title = 'API Version'
                        value = $ver.apiVersion
                        short = 'true'
                    }

                    @{
                        title = 'SLA Domains'
                        value = $slanames
                        short = 'true'
                    }

                    @{
                        title = 'Live Mounts'
                        value = $mountlist.Count
                        short = 'true'
                    }
                )
            }
        )
    }

    $jbody = $body | ConvertTo-Json -Depth 4

    Invoke-WebRequest -Uri $url -Method Post -Body $jbody -ContentType 'application/json'
}

function SLARegex ()
{
    # Case insensitive match to Gold, Bronze, Silver, and anything with DND in it (Do Not Delete).
    [regex]$slaFilter = "(?i)^(gold|bronze|silver|unprotected|.*DND.*)$"
    return $slaFilter
}
