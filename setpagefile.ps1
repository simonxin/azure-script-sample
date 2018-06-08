function Set-PageFile
{
    [CmdletBinding(SupportsShouldProcess=$True)]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $InitialSize,
        [Parameter(Mandatory=$true,Position=2)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $MaximumSize
    )
    Set-PSDebug -Strict
 
    $ComputerSystem = $null
    $CurrentPageFile = $null
    $Modified = $false
 
    # Disables automatically managed page file setting first
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
    if ($ComputerSystem.AutomaticManagedPagefile)
    {
        $ComputerSystem.AutomaticManagedPagefile = $false
        if ($PSCmdlet.ShouldProcess("$($ComputerSystem.Path.Server)", 'Disable automatic managed page file'))
        {
            $ComputerSystem.Put()
        }
    }
 
    $CurrentPageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($CurrentPageFile.Name -eq $Path)
    {
        # Keeps the existing page file
        if ($CurrentPageFile.InitialSize -ne $InitialSize)
        {
            $CurrentPageFile.InitialSize = $InitialSize
            $Modified = $true
        }
        if ($CurrentPageFile.MaximumSize -ne $MaximumSize)
        {
            $CurrentPageFile.MaximumSize = $MaximumSize
            $Modified = $true
        }
        if ($Modified)
        {
            if ($PSCmdlet.ShouldProcess("Page file $Path", "Set initial size to $InitialSize and maximum size to $MaximumSize"))
            {
                $CurrentPageFile.Put()
            }
        }
    }
    else
    {
        # Creates a new page file
        if ($PSCmdlet.ShouldProcess("Page file $($CurrentPageFile.Name)", 'Delete old page file'))
        {
            $CurrentPageFile.Delete()
        }
        if ($PSCmdlet.ShouldProcess("Page file $Path", "Set initial size to $InitialSize and maximum size to $MaximumSize"))
        {
            Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{Name=$Path; InitialSize = $InitialSize; MaximumSize = $MaximumSize}
        }
    }
}

Set-PageFile -path C:\pagefile.sys -InitialSize 1000 -MaximumSize 2000

# Remove-Partition -DriveLetter D -Confirm:$false
# get-disk -Number 1 | Set-Disk –IsOffline $True

restart-computer -force



