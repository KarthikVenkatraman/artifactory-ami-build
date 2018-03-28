#############################################################################
#
# Script: win_cleanup.ps1
#
# Description: Script to clean up the image ready for others to use.
#
#############################################################################

if (!(Test-Path "C:\Aviva"))
{
	New-Item -Path C:\ -Name Aviva -ItemType Directory
}

if (!(Test-Path "C:\Aviva\Temp"))
{
	New-Item -Path C:\Aviva -Name Temp -ItemType Directory
}

$logfile = "C:\Aviva\Temp\03-cleanup.log"
"Transcript started {0}" -f (Get-Date).DateTime | Out-File $logfile

#Determine OS Version so appropriate cleanup tasks can be performed:
switch -wildcard ((Get-WmiObject Win32_OperatingSystem).Caption)
{
	"*2008*"	#Windows 2008
	{
		"Windows 2008 Detected -- running cleanup" | Out-File $logfile -Append
		$OS = "2008"
		#Cleanup Profile Usage Information
		remove-item -Path "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Recent\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
		remove-item -Path "C:\Users\Administrator\AppData\Local\Temp\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
		remove-item -path "C:\Windows\System32\sysprep\Panther\setupact.log" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
		remove-item -path "C:\Windows\System32\sysprep\Panther\setuperr.log" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
		Remove-Item -Path "C:\Windows\System32\sysprep\Panther\IE\setupact.log" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue

		#Checks License status before continuing; required for Sysprep to be successful
		foreach ($item in (gwmi SoftwareLicensingProduct))
		{
			if ($item.LicenseStatus -eq 1)
			{
				 "Windows is Licensed" | Out-File $logfile -Append
				 $licensed = $true
			}
		}

	}
	"*Server 2003*"	#Windows 2003
	{
		"Windows 2003 Detected -- running cleanup" | Out-File $logfile -Append
		$OS = "2003"
		###Run Disk Cleanup
		cleanmgr.exe /VERYLOWDISK
		Wait-Process -Name cleanmgr

		#Cleanup Profile Usage Information
		remove-item -Path "C:\Documents and Settings\Administrator\Recent\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue
		remove-item -Path "C:\Documents and Settings\Administrator\Local Settings\Temp\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue

		#Checks License status before continuing; required for Sysprep to be successful
		foreach ($item in (gwmi Win32_WindowsProductActivation))
		{
			if ($item.ActivationRequired -eq 0)
			{
				 "Windows is Licensed" | Out-File $logfile -Append
				 $licensed = $true
			}
		}
	}
	default
	{
		"No OS Match found -- using default" | Out-File $logfile -Append
		$OS = "Unknown"
		#Cleanup Profile Usage Information
		remove-item -Path "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Recent\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue

		#Checks License status before continuing; required for Sysprep to be successful
		foreach ($item in (gwmi SoftwareLicensingProduct))
		{
			if ($item.LicenseStatus -eq 1)
			{
				 "Windows is Licensed" | Out-File $logfile -Append
				 $licensed = $true
			}
		}
	}
}

"start ec2config service" | Out-File $logfile -Append
#Ensures that the service is started
start-service ec2config

#Removes Temporary Files
"remove temp files" | Out-File $logfile -Append
Write-Output "Remove temp files"
remove-item -Path "C:\Windows\Temp\*" -Force -Recurse -Confirm:$false -ErrorAction SilentlyContinue

#Removes old EC2Config Log
"remove old ec2config log" | Out-File $logfile -Append
Write-Output "Remove old ec2config log"
remove-item -Path "C:\Program Files\Amazon\Ec2ConfigService\Logs\Ec2ConfigLog.txt" -Force -Confirm:$false -ErrorAction SilentlyContinue

#Clears Start Menu Run History
"Clear start menu run history" | Out-File $logfile -Append
Write-Output "Clear start menu run history"
foreach ($item in (Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist)){Clear-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\$($item.PSChildName)\Count}

#Clears Explorer Run History
#Clear-Item -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU	#Returns error if no entries exist to clear

#Removes any previous Memory Dump files
"Removing dump files" | Out-File $logfile -Append
Write-Output "Removing dump files"
remove-item -Path "C:\Windows\*.DMP" -Force -Confirm:$false -ErrorAction SilentlyContinue
remove-item -Path "C:\Windows\Minidump" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue

#Clear IE history
"Clear IE history" | Out-File $logfile -Append
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 1
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 16
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 32

#Pre-Compiles Queued .net Assemblies prior to Sysprep
#"Pre-compile .net" | Out-File $logfile -Append
#Write-Output "Pre-compile .net. This might take a while."
#start -wait C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319\ngen.exe -ArgumentList 'executequeueditems'

#Defragments the Drive
#"defrag C:" | Out-File $logfile -Append
#Write-Output "Defrag C: This might take a while."
#defrag c:

#Securely deletes files
#"Permanently erasing deleted files" | Out-File $logfile -Append
#& 'C:\Program Files\Amazon\Ec2ConfigService\Scripts\sdelete.exe' -c -accepteula
#del 'C:\Program Files\Amazon\Ec2ConfigService\Scripts\sdelete.exe'

"Removing any mapped drives" | Out-File $logfile -Append
net use \\$RemoteIPAddress\C$ /delete /Y

#Removes any UserData Scripts
"Removing UserData scripts" | Out-File $logfile -Append
Write-Output "Removing UserData scripts"
Remove-Item -Path "C:\Program Files\Amazon\Ec2ConfigService\Scripts\UserScript.bat" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Program Files\Amazon\Ec2ConfigService\Scripts\UserScript.ps1" -Force -ErrorAction SilentlyContinue

