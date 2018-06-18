# the script take 1 parameters: 



simonin@microsoft.com


#prepare file 
param (
[Parameter(Mandatory=$false)][string]$outputpath =  "C:\windows\temp\"
      )


function list-filesinfileshare {

param (
        [Parameter(Mandatory=$true)]
        [string]$subscriptionID,
        [Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext]$storageContext,
        [Parameter(Mandatory=$true)]
        [string]$filesharename,
        [Parameter(Mandatory=$true)]
        [string]$outputfile,
        [Parameter(Mandatory=$false)]
        [string]$path        
     )

     if ($path -ne "") {

        $files =   get-azurestoragefile -sharename $fileshare.name -Context $storageContext -path $path | get-azurestoragefile | where {$_.GetType().Name -eq "CloudFile"}    
        foreach ($file in $files) {
          $filerecord = [pscustomobject]@{
            subscriptionID=$subscriptionID;
            stname = $storageContext.StorageAccountName;
            name=$file.name;
            size=$file.Properties.length;
            fileuri=$file.uri.AbsoluteUri;
           }
             
           $filerecord | ConvertTo-Csv -Delimiter ";"  -NoTypeInformation | Select-Object -Skip 1 | Out-File -Append -Encoding ascii -FilePath $outputfile
        
        }
      
         $directories = get-azurestoragefile -sharename $fileshare.name -Context $storageContext -path $path | get-azurestoragefile | where {$_.GetType().Name -eq "CloudFileDirectory"}
         foreach ($directory in $directories) {
         $newpath = $path + '\'+ $directory.name
         write-host "query for new path: "$newpath
         list-filesinfileshare -subscriptionID $subscriptionID -storageContext $storageContext -filesharename $filesharename -outputfile $outputfile -path $newpath

         }
      } else {
        
        write-host "query on root directory"
        $files =   get-azurestoragefile -sharename $fileshare.name -Context $storageContext |  where {$_.GetType().Name -eq "CloudFile"}    
        foreach ($file in $files) {
          
            $filerecord = [pscustomobject]@{
            subscriptionID=$subscriptionID;
            stname = $storageContext.StorageAccountName;
            name=$file.name;
            size=$file.Properties.length;
            fileuri=$file.uri.AbsoluteUri;
           }
             
           $filerecord | ConvertTo-Csv -Delimiter ";"  -NoTypeInformation | Select-Object -Skip 1 | Out-File -Append -Encoding ascii -FilePath $outputfile
        
        }
        
         $directories = get-azurestoragefile -sharename $fileshare.name -Context $storageContext |  where {$_.GetType().Name -eq "CloudFileDirectory"}
         foreach ($directory in $directories) {
         $newpath = $directory.name
          write-host "query on share path: "$newpath

         list-filesinfileshare -subscriptionID $subscriptionID -storageContext $storageContext -filesharename $filesharename -outputfile $outputfile -path $newpath

         }

      }
}



if (!(Test-Path $outputpath)) {
  $filepath = (new-item $outputpath -type directory).FullName + '\'
} else {
   $filepath = (get-item $outputpath).FullName
}

Write-Host "export file path is set to "$filepath

$sharelist = $filepath+"share_"+(get-date -Format yyyyMMddHHmm).ToString()+”.csv"
$bloblist = $filepath +"blob_"+(get-date -Format yyyyMMddHHmm).ToString()+”.csv"


$fileheader = [pscustomobject]@{
            subscriptionID="subscriptionID";
            stname="storage account name";
            name="name";
            size="size";
            fileuri="fileuri";
           }
             
$fileheader | ConvertTo-Csv -Delimiter ";"  -NoTypeInformation | Select-Object -Skip 1 | Out-File -Append -Encoding ascii -FilePath $sharelist


$blobheader = [pscustomobject]@{
            subscriptionID="subscriptionID";
            stname="storage account name";
            name="name";
            size="size";
            type="blobtype"
            bloburi="bloburi";
            VM="VM name";
           }

