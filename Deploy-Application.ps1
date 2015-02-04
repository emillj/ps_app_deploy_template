<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s). 
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.EXAMPLE
	Deploy-Application.ps1
.EXAMPLE
	Deploy-Application.ps1 -DeployMode 'Silent'
.EXAMPLE
	Deploy-Application.ps1 -AllowRebootPassThru -AllowDefer
.EXAMPLE
	Deploy-Application.ps1 -DeploymentType Uninstall
.NOTES
.LINK 
	http://psappdeploytoolkit.codeplex.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')] 
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = ''
	[string]$appName = ''
	[string]$appVersion = ''
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '01/01/2015'
	[string]$appScriptAuthor = 'emil.ljungstedt@sbkf.se'
	##*===============================================
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.5.0'
	[string]$deployAppScriptDate = '11/17/2014'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -Path $moduleAppDeployToolkitMain -PathType Leaf)) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		. $moduleAppDeployToolkitMain
	}
	Catch {
		[int32]$mainExitCode = 1
		Write-Output "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message) `n$($_.InvocationInfo.PositionMessage)"
		Exit $mainExitCode
	}
	
	## Handle ServiceUI Invocation
	If ($serviceUIExitCode) { Exit-Script -ExitCode $serviceUIExitCode }
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		#Exit with error if Powerpoint Presentation is running in full screen.
	        If (Test-PowerPoint) {
            		Exit-Script -ExitCode 60500
			}
		
		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'iexplore,chrome,firefox' -BlockExecution -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Installation tasks here>
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## <Perform Installation tasks here>

        # INSTALL PROGRESS - Before every new action.
        # Show-InstallationProgress -StatusMessage "Installerar $appName $appVersion ...`nProgramfiler."

		# FOLDER - Create new
        # New-Folder -Path "c:\temp" -ContinueOnError $TRUE

        # MSI - Install msi.
        # Execute-MSI -Action Install -Path "CRRuntime_32bit_13_0_11.msi"
        # Execute-MSI -Action Install -Path "PMO Client 6.0.2.235-sve.msi" -Transform "BMA Settings.mst"
        # Execute-MSI -Action Install -Path "IncitXpand.msi" -Parameters 'PS=samsrv049 PD=sum_solvesborg_sy /QN'
        # Execute-MSI -Action Install -Path "IncitXpand.msi" -Parameters 'PS=samsrv049 PD=sum_solvesborg_sy /QB!'  # '!' in '/QB!' to eliminate cansel button.
    
        # EXE - Run exe.
        # Execute-Process -Path "vcredist_x64.exe" -Parameters "/q"

        # MSP - Install msp patch.
        # xecute-MSI -Action Patch -Path "Patch.msp" -Parameters "/passive /norestart"

        # HKCU REGISTRY - Add registry value in current user for all users.
        # [scriptblock]$HKCURegistrySettings = {
        #     Set-RegistryKey -Key 'HKCU\Software\Vendor\Application\14.0\Common' -Name 'qmenable' -Value 0 -Type DWord -SID $UserProfile.SID
        #     Set-RegistryKey -Key 'HKCU\Software\Vendor\Application\Login' -Name 'site' -Value 'logonserver_name' -Type String -SID $UserProfile.SID
        #     }
        # Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings

        # INFO DIALOG BOX - Mostly for info and/or pause during testing.
        # Show-DialogBox -Title 'Info:' -Text 'Component installation has completed. `nComponent name' -Icon 'Information'
		
        # CHECK OS ARCHITECTURE - (updated code, needs testing)
        # If ($envOSArchitecture -eq "64-bit") {
        #     Execute-MSI -Action Install -Path 'Setup_64.msi'
        #     }
        #
        # If ($envOSArchitecture -eq "32-bit") {
        #     Execute-MSI -Action Install -Path 'Setup_x86.msi'
        #     }
        
        # ZIP - Unzip to 
        # Execute-Process -Path '7za.exe' -Parameters "x $dirFiles\archive.zip -o`"$envProgramFilesX86\unzip_target_folder`" -aoa"    # (7za.exe in Files, archive.zip in Files)
        # Execute-Process -Path '7za.exe' -Parameters "x $dirSupportFiles\archive.zip -o`"$envProgramFilesX86\unzip_target_folder`" -aoa"    # (7za.exe in Files, archive.zip in SupportFiles)


        # COPY FILE - Copy file from Support Files folder.
        # Copy-File -Path "$dirSupportFiles\Application.ico" -Destination "$envProgramFilesX86\Vendor\Application\Application.ico"

        # SHORTCUT - Create shortcut.
        # New-Shortcut -Path "$envPublic\Desktop\Application.lnk" -TargetPath "$envProgramFilesX86\Vendor\Application\Application.exe" -IconLocation "$envProgramFilesX86\Vendor\Application\Application.ico" -Description "$appName $appVersion" -WorkingDirectory "$envProgramFilesX86\Vendor\Application"

        # ACL - Set access rights on folder or registry. Example gives authenticated users full rights.
        # Execute-Process -Path 'setacl.exe' -Parameters "-on `"$envProgramFiles\EDP`" -ot file -actn ace -ace `"n:S-1-5-4;p:change;s:y`""    # Authenticated users, full rights to folder.
        # Execute-Process -Path 'setacl.exe' -Parameters '-on "HKEY_LOCAL_MACHINE\Software\Classes" -ot reg -actn ace -ace "n:S-1-5-4;p:full;s:y -ignoreerr'    # Authenticated users, fill rights to registy branch.

        # KB - Test if KB is installed.
        # If (Test-MSUpdates -KBNumber 'KB3025945') {
        #     Show-InstallationPrompt -Message 'KB3025945 redan installerad. Avbryter installationen' -ButtonRightText 'OK' -Icon Information -NoWait
        #     Exit-Script -ExitCode 0 #Exit without failure
		# 	  }

        # MSU - Install MS Update.
        # Execute-Process -FilePath "$envWinDir\System32\wusa.exe" -Arguments "$dirFiles\X86-all-ie9-windows6.1-kb3025945-x86.msu /quiet /norestart" -WindowStyle Hidden



        # Remove previous version of application
        # --------------------------------------




        # Install prerequsites
        # --------------------------------------




        # Install application
        # --------------------------------------




		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>

        # Copy a file for SCCM Detection to trigger on.
        # Copy-File -Path "$dirSupportFiles\$appName_$appVersion.txt" -Destination "$envProgramFiles\$appVendor\SCCM_Detection\$appName_$appVersion.txt"

		## Display a message at the end of the install
		#Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		# <Perform Uninstallation tasks here>

        # Update Install Progress message - Before every new action.
        # Show-InstallationProgress -StatusMessage "Installerar $appName $appVersion ...`nProgramfiler."

       	# MSI, Uninstall
		# Execute-MSI -Action Uninstall -Path  '{36086086-C35D-4DBE-A994-A4C4A199A7AB}' # Avinstallerar Programnamn

        # EXE, Uninstall
        # 

        # Shortcut .lnk .url, Delete
        # Remove-File -Path 'C:\Windows\Downloaded Program Files\Temp.inf'

        # Folder, delete
        # Remove-Folder -Path "$envProgramFilesX86\Vendor\Application"


		
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 1
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}