#Resets desktop wallpaper
"Reset desktop wallpaper" | Out-File $logfile -Append
Write-Output "Reset desktop wallpaper"
Start-Process "C:\Program Files\Amazon\Ec2ConfigService\Ec2ConfigServiceSettings.exe" -ArgumentList -resetwallpaper

#############################
### Run EC2Config Service ###
"Amending ec2config config.xml" | Out-File $logfile -Append

#Gets the content of EC2Config Config.xml and enables Password Generation, UserData and DynamicVolumeSize for next boot
$EC2SettingsFile="C:\Program Files\Amazon\Ec2ConfigService\Settings\Config.xml"

$xml = [xml](get-content $EC2SettingsFile)
$xmlElement = $xml.get_DocumentElement()
$xmlElementToModify = $xmlElement.Plugins

"Setting Config.xml" | Out-File $logfile -Append
foreach ($element in $xmlElementToModify.Plugin)
{
	" $($element.name)" | Out-File $logfile -Append
	if ($element.name -eq "Ec2SetPassword")
	{
		$element.State="Enabled"
	}
	elseif ($element.name -eq "Ec2HandleUserData")
	{
		$element.State="Enabled"
	}
	elseif ($element.name -eq "AWS.EC2.Windows.CloudWatch.PlugIn")
	{
		$element.State="Enabled"
	}
	elseif ($element.name -eq "Ec2DynamicBootVolumeSize")
	{
		#Except for Windows 2003, enable dynamic Root Volume Sizing
		if ($OS -ne "2003")
		{
			$element.State="Enabled"
		}
	}
	"  $($element.State)" | Out-File $logfile -Append
}
$xml.Save($EC2SettingsFile)

"Amending bundleconfig.xml" | Out-File $logfile -Append
Write-Output "Amending bundleconfig.xml"
#Gets the content of EC2Config BundleConfig.xml and enables the RDP Cert element so new cert is generated
$EC2SettingsFile="C:\Program Files\Amazon\Ec2ConfigService\Settings\BundleConfig.xml"

$xml = [xml](get-content $EC2SettingsFile)
$xmlElement = $xml.get_DocumentElement()
$xmlElementToModify = $xmlElement.Property

"Setting BundleConfig.xml" | Out-File $logfile -Append
foreach ($element in $xmlElementToModify)
{
	" $($element.name)" | Out-File $logfile -Append
	if ($element.name -eq "SetRDPCertificate")
	{
		#For Windows 2003 OS, generates a new RDP Certificate
		if ($OS -eq "2003")
		{
			$element.Value="Yes"
		}
	}
	elseif ($element.name -eq "AutoSysprep")
	{
		$element.Value="Yes"
	}
	elseif ($element.name -eq "SetPasswordAfterSysprep")
	{
		$element.Value="Yes"
	}

	"  $($element.Value)" | Out-File $logfile -Append
}

$xmlElementToModify = $xmlElement.GeneralSettings.Sysprep

foreach ($element in $xmlElementToModify)
{
    if ($element.Switches -eq "/oobe /shutdown /generalize")
    {
        $element.Switches = "/oobe /quit /generalize"
    }
}

$xml.Save($EC2SettingsFile)

"Amending sysprep2008.xml" | Out-File $logfile -Append
Write-Output "Amending sysprep2008.xml"
# We also need to set the timezone and locale values in the EC2ConfigService sysprep2008.xml file
# so they dont get reset on sysprep
$path = "C:\Program Files\Amazon\Ec2ConfigService\sysprep2008.xml"
$timeZone = "GMT Standard Time"
$locale = "en-GB"

$xml = [xml](Get-Content $path)

$oobeSystemNode = $xml.unattend.settings | where {$_.pass -eq "oobeSystem"}
$oobeWinShellNode = $oobeSystemNode.component | where {$_.name -eq "Microsoft-Windows-Shell-Setup"}
$oobeWinShellNode.TimeZone = $timeZone
$oobeWinIntNode = $oobeSystemNode.component | where {$_.name -eq "Microsoft-Windows-International-Core"}
$oobeWinIntNode.InputLocale = $locale
$oobeWinIntNode.SystemLocale = $locale
$oobeWinIntNode.UILanguage = $locale
$oobeWinIntNode.UserLocale = $locale
$specializeNode = $xml.unattend.settings | where {$_.pass -eq "specialize"}
$specializeWinShellNode = $specializeNode.component | where {$_.name -eq "Microsoft-Windows-Shell-Setup"}
$specializeWinShellNode.TimeZone = $timeZone

$xml.Save($path)

#Clear event logs
"Clearing Event Logs" | Out-File $logfile -Append
Write-Output "Clearing Event Logs"
Clear-EventLog Application
Clear-EventLog System
Clear-EventLog Security

#Checks licensed status prior to running Sysprep
if ($licensed -eq $true)
{
	"Starting Sysprep" | Out-File $logfile -Append
	#Set-ExecutionPolicy Restricted
	#Start-Process "C:\Program Files\Amazon\Ec2ConfigService\ec2config.exe" -ArgumentList -sysprep | Out-Null

	#$regkey = "HKLM:\\System\Setup"
	#Set-ItemProperty -path $regkey CmdLine -value "powershell.exe -ExecutionPolicy Bypass -file c:\aviva\scripts\rename-server.ps1"

}
else
{
	"Windows is NOT Licensed, unable to run Sysprep" | Out-File $logfile -Append
}

"Transcript finished {0}" -f (Get-Date).DateTime | Out-File $logfile -Append
Write-Output "Finished"

Exit
