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
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
	Deploy-Application.ps1
.EXAMPLE
	Deploy-Application.ps1 -DeployMode 'Silent'
.EXAMPLE
	Deploy-Application.ps1 -AllowRebootPassThru -AllowDefer
.EXAMPLE
	Deploy-Application.ps1 -DeploymentType Uninstall
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
        #[Parameter(Mandatory=$false)]
        #[ValidateSet('Yes','No')] 
        #[string]$CustomParam1 = 'No',
	#[Parameter(Mandatory=$false)]
	#[switch]$CustomParam2 = $false,
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false,
        [Parameter(Mandatory=$false)]
	[switch]$DebugDialogs = $false
        [Parameter(Mandatory=$false)]
	[switch]$BMA = $false,
        [Parameter(Mandatory=$false)]
	[switch]$SBG = $false
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
	[string]$appScriptDate = '08/17/2015'
	[string]$appScriptAuthor = 'emil.ljungstedt@sbkf.se'
	##*===============================================
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.5'
	[string]$deployAppScriptDate = '08/17/2015'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
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

		#Exit with error if Powerpoint Presentation is running in full screen. (emil.ljungstedt@sbkf.se 20150430)
	        If (Test-PowerPoint) {
            		Exit-Script -ExitCode 60500
			}
		
		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		#Show-InstallationWelcome -CloseApps 'iexplore, DummyApp' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		#Show-InstallationWelcome -CheckDiskSpace -PersistPrompt # (emil.ljungstedt@sbkf.se 20150518)
		
		## Show Progress Message (with the default message)
		# Show-InstallationProgress (emil.ljungstedt@sbkf.se 20150518)
		
		## <Perform Pre-Installation tasks here>
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}
		
		## <Perform Installation tasks here>

        # === EXAMPLE CODE === (emil.ljungstedt@sbkf.se 20150430)

        # INSTALL PROGRESS - Before every new action.
        # Show-InstallationProgress -StatusMessage "Installerar $appName $appVersion ...`nProgramfiler."

        # FOLDER - Create new
        # New-Folder -Path "c:\temp" -ContinueOnError $TRUE

        # MSI - Install msi.
        # Execute-MSI -Action Install -Path "application.msi"
        # Execute-MSI -Action Install -Path "application.msi" -Transform "BMA Settings.mst"
        # Execute-MSI -Action Install -Path "application.msi" -Parameters 'PS=server_alias PD=database_name /QN'
        # Execute-MSI -Action Install -Path "application.msi" -Parameters 'PS=server_alias PD=database_name /QB!'  # '!' in '/QB!' to eliminate cansel button.
    
        # EXE - Run exe.
        # Execute-Process -Path "vcredist_x64.exe" -Parameters "/q"

        # MSP - Install msp patch.
        # xecute-MSI -Action Patch -Path "Patch.msp" -Parameters "/passive /norestart"

        # HKLM REGISTRY
        # Set-RegistryKey -Key 'HKLM\Software\Vendor\Application\14.0\Common' -Name 'qmenable' -Value 0 -Type DWord #Type: 'Binary', 'DWord', 'ExpandString', 'MultiString', 'None', 'QWord', 'String', 'Unknown'

        # HKCU REGISTRY - Add registry value in current user for all users.
        # [scriptblock]$HKCURegistrySettings = {
        #     Set-RegistryKey -Key 'HKCU\Software\Vendor\Application\14.0\Common' -Name 'qmenable' -Value 0 -Type DWord -SID $UserProfile.SID
        #     Set-RegistryKey -Key 'HKCU\Software\Vendor\Application\Login' -Name 'site' -Value 'logonserver_name' -Type String -SID $UserProfile.SID
        #     Set-RegistryKey -Key 'HKCU\Software\Microsoft\Windows Live\Photo Gallery\Library' -Name 'DontShowAssociationsDialogExtensions' -Value ".WDP", ".BMP", ".JFIF", ".JPEG", ".JPE", ".JPG", ".PNG", ".TIF", ".JXR", ".DIB", ".TIFF", ".ICO" -Type MultiString -SID $UserProfile.SID
        #     }
        # Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings

        # INFO DIALOG BOX - Mostly for info and/or pause during testing.
        # Show-DialogBox -Title 'Info:' -Text "Component installation has completed. `nComponent name' -Icon 'Information"
        # or even better, use... 
        # DEBUG INFO. Enable with -DebugDialogs on the commandline
        # If ($DebugDialogs) {Show-DialogBox -Title 'Info:' -Text "Variable `$ProdID = $ProdID" }
		
        # CHECK OS ARCHITECTURE - (updated code, needs testing)
        # If ($envOSArchitecture -eq "64-bit") {
        #     Execute-MSI -Action Install -Path "Setup_64.msi"
        #     }
        #
        # If ($envOSArchitecture -eq "32-bit") {
        #     Execute-MSI -Action Install -Path "Setup_x86.msi"
        #     }
        
        # ZIP - Unzip to 
        # $unzip_target_folder="$envSystemDrive\TEMP"
        # New-Folder -Path "$envProgramFilesX86\$unzip_target_folder" -ContinueOnError $TRUE    # Create target folder
        # If ( Test-Path "$envProgramFilesX86\$unzip_target_folder" ) {
        #        Execute-Process -Path "$dirFiles\7za.exe" -Parameters "x `"$dirFiles\archive.zip`" -o`"$envProgramFilesX86\$unzip_target_folder`" -aoa"           # (7za.exe in Files, archive.zip in Files)                
        # Else {
		#        Show-DialogBox -Title 'Error:' -Text "Unzip target folder missing.`n$unzip_target_folder" -Icon "Stop"
        #        Exit-Script -ExitCode 69404
        #        }

        # COPY FILE - Copy file from Support Files folder.
        # New-Folder -Path "$envProgramFilesX86\Vendor\Application" -ContinueOnError $TRUE    # Create target folder
        # Copy-File -Path "$dirSupportFiles\Application.ico" -Destination "$envProgramFilesX86\Vendor\Application\Application.ico"

        # SHORTCUT - Create shortcut.
        # New-Shortcut -Path "$envProgramData\Microsoft\Windows\Start Menu\Application\Application.lnk" -TargetPath "$envProgramFilesX86\Vendor\Application\Application.exe" -Description "$appName $appVersion" -WorkingDirectory "$envProgramFilesX86\Vendor\Application"
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

        # FILE DELETE IN ALL PROFILES - Delete unique file from all local userprofiles
        # Execute-Process -Path "$envWinDir\system32\cmd.exe" -Parameters "/C CD $envSystemDrive\USERS &&del /S /F /Q unique_filename.INI"

        # === END OF EXAMPLE CODE ===




        # Remove previous version of application
        # --------------------------------------
        # Show-InstallationProgress -StatusMessage "Avinstallerar $appName  ...`nGamla programfiler."
        # Execute-MSI -Action Uninstall -Path  '{36086086-C35D-4DBE-A994-A4C4A199A7AB}' # Avinstallerar Programnamn
        # Remove-MSIApplications -Name 'Adobe Flash Player' # Avinstallerar msi med matchande namn.



        # Install prerequsites
        # --------------------------------------




        # Install application
        # --------------------------------------

        Show-InstallationProgress -StatusMessage "Installerar $appName $appVersion ...`nProgramfiler."

        If ($BMA) {
		If ($DebugDialogs) {Show-DialogBox -Title 'Info:' -Text "Variable `$BMA = TRUE" }
	}
	
	
	ElseIf ($SBG) {
		If ($DebugDialogs) {Show-DialogBox -Title 'Info:' -Text "Variable `$SBG = TRUE" }
	}
	
	Else {
		Show-DialogBox -Title 'Error:' -Text "Installationen måste startas med -BMA eller -SBG som argument.`n" -Icon "Stop"
            Exit-Script -ExitCode 69000
            }
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>

        	# Copy a file for SCCM Detection to trigger on. (emil.ljungstedt@sbkf.se 20150430)
                # [string]$TriggerFile = "FileName.txt"
                # [string]$TriggerPath = "$envProgramFiles\$appVendor\SCCM_Detection"
                # New-Folder -Path "$TriggerPath" -ContinueOnError $TRUE    # Create target folder
        	# Copy-File -Path "$dirFiles\$TriggerFile" -Destination "$TriggerPath\$TriggerFile"

		## Display a message at the end of the install
		# If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
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
                # [string]$TriggerFile = "FileName.txt"
                # [string]$TriggerPath = "$envProgramFiles\$appVendor\SCCM_Detection"
                # Remove file used by SCCM as trigger. (emil.ljungstedt@sbkf.se 20150519)
                If ( Test-Path "$TriggerPath\$TriggerFile" ) {
                    Remove-File -Path "$TriggerPath\$TriggerFile" -ContinueOnError $TRUE
                }
                If ( Test-Path "$TriggerPath" ) {
                    Remove-Folder -Path "$TriggerPath" -ContinueOnError $TRUE
                }
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		
		# <Perform Uninstallation tasks here>

        # === EXAMPLE CODE === (emil.ljungstedt@sbkf.se 20150430)

        # Update Install Progress message - Before every new action.
        # Show-InstallationProgress -StatusMessage "Avinstallerar $appName  ...`nProgramfiler."

       	# MSI, Uninstall
        # Execute-MSI -Action Uninstall -Path  '{36086086-C35D-4DBE-A994-A4C4A199A7AB}' # Avinstallerar Programnamn
        # Remove-MSIApplications -Name 'Adobe Flash Player' # Avinstallerar msi med matchande namn.

        # EXE, Uninstall
        # Execute-Process -Path "uninstall.exe" -Parameters "/q"

        # Shortcut .lnk .url, Delete
        # If ( Test-Path "$envProgramData\Microsoft\Windows\Start Menu\Vendor\Application.lnk" ) {
        #     Remove-File -Path "$envProgramData\Microsoft\Windows\Start Menu\Vendor\Application.lnk" -ContinueOnError $TRUE
        # }

        # Folder, delete
        # If ( Test-Path "$envProgramFilesX86\Vendor\Application" ) {
        #     Remove-Folder -Path "$envProgramFilesX86\Vendor\Application" -ContinueOnError $TRUE
        # }

        # === END OF EXAMPLE CODE ===
		
		
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
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}



