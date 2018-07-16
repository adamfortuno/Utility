function Add-TestMachines {
	Param($MachineName, $InstallerDisk)

	$machine_name = c$MachineName
	machine_installer_disk = $InstallerDisk

	$hypervisor_disk_directory_default = 'C:\Hyper-V\Virtual Hard Disks\'
	$machine_disk_path = Join-Path -Path ${hypervisor_disk_directory_default} -ChildPath $machine_name
	$machine_disk_path = Join-Path -Path ${machine_disk_path} -ChildPath "${machine_name}_disk-1.vhdx"

	$machine_switch = 'sbx-ext01'
	$machine_installer_disk = $InstallerDisk

	## Creates a Dynamic Disk
	$machine_disk_os = New-VHD -Dynamic `
		-Path $machine_disk_path `
		-SizeBytes 30GB

	## Create the virtual machine
	New-VM -Name $machine_name `
		-MemoryStartupBytes 256MB `
		-Generation 2 `
		-VHDPath $machine_disk_path `
		-Path 'C:\Hyper-V\Virtual Machines' `
		-SwitchName 'sbx-ext01'

	## Add DVD Drive to Virtual Machine
	Add-VMScsiController -VMName $machine_name
	Add-VMDvdDrive -VMName $machine_name -ControllerNumber 1 -ControllerLocation 0 -Path $machine_installer_disk

	## Configure machine to Boot from ISO
	$machine_boot_device = Get-VMDvdDrive -VMName $machine_name
	Set-VMFirmware -VMName $machine_name -FirstBootDevice $machine_boot_device

	##
	Set-VMProcessor -VMName $machine_name -Count 2
}

Add-TestMachines -MachineName 'sbx-misc-app01' -InstallerDisk 'C:\Hyper-V\iso\CentOS-7-x86_64-DVD-1708.iso'
Add-TestMachines -MachineName 'sbx-misc-app02' -InstallerDisk 'C:\Hyper-V\iso\CentOS-7-x86_64-DVD-1708.iso'
Add-TestMachines -MachineName 'sbx-misc-app03' -InstallerDisk 'C:\Hyper-V\iso\CentOS-7-x86_64-DVD-1708.iso'

