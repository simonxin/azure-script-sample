#take disk offline
Remove-Partition -DriveLetter D -Confirm:$false
get-disk -Number 1 | Set-Disk –IsOffline $True