# =====================
# = Toolkit Variables =
# =====================
# Toolkit Name
# $appDeployToolkitName    Short-name of toolkit without spaces
# $appDeployMainScriptFriendlyName    Full name of toolkit including spaces
#
# Script Info
# $appDeployMainScriptVersion    Version number of the toolkit
# $appDeployMainScriptMinimumConfigVersion    Minimum version of the config XML file required by the toolkit
# $appDeployMainScriptDate    Date toolkit was last modified
# $appDeployMainScriptParameters    Contains all parameters and values specified when toolkit was launched
#
# Datetime and Culture
# $currentTime    Current time when toolkit was launched
# $currentDate    Current date when toolkit was launched
# $currentTimeZoneBias    TimeZone bias based on the current date/time
# $culture    Object which contains all of the current Windows culture settings
# $currentLanguage    Current Windows two letter ISO language name (e.g. EN, FR, DE, JA etc)
#
# Environment Variables (path examples are for Windows 7 and higher)
# $envHost    Object that contains details about the current PowerShell console
# $envAllUsersProfile    %ALLUSERSPROFILE% (e.g. C:\ProgramData)
# $envAppData    %APPDATA% (e.g. C:\Users\{username}\AppData\Roaming)
# $envArchitecture    %PROCESSOR_ARCHITECTURE% (e.g. AMD64/IA64/x86) This doesn't tell you the architecture of the processor but only of the current process, so it returns "x86" for a 32-bit WOW process running on 64-bit Windows.
# $envCommonProgramFiles    %COMMONPROGRAMFILES% (e.g. C:\Program Files\Common Files)
# $envCommonProgramFilesX86    %COMMONPROGRAMFILES(x86)% (e.g. C:\Program Files (x86)\Common Files)
# $envComputerName    $COMPUTERNAME% (e.g. computer1)
# $envComputerNameFQDN    Fully qualified computer name (e.g. computer1.conto.contoso.com)
# $envHomeDrive    %HOMEDRIVE% (e.g. C:)
# $envHomePath    %HOMEPATH% (e.g. \Users\{username})
# $envHomeShare %HOMESHARE% # Used instead of HOMEDRIVE if the home directory uses UNC paths.
# $envLocalAppData    %LOCALAPPDATA% (e.g. C:\Users\{username}\AppData\Local)
# $envProgramFiles    %PROGRAMFILES% (e.g. C:\Program Files)
# $envProgramFilesX86    %ProgramFiles(x86)% (e.g. C:\Program Files (x86) # Only on 64 bit systems, is used to store 32 bit programs.
# $envProgramData    %PROGRAMDATA% (e.g. C:\ProgramData)
# $envPublic    %PUBLIC% (e.g. C:\Users\Public)
# $envSystemDrive    %SYSTEMDRIVE% (e.g. C:)
# $envSystemRoot    %SYSTEMROOT% (e.g. C:\Windows)
# $envTemp    %TEMP% (e.g. C:\Users\{Username}\AppData\Local\Temp)
# $envUserName    %USERNAME% (e.g. {username})
# $envUserProfile    %USERPROFILE% (e.g. %SystemDrive%\Users\{username})
# $envWinDir    %WINDIR% (e.g. C:\Windows)
#
# Domain Membership
# $IsMachinePartOfDomain    Is machine joined to a domain (e.g. $true/$false)
# $envMachineWorkgroup    If machine not joined to domain, what is the WORKGROUP it belongs to?
# $envMachineADDomain    Root AD domain name for machine (e.g. <name>.<suffix>.contoso.com)
# $envLogonServer    FQDN of %LOGONSERVER% used for authenticating logged in user
# $MachineDomainController    FQDN of an AD domain controller used for authentication
# $envMachineDNSDomain    Full Domain name for machine (e.g. <name>.conto.contoso.com)
# $envUserDNSDomain    %USERDNSDOMAIN%. Root AD domain name for user (e.g. <name>.<suffix>.contoso.com)
# $envUserDomain    %USERDOMAIN% (e.g. <name>.<suffix>.CONTOSO.<tld>)
#
# Operating System
# $envOS    Object that contains details about the operating system
# $envOSName    Name of the operating system (e.g. Microsoft Windows 8.1 Pro)
# $envOSServicePack    Latest service pack installed on the system (e.g. Service Pack 3)
# $envOSVersion    Full version number of the OS (e.g. {major}.{minor}.{build}.{revision})
# $envOSVersionMajor    Major portion of the OS version number (e.g. {major}.{minor}.{build}.{revision})
# $envOSVersionMinor    Minor portion of the OS version number (e.g. {major}.{minor}.{build}.{revision})
# $envOSVersionBuild    Build portion of the OS version number (e.g. {major}.{minor}.{build}.{revision})
# $envOSVersionRevision    Revision portion of the OS version number (e.g. {major}.{minor}.{build}.{revision})
# $envOSProductType    OS product type represented as an integer (e.g. 1/2/3)
# $IsServerOS    Is server OS? (e.g. $true/$false)
# $IsDomainControllerOS    Is domain controller OS? (e.g. $true/$false)
# $IsWorkStationOS    Is workstation OS? (e.g. $true/$false)
# $envOSProductTypeName    OS product type name (e.g. Server/Domain Controller/Workstation/Unknown)
# $Is64Bit    Is this a 64-bit OS? (e.g. $true/$false)
# $envOSArchitecture    Represents the OS architecture (e.g. 32-Bit/64-Bit)
#
# Current Process Architecture
# $Is64BitProcess    Is the current process 64-bits? (e.g. $true/$false)
# $psArchitecture    Represents the current process architecture (e.g. x86/x64)
#
# PowerShell And CLR (.NET) Versions
# $envPSVersionTable     Object containing PowerShell version details from PS variable $PSVersionTable
# $envPSVersion     Full version number of PS (e.g. {major}.{minor}.{build}.{revision})
# $envPSVersionMajor    Major portion of PS version number (e.g. {major}.{minor}.{build}.{revision})
# $envPSVersionMinor     Minor portion of PS version number (e.g. {major}.{minor}.{build}.{revision})
# $envPSVersionBuild    Build portion of PS version number (e.g. {major}.{minor}.{build}.{revision})
# $envPSVersionRevision     Revision portion of PS version number (e.g. {major}.{minor}.{build}.{revision})
# $envCLRVersion     Full version number of .NET used by PS (e.g. {major}.{minor}.{build}.{revision})
# $envCLRVersionMajor     Major portion of PS .NET version number (e.g. {major}.{minor}.{build}.{revision})
# $envCLRVersionMinor     Minor portion of PS .NET version number (e.g. {major}.{minor}.{build}.{revision})
# $envCLRVersionBuild     Build portion of PS .NET version number (e.g. {major}.{minor}.{build}.{revision})
# $envCLRVersionRevision    Revision portion of PS .NET version number (e.g. {major}.{minor}.{build}.{revision})
#
# Permissions/Accounts
# $CurrentProcessToken     Object that represents the current processes Windows Identity user token. Contains all details regarding user permissions.
# $CurrentProcessSID    Object that represents the current process account SID (e.g. S-1-5-32-544)
# $ProcessNTAccount     Current process NT Account (e.g. NT AUTHORITY\SYSTEM)
# $ProcessNTAccountSID     Current process account SID (e.g. S-1-5-32-544)
# $IsAdmin     Is the current process running with elevated admin privileges? (e.g. $true/$false)
# $IsLocalSystemAccount     Is the current process running under the SYSTEM account? (e.g. $true/$false)
# $IsLocalServiceAccount    Is the current process running under LOCAL SERVICE account? (e.g. $true/$false)
# $IsNetworkServiceAccount     Is the current process running under the NETWORK SERVICE account? (e.g. $true/$false)
# $IsServiceAccount    Is the current process running as a service? (e.g. $true/$false)
# $IsProcessUserInteractive     Is the current process able to display a user interface?
# $LocalSystemNTAccount     Localized NT account name of the SYSTEM account (e.g. NT AUTHORITY\SYSTEM)
# $SessionZero     Is the current process currently in session zero? In session zero isolation, process is not able to display a user interface. (e.g. $true/$false)
#
# Script Name and Script Paths
# $scriptPath     Fully qualified path of the toolkit (e.g. C:\Testing\AppDeployToolkit\AppDeployToolkitMain.ps1)
# $scriptName     Name of toolkit without file extension (e.g. AppDeployToolkitMain)
# $scriptFileName     Name of toolkit file (e.g. AppDeployToolkitMain.ps1)
# $scriptRoot      Folder that the toolkit is located in. (e.g. C:\Testing\AppDeployToolkit)
# $invokingScript     Fully qualified path of the script that invoked the toolkit (e.g. C:\Testing\Deploy-Application.ps1)
# $scriptParentPath     If toolkit was invoked by another script: contains folder that the invoking script is located in. If toolkit was not invoked by another script: contains parent folder of the toolkit.
#
# App Deploy Script Dependency Files
# $appDeployLogoIcon     Path to the logo icon file for the toolkit (e.g. $scriptRoot\AppDeployToolkitLogo.ico)
# $appDeployLogoBanner     Path to the logo banner file for the toolkit (e.g. $scriptRoot\AppDeployToolkitBanner.png)
# $appDeployConfigFile     Path to the config XML file for the toolkit (e.g. $scriptRoot\AppDeployToolkitConfig.xml)
# $appDeployToolkitDotSourceExtensions     Name of the optional extensions file for the toolkit (e.g. AppDeployToolkitExtensions.ps1)
# $xmlConfigFile     Contains the entire contents of the XML config file
# $configConfigVersion     Version number of the config XML file
# $configConfigDate     Last modified date of the config XML file
#
# Script Directories
# $dirFiles     "Files" sub-directory of the toolkit
# $dirSupportFiles     "SupportFiles" sub-directory of the toolkit
# $dirAppDeployTemp     Toolkit temp directory. Configured in XML Config file option "Toolkit_TempPath". (e.g. Toolkit_TempPath\$appDeployToolkitName)
#
# Script Naming Convention
# $appVendor     Name of the manufacturer that created the package being deployed (e.g. Microsoft)
# $appName     Name of the application being packaged (e.g. Office 2010)
# $appVersion     Version number of the application being packaged (e.g. 14.0)
# $appLang     UI language of the application being packaged (e.g. EN)
# $appRevision     Revision number of the package (e.g. 01)
# $appArch     Architecture of the application being packaged (e.g. x86/x64)
# $installTitle     Combination of the most important details about the application being packaged (e.g. "$appVendor $appName $appVersion")
# $installName     Combination of any of the following details which were provided: $appVendor + '_' + $appName + '_' + $appVersion + '_' + $appArch + '_' + $appLang + '_' + $appRevision
#
# Executables
# $exeWusa     Name of system utility that installs Standalone Windows Updates (e.g. wusa.exe)
# $exeMsiexec     Name of system utility that install Windows Installer files (e.g. msiexec.exe)
# $exeSchTasks     Path of system utility that allows management of scheduled tasks (e.g. $envWinDir\System32\schtasks.exe)
#
# RegEx Patterns
#$MSIProductCodeRegExPattern     Contains the regex pattern used to detect a MSI product code.
#
# Registry Keys
# $regKeyApplications     Array containing the path to the 32-bit and 64-bit portions of the registry that contain information about programs installed on the system. 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
# $regKeyLotusNotes     Contains the registry path that stores information about a Lotus Notes installation. 'HKLM:SOFTWARE\Lotus\Notes','HKLM:SOFTWARE\Wow6432Node\Lotus\Notes'
# $regKeyAppExecution     Contains the registry path where application execution can be blocked by configuring the ‘Debugger’ value. 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
# $regKeyDeferHistory      The path in the registry where the defer history for the package being installed is stored. "$configToolkitRegPath\$appDeployToolkitName\DeferHistory\$installName"
#
# COM Objects
# $Shell      Represents and allows use of the WScript.Shell COM object
# $ShellApp     Represents and allows use of the Shell.Application COM object
 