$blobheader | ConvertTo-Csv -Delimiter ";"  -NoTypeInformation | Select-Object -Skip 1 | Out-File -Append -Encoding ascii -FilePath $bloblist




#login azure
Add-AzureRmAccount -EnvironmentName AzureChinaCloud

#go with all subs
$subs = get-azurermsubscription 

foreach ($sub in $subs) {

Set-AzureRmContext -SubscriptionId $sub.id

    
#list all azure arm storage account
$armstorages = Get-azurermStorageAccount

#polling all arm storage account
      

foreach($st in $armstorages) {
  
  $storagePrimaryKey = (Get-azurermStorageAccountKey -StorageAccountName $st.StorageAccountName -ResourceGroupName $st.ResourceGroupName)[0].Value
  $storageContext = New-azureStorageContext -StorageAccountName $st.StorageAccountName -StorageAccountKey $storagePrimaryKey
  
  #query file shares
  $fileshares = Get-AzureStorageShare -Context $storageContext -ErrorAction SilentlyContinue
  
  foreach ($fileshare in $fileshares) {
      list-filesinfileshare -subscriptionID $sub.id -storageContext $storageContext -filesharename $fileshares.name -outputfile $sharelist
  }

  #query blobs
  $containers = Get-azureStorageContainer -Context $storageContext
  foreach ($container in $containers) {
      
      $blobs = Get-azureStorageBlob -Context $storageContext -Container $Container.Name
      
      foreach ($blob in $blobs) {

      write-host "start query on blob container: "$Container.Name
      $blobrecord = [pscustomobject]@{
            subscriptionID=$sub.id;
            stname=$storageContext.StorageAccountName;
            name=$blob.name;
            size=$blob.length;
            blobtype=$blob.BlobType;
            bloburi=$blob.ICloudBlob.uri.AbsoluteUri;
            vm=$blob.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName;
           }

      $blobrecord | ConvertTo-Csv -Delimiter ";"  -NoTypeInformation | Select-Object -Skip 1 | Out-File -Append -Encoding ascii -FilePath $bloblist

      }

  }

}



#list all azure asm storage account
$asmstorages = Get-azureStorageAccount 

#polling all arm storage account

foreach($st in $asmstorages) {
  
  $storagePrimaryKey = (Get-AzureStorageKey -StorageAccountName $st.StorageAccountName).Primary
  $storageContext = New-azureStorageContext -StorageAccountName $st.StorageAccountName -StorageAccountKey $storagePrimaryKey
  
  #query file shares
  $fileshares = Get-AzureStorageShare -Context $storageContext -ErrorAction SilentlyContinue
  
  foreach ($fileshare in $fileshares) {
      list-filesinfileshare -subscriptionID $sub.id -storageContext $storageContext -filesharename $fileshares.name -outputfile $sharelist
  }

  #query blobs
  $containers = Get-azureStorageContainer -Context $storageContext
  foreach ($container in $containers) {
      
      $blobs = Get-azureStorageBlob -Context $storageContext -Container $Container.Name
      
      foreach ($blob in $blobs) {

      write-host "start query on blob container: "$Container.Name
      $blobrecord = [pscustomobject]@{
            subscriptionID=$sub.id;
            stname=$storageContext.StorageAccountName;
            name=$blob.name;
            size=$blob.length;
            blobtype=$blob.BlobType;
            bloburi=$blob.ICloudBlob.uri.AbsoluteUri;
            vm=$blob.ICloudBlob.Metadata.MicrosoftAzureCompute_VMName;
           }

      $blobrecord | ConvertTo-Csv -Delimiter ";"  -NoTypeInformation | Select-Object -Skip 1 | Out-File -Append -Encoding ascii -FilePath $bloblist

      }

  }

}

}

write-host "export blob file list to  file "$bloblist
write-host "export share file list to  file "$sharelist
