
function Invoke-GetAzureStorageFunction{
    
    # Sign into Azure Portal
    login-azaccount

    # Fetching subscription list
    $subs = get-azsubscription

    # Fetch current working directory 
    $working_directory = "c:\AzureStorage"

    new-item $working_directory -ItemType Directory -Force

    # Fetching the IaaS inventory list for each subscription
        
    foreach($vsubs in $subs){
        $subscription_id = $vsubs.id
        $subscription_name = $vsubs.name

        if($vsubs.State -ne "Disabled"){
            Get-AzureStorage($subscription_id)
        }
        
    }

}


function Get-AzureStorage{

Param(
[String]$subscription_id
)

# Selecting the subscription
Select-azSubscription -Subscription $subscription_id

# Create a new directory with the subscription name
$path_to_store_inventory_csv_files = "c:\AzureStorage\" + $subscription_id

#Fetch the Virtual Machines from the subscription
$VMDetails = get-azvm

# Fetch the Storage Accounts from the subscription
$stgaccount = Get-azStorageAccount

# Create a new directory with the subscription name
new-item $path_to_store_inventory_csv_files -ItemType Directory -Force

# Change the directory location to store the CSV files
Set-Location -Path $path_to_store_inventory_csv_files


#####################################################################
#    Fetching Virtual Machine Details                               #
#####################################################################

    $virtual_machine_object = $null
    $virtual_machine_object = @()


    # Iterating over the Virtual Machines under the subscription
        
        foreach($VMDetails_Loop in $VMDetails){
        
        # Fetching the satus
        $vm_status = get-azvm -ResourceGroupName $VMDetails_Loop.resourcegroupname -name $VMDetails_Loop.name -Status

        #Fetching data disk names
        $data_disks = $VMDetails_Loop.StorageProfile.DataDisks
        $data_disk_name_list = ''
            foreach ($data_disks_iterator in $data_disks) {
            $data_disk_name_list_temp = $data_disk_name_list + "; " +$data_disks_iterator.name 
            
			#Trimming the first three characters which contain --> " ; "
            
			$data_disk_name_list = $data_disk_name_list_temp.Substring(2)
            
			#write-host $data_disk_name_list
            }
            
            # Fetching OS Details (Managed / un-managed)

            if($VMDetails_Loop.StorageProfile.OsDisk.manageddisk -eq $null){
                # This is un-managed disk. It has VHD property

                $os_disk_details_unmanaged = $VMDetails_Loop.StorageProfile.OsDisk.Vhd.Uri
                $os_disk_details_managed = "This VM has un-managed OS Disk"

            }
			else{
                
                $os_disk_details_managed = $VMDetails_Loop.StorageProfile.OsDisk.ManagedDisk.Id
                $os_disk_details_unmanaged = "This VM has Managed OS Disk"
            }

            $virtual_machine_object_temp = new-object PSObject 
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "ResourceGroupName" -Value $VMDetails_Loop.ResourceGroupName
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "VMName" -Value $VMDetails_Loop.Name
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "VMStatus" -Value $vm_status.Statuses[1].DisplayStatus
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "Location" -Value $VMDetails_Loop.Location
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "VMSize" -Value $VMDetails_Loop.HardwareProfile.VmSize
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "OSDisk" -Value $VMDetails_Loop.StorageProfile.OsDisk.OsType
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "OSImageType" -Value $VMDetails_Loop.StorageProfile.ImageReference.sku
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "OSVersion" -Value $VMDetails_Loop.StorageProfile.ImageReference.Sku
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "ManagedOSDiskURI" -Value $os_disk_details_managed
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "UnManagedOSDiskURI" -Value $os_disk_details_unmanaged
            $virtual_machine_object_temp | add-member -membertype NoteProperty -name "DataDiskNames" -Value $data_disk_name_list

            $virtual_machine_object += $virtual_machine_object_temp
            
        }

        $virtual_machine_object | Export-Csv "Virtual_Machine_details.csv" -NoTypeInformation -Force

#####################################################################
#    Fetching Storage Account Details                               #
#####################################################################

        $storage_account_object = $null
        $storage_account_object = @()

        foreach($AzureStgAccount in $stgaccount){
    
            # Populating the cells

            $storage_account_object_temp = new-object PSObject

            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "ResourceGroupName" -Value $AzureStgAccount.ResourceGroupName
            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "StorageAccountName" -Value $AzureStgAccount.StorageAccountName
            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "Location" -Value $AzureStgAccount.Location
            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "StorageTier" -Value $AzureStgAccount.Sku.Tier
            $storage_account_object_temp | add-member -MemberType NoteProperty -Name "ReplicationType" -Value $AzureStgAccount.Sku.Name
        
            # Setting the pointer to the next row and first column
            $storage_account_object += $storage_account_object_temp
    }

    $storage_account_object | Export-Csv "Storage_Account_Details.csv" -NoTypeInformation -Force

}
Invoke-GetAzureStorageFunction