# Log File
# $logName      Name of the script log file: $installName + '_' + $appDeployToolkitName + '_' + $deploymentType + '.log'
# $logTempFolder     Temporary log file directory used if the option to compress log files was selected in the config XML file: $envTemp\$installName
# $logDirectory     Path to log directory defined in XML config file
# $zipFileDate     If option to zip the log files was selected, then append the current date to the zipped log file.
# $zipFileName      Path where the zipped log files will be stored: $configToolkitLogDir\$installName + '_' + $deploymentType + '_' + $zipFileDate + '.zip'
# $DisableScriptLogging     Dot source this ScriptBlock to disable logging messages to the log file.
# $RevertScriptLogging      Dot source this ScriptBlock to revert script logging back to its original setting.
#
# Script Parameters
# $deployAppScriptParameters     Non-default parameters that Deploy-Application.ps1 was launched with
# $appDeployMainScriptParameters     Non-default parameters that AppDeployToolkitMain.ps1 was launched with
# $appDeployExtScriptParameters     Non-default parameters that AppDeployToolkitExtensions.ps1 was launched with
#
# Logged On Users
# $LoggedOnUserSessions     Object that contains account and session details for all users
# $usersLoggedOn     Array that contains all of the NTAccount names of logged in users
# $CurrentLoggedOnUserSession     Object that contains account and session details for the current process if it is running as a logged in user. This is the object from $LoggedOnUserSessions where the IsCurrentSession property is $true.
# $CurrentConsoleUserSession      Objects that contains the account and session details of the console user (user with control of the physical monitor, keyboard, and mouse). This is the object from $LoggedOnUserSessions where the IsConsoleSession property is $true.
# $RunAsActiveUser     The active console user. If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user.
#
# Miscellaneous
# $dpiPixels     DPI Scale (property only exists if DPI scaling has been changed on the system at least once)
# $runningTaskSequence     Is the current process running in a SCCM task sequence? (e.g. $true/$false)
# $IsTaskSchedulerHealthy    Are the task scheduler services in a healthy state? (e.g. $true/$false)
# $invalidFileNameChars    Array of all invalid file name characters used to sanitize variables which may be used to create file names.
# $useDefaultMsi     A Zero-Config MSI installation was detected.