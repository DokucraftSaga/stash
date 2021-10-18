#
# Minecraft Dungeons Mod Installer/Loader (DMI)
# made by LukeFZ#4035
# modified by CCCode
# with help from the Dungeoneer's Hideout server (discord.gg/Y3xZmdR)
#
# Version 2.3b (Modified)
# Changelog:
# 2.3b - Removed AppxManifest patch to make the script more reliable
# 2.3 - Patched UWPDumper to not pause on exit, now setting install location before dumping
# 2.2 - Fixed directory matching
# 2.1 - Added update mechanism

# Needed for developer mode activation, as well as folder permissions
#Requires -RunAsAdministrator

# Preparing Variables
$Package = Get-AppxPackage Microsoft.Lovika                                                                     # Game package details
$PackageFamilyName = $Package.PackageFamilyName                                                                 # Game package family name
$Location = $Package.InstallLocation                                                                            # Game install location
$Version = $Package.version                                                                                     # Installed game version
$InstalledDriveLetter = (Get-Item -Path (Get-Item -Path ${Location}\).Target).PSDrive.Name                      # Drive letter of the drive the game is installed on
$FreeSpace = (Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '${InstalledDriveLetter}:'").FreeSpace # Free space of the drive
$SystemArchitecture = [Environment]::Is64BitOperatingSystem                                                     # Variable for checking system architecture
$UWPDumper64 = "https://cdn.discordapp.com/attachments/721362545889509388/772504733289414666/UWPDumper_Patched_x64.zip" # Download URL for UWPDumper (x64)
$UWPDumper86 = "https://cdn.discordapp.com/attachments/721362545889509388/772507230859165726/UWPDumper_Patched_x86.zip" # Download URL for UWPDumper (x86)
$Extension = "https://docs.dungeonsworkshop.net/extension/extension.zip"                                        # Download URL for Vortex Extension
# $DumpLocation = "$env:localappdata\Packages\$PackageFamilyName\TempState\DUMP"                                # Location of dumped game (Redundant as of 2.3, dump location is now install location)
$TempPath = "C:\mcdtemp"                                                                                        # Temporary folder for all downloading
$Progress = 0                                                                                                   # Variable used for install folder checking
$Install                                                                                                        # User-chosen install folder
$Id                                                                                                             # Dungeons Process ID, used in dumping


if ($args[0] -eq "update") {
$FreeSpaceC = (Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = 'C:'").FreeSpace                      # Free space of the drive C, used for updating
$UpdateManifest = "https://docs.dungeonsworkshop.net/update/updatemanifest.txt"                                 # Download URL for update "manifest"
$UpdateLink                                                                                                     # Download URL for update .msixvc 
$Install = $Location                                                                                            # Game is already installed, no install folder selection
$DownloadLocation = "$TempPath\update.msixvc"                                                                   # Update file output
}

clear 

"
+---------------------+
|Dungeons Modding Tool|
|    Version 2.3b     |
| made by LukeFZ#4035 |
+---------------------+
" 
""

"Checking requirements..."

if($Package -eq $null) {                                                                                        # Check if the Package is even installed
    "You do not have the Windows Store version of Minecraft: Dungeons installed."
    "Please install it from the Store or the Xbox app, then run the script again."
    exit
}

if(($Package.IsDevelopmentMode) -and ($args[0] -ne "update")) {                                                 # IsDevelopmentMode is true for packages installed by this script,
    "Error: You already have a moddable installation of the game installed."                                    # so we can use that to check if the script is necessary.
    "If you want to update your installation instead, run this script with the 'update' argument."
    "Else, if you want to rerun this script, please reinstall Minecraft: Dungeons from the Windows Store."
    exit
}

if (!($FreeSpace -gt 8000000000)) {
    "Error: You do not have enough free space left on ${InstalledDriveLetter}:\ to continue the patching."      # Dumping + Installation on the same drive uses almost 10GB, so adding this check
    "Please free up at least 10GB of space to ensure proper installation."
    exit
}

# mkdir $TempPath -Force                                                                                        # Creating the temp. folder for all downloads
if ($args[0] -eq "update") {

    if (!($FreeSpaceC -gt 12000000000)) {
        "Error: You do not have enough free space left on C:\ to continue the patching."                        # Updating uses ~4 more GB, and we cant specify install location of msixvc.
        "Please free up at least 15GB of space to ensure proper installation."
        exit
    }


    "Downloading required update files..."                                                                      # Downloading file with latest update link & version
    Invoke-WebRequest -Uri $UpdateManifest -OutFile $TempPath\updatemanifest.txt

    $UpdateFileContent = Get-Content -Path $TempPath\updatemanifest.txt
    if (($UpdateFileContent[0] -eq $Version) -or ([version]$UpdateFileContent[0] -lt [version]$Version)) {
        "You already have the newest version of Minecraft: Dungeons installed!"
        exit
    }

    $UpdateLink = $UpdateFileContent[1]

    "Downloading update package. This can take a while depending on your internet speed!"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($UpdateLink, $DownloadLocation)

    "Finished!"

    "Backing up mods..."
    mv "$Install\Dungeons\Content\Paks\~mods" "$TempPath\~mods"

    "Uninstalling modifiable version..."
    Remove-AppxPackage $Package -AllUsers                                                                       # Removes package but not folders
    Remove-Item $install/* -Recurse                                                                             # Removes folders

    "Installing updated store version..."
    Add-AppxPackage "$TempPath/update.msixvc"                                                                   # A package format used by the store

    $Package = Get-AppxPackage Microsoft.Lovika                                                                 # Need to update for new version/package
    $Version = $Package.version

    "Finished updating process! Now continuing with the script..."
}

if ($args[0] -eq "update") {
    "Using installation folder from previous installation!"
} else {
    while($Progress -eq "0") {

        $Application = New-Object -ComObject Shell.Application
        $Install = ($Application.BrowseForFolder(0, 'Select a Folder where the game should be stored! (Do not select the root of a drive)', 0)).Self.Path # Choose a folder dialog
        if ($Install -Match "OneDrive") {                                                                       # Problematic Folder names get filtered out here
            "You have selected a folder which is stored on your OneDrive cloud."
            "You probably don't want this, so please select a different folder."
        } elseif ($Install -Match "Program Files") {
            "Your selection can cause permission problems, please select a different one."
        } elseif ($Install -eq $null) {
            "You need to make a selection to continue!"
        } else {
            $Progress = "1"
        }
        $InstalledDriveLetter = (Get-Item -Path (Get-Item -Path $Install\).Target).PSDrive.Name                  # Free space check for install drive
        $FreeSpace = (Get-WmiObject -Class Win32_logicaldisk -Filter "DeviceID = '${InstalledDriveLetter}:'").FreeSpace
        if (!($FreeSpace -gt 8000000000)) {
            "The drive you selected your folder on doesn't have enough free space available."
            "Please choose another folder on a different drive."
            $Progress = "0" 
        }
    }
}

"Enabling Developer Mode..."                                                                                    # Needed for reinstalling the package after dumping
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"

"Downloading UWPDumper..."
if ($SystemArchitecture) {                                                                                      # Detect system architecture (64 or 32) to download the right UWPDumper
    Invoke-WebRequest -Uri $UWPDumper64 -OutFile C:\mcdtemp\uwp.zip
} else {
    Invoke-WebRequest -Uri $UWPDumper86 -OutFile C:\mcdtemp\uwp.zip
}

"Unpacking UWPDumper..."
Expand-Archive -Path $TempPath\uwp.zip -DestinationPath $TempPath\uwp -Force

"Unpacking finished. Now trying to dump the game. Do not panic if it looks stuck!"
explorer.exe shell:AppsFolder\${PackageFamilyName}!Game                                                         # Can't start the game normally, so using a workaround for UWP apps
Start-Sleep -s 10

while($Id -eq $null) {
    $Id = (Get-Process Dungeons).Id
}

C:\mcdtemp\uwp\UWPInjector.exe -p $Id -d $Install                                                               # Dumping the decrypted game files
if (!(Test-Path -Path $Install\Dungeons)) {
    "Something went wrong while trying to dump the game."
    "If this error persists, report this in the Discord channel."
    exit
} else {
    "Dumping finished successfully!"
    Stop-Process -Id $Id -Force
}
clear

"
+---------------------+
|Dungeons Modding Tool|
|    Version 2.3b     |
| made by LukeFZ#4035 |
+---------------------+
" 

# Not needed anymore, as we just dump the game to the selected folder. (Made redundant in 2.3)
# "Copying game files..."
# cd $DumpLocation                                                                                              # Enter dump folder
# xcopy /T /E /g . "$Install"                                                                                   # First copy only the directory structure, prevents errors 
# xcopy /E /g . "$Install"                                                                                      # Now copy all the files, 'hopefully' prevent reencryption

"Decrypting copied game files, this can take a while!"
cd $Install
cipher /d                                                                                                       # Normally, UWP games are EFS encrypted. This + the dumping
cipher /d /S:"$Install/Dungeons"                                                                                # decrypts that

"Removing intro videos..."                                                                                      # Nobody likes the videos, so we just "remove" them
mkdir "$install\Dungeons\Content\Movies\backup"
Get-ChildItem -Path "$install\Dungeons\Content\Movies\*" -File -Exclude "loader_splash1080.mp4","dungeons_intro_1080_loop.mp4","blank_splash720.mp4" | Move-Item -Destination "$install\Dungeons\Content\Movies\backup\"

"Uninstalling original version..."
Remove-AppxPackage $Package -AllUsers                                                                           # Need to first remove the original package to install the new one

"Original version uninstalled, now installing modifiable version..."
Add-Appxpackage -Path "$install/AppxManifest.xml" -register                                                     # Installing the modifiable package with the patched AppxManifest.xml
mkdir "$install\Dungeons\Content\Paks\~mods" -Force


if ($args[0] -eq "update") {
    "Finishing update process..."
    mv $TempPath\~mods $Install\Dungeons\Content\Paks\~mods
}



"Main process finished! Now checking if Vortex is installed..."                                                 # Trying to install the Vortex Mod Manager plugin
if(Test-Path -Path "$env:appdata\Vortex\plugins")                                                               # Useful for installing NexusMods mods
{

    "Vortex detected, installing plugin..."
    Invoke-WebRequest -Uri $Extension -OutFile "C:\mcdtemp\extension.zip"
    mkdir "$env:appdata\Vortex\plugins\game-minecraftdungeons" -Force 
    Expand-Archive -Path "C:\mcdtemp\extension.zip" -DestinationPath "$env:appdata\Vortex\plugins\game-minecraftdungeons" -Force

} else {
    "Vortex not detected, skipping plugin installation!"
}

"Creating shortcut on the desktop..."
$TargetFile = "shell:AppsFolder\Microsoft.Lovika_8wekyb3d8bbwe!Game"                                            # PowerShell has no command for creating a shortcut,
$Shortcut ="$env:USERPROFILE\Desktop\Minecraft Dungeons [Modding].lnk"                                          # so we need to cheat a bit
$WScriptShell = New-Object -ComObject WScript.Shell
$ShortcutCommand = $WScriptShell.CreateShortcut($Shortcut)
$ShortcutCommand.TargetPath = $TargetFile
$ShortcutCommand.Save()

"Finished! Deleting temp. folder..."
Remove-Item $TempPath -Force -Recurse                                                                           # Cleaning up the downloads folder
clear
"
+---------------------------------------------+
|The script has finished!                     |
|You can start the game through the start menu|
|or by using the shortcut on your desktop.    |
|It has also opened the mods folder for you if|
|you want to install mods right now.          |
+---------------------------------------------+
"
Invoke-Item -Path "$install/Dungeons/Content/Paks/~mods"                                                        # Opening the ~mods folder

"To exit,press enter."
pause
exit