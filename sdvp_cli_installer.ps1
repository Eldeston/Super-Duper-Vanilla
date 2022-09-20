$validAnswer = $false
$Folder = '~/AppData/Roaming/.minecraft/shaderpacks/Super-Duper-Vanilla'
#$Folder = '~/test' #for debug purposes
$host.UI.RawUI.BackgroundColor = "Black"
Clear-Host
While(-not $validAnswer)
{
    $yn = Read-Host "`nSuper Duper Vanilla Pack - Command Line Interface Installer`nDeveloped by @Eldeston, installer written by @the_steb`nPresented by Flamerender Studios`nGitHub Repository Link: https://github.com/eldeston/super-duper-vanilla`n`nHow would you like SDVP to be installed?`n`n1 - Install Stable Release`n2 - Install Development Release (NOTE: Might be very unstable but usually has newer features.)`n3 - Exit to Windows.`n`n>"
    Switch($yn.ToLower())
    {
        # Stable Release option tree
        "1" {$validAnswer = $true
        Clear-Host
        Write-Host
        Write-Host 'Super Duper Vanilla Pack - Command Line Interface Installer > Install Stable Release'
        Write-Host
        Write-Host 'Checking for existing SDVP installations...'
        Start-Sleep -Seconds 0.75
        if (Test-Path -Path $Folder) {
            # Installation check gate for stable
            $updateStable = read-host "An existing installation of SDVP was found on your shaderpacks directory. Would you like to update it or perform a clean install instead?`n`n1 - Update SDVP (Backs up shader configs)`n2 - Reinstall SDVP (Removes EVERYTHING from the SDVP folder, giving it a fresh install)`n3 - Cancel Installation and return to Windows`n`n>"

            if ($updateStable -eq 1){
                Write-Host 'Backing up shader configuration file...'
                # move-tool param here:
                Remove-Item '~\AppData\Roaming\.minecraft\shaderpacks\Super-Duper-Vanilla' -Recurse -Confirm:$false -Force
                Set-Location -Path '~/AppData/Roaming/.minecraft/shaderpacks'
                Write-Host
                Start-Sleep -Seconds 0.25
                Write-Host 'Starting update from stable channel...' -ForegroundColor Green
                Invoke-WebRequest -uri "https://github.com/Eldeston/Super-Duper-Vanilla/archive/refs/tags/v1.3.0-beta.3.zip" -OutFile ( New-Item -Path "super-duper-vanilla_stable.zip" -Force ) 
                Expand-Archive -Path 'super-duper-vanilla_stable.zip' -DestinationPath 'Super-Duper-Vanilla' -Force 
                Remove-Item 'super-duper-vanilla_stable.zip'
                Write-Host 'Super Duper Vanilla was successfully installed!' -ForegroundColor Green
                Write-Host 'Installation method: quickInstallStable'
                Write-Host
                Start-Sleep -Seconds 0.25
                Write-Host 'Press any key to exit.'
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                 exit
                 }
         else{
          # -intentionally left blank
            }
            

            if ($updateStable -eq 2){
                Write-Host 'Clearing previous versions of SDVP...'
                Remove-Item '~\AppData\Roaming\.minecraft\shaderpacks\Super-Duper-Vanilla' -Recurse -Confirm:$false -Force
                Write-Host 'shaderpacks/Super-Duper-Vanilla was wiped clean!'
                Set-Location -Path '~/AppData/Roaming/.minecraft/shaderpacks'
                Write-Host
                Start-Sleep -Seconds 0.25
                Write-Host 'Starting clean installation from stable channel...' -ForegroundColor Green
                Invoke-WebRequest -uri "https://github.com/Eldeston/Super-Duper-Vanilla/archive/refs/tags/v1.3.0-beta.3.zip" -OutFile ( New-Item -Path "super-duper-vanilla_stable.zip" -Force ) 
                Expand-Archive -Path 'super-duper-vanilla_stable.zip' -DestinationPath 'Super-Duper-Vanilla' -Force
                Remove-Item 'super-duper-vanilla_stable.zip'
                Write-Host 'Super Duper Vanilla was successfully installed!' -ForegroundColor Green
                Write-Host 'Installation method: cleanInstallStable'
                Write-Host
                Start-Sleep -Seconds 0.25
                Write-Host 'Press any key to exit.'
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                exit
            }else{
                # -intentionally left blank
            }

            if ($updateStable -eq 3){
                Write-Host 'Installation was aborted.'
                Write-Host
                Write-Host 'Press any key to exit.'
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                 exit
            }else{
            # -intentionally left blank
            }
        } 
        # If there is no previous version of SDVP present, an else statement will trigger instead.
    else {
    	Write-Host
        Write-Host "It looks like there isn't any existing installations of SDVP on this computer."
        Write-Host 'Performing quick install, buckle up!' -ForegroundColor Blue
        Set-Location -Path '~/AppData/Roaming/.minecraft/shaderpacks'
        Write-Host
        Start-Sleep -Seconds 0.25
        Write-Host 'Performing quick installation from stable channel...' -ForegroundColor Green
        Invoke-WebRequest -uri "https://github.com/Eldeston/Super-Duper-Vanilla/archive/refs/tags/v1.3.0-beta.3.zip" -OutFile ( New-Item -Path "super-duper-vanilla_stable.zip" -Force ) 
        Expand-Archive -Path 'super-duper-vanilla_stable.zip' -DestinationPath 'Super-Duper-Vanilla' -Force 
        Remove-Item 'super-duper-vanilla_stable.zip'
        Write-Host 'Super Duper Vanilla was successfully installed!' -ForegroundColor Green
        Write-Host 'Installation method: quickInstallStable'
        Write-Host
        Start-Sleep -Seconds 0.25
        Write-Host 'Press any key to exit.'
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        exit
        }
    }
            # Dev Option tree
        "2" {$validAnswer = $true
            Clear-Host
            Write-Host
            Write-Host 'Super Duper Vanilla Pack - Command Line Interface Installer > Install Dev Release'
            Write-Host
            Write-Host 'Checking for existing SDVP installations...'
        Start-Sleep -Seconds 0.75
        if (Test-Path -Path $Folder) {
            # Installation check gate for stable
            $updateDev = read-host "An existing installation of SDVP was found on your shaderpacks directory. Would you like to update it or perform a clean install instead?`n`n1 - Update SDVP (Backs up shader configs)`n2 - Reinstall SDVP (Removes EVERYTHING from the SDVP folder, giving it a fresh install)`n3 - Cancel Installation and return to Windows`n`n>"

            # If a recent installation was found, installer will trigger another read-host switch for dev
            # If user decides to update using dev:
            if ($updateDev -eq 1){
                Write-Host 'Backing up shader configuration file...'
                # move-tool param here:
                Remove-Item '~\AppData\Roaming\.minecraft\shaderpacks\Super-Duper-Vanilla' -Recurse -Confirm:$false -Force
                Set-Location -Path '~/AppData/Roaming/.minecraft/shaderpacks'
                Write-Host
                Start-Sleep -Seconds 0.25
                Write-Host 'Starting update from dev channel...' -ForegroundColor Green
                Write-Host 'NOTE: Might be unstable'
                Invoke-WebRequest -uri "https://github.com/Eldeston/Super-Duper-Vanilla/archive/refs/heads/master.zip" -OutFile ( New-Item -Path "super-duper-vanilla_dev.zip" -Force )
                Expand-Archive -Path 'super-duper-vanilla_dev.zip' -DestinationPath 'Super-Duper-Vanilla' -Force 
                Remove-Item 'super-duper-vanilla_dev.zip'
                Write-Host 'Super Duper Vanilla was successfully installed!' -ForegroundColor Green
                Write-Host 'Installation method: updateDev'
                Write-Host
                Start-Sleep -Seconds 0.25
                Write-Host 'Press any key to exit.'
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                 exit
             }else{
             # -intentionally left blank
            }
            # If user decides to clean install using dev:
            if ($updateDev -eq 2){
                Write-Host 'Clearing previous versions of SDVP...'
                Remove-Item '~\AppData\Roaming\.minecraft\shaderpacks\Super-Duper-Vanilla' -Recurse -Confirm:$false -Force 
                Write-Host 'shaderpacks/Super-Duper-Vanilla was wiped clean!'
                Set-Location -Path '~/AppData/Roaming/.minecraft/shaderpacks'
                Write-Host
                Start-Sleep -Seconds 0.25
                Write-Host 'Starting clean installation from dev channel...' -ForegroundColor Green
                Write-Host 'NOTE: Might be unstable'
                Invoke-WebRequest -uri "https://github.com/Eldeston/Super-Duper-Vanilla/archive/refs/heads/master.zip" -OutFile ( New-Item -Path "super-duper-vanilla_dev.zip" -Force ) 
                Expand-Archive -Path 'super-duper-vanilla_dev.zip' -DestinationPath 'Super-Duper-Vanilla' -Force 
                Remove-Item 'super-duper-vanilla_dev.zip'
                Write-Host 'Super Duper Vanilla was successfully installed!' -ForegroundColor Green
                Write-Host 'Installation method: cleanInstallDev'
                Write-Host
                Start-Sleep -Seconds 0.25
                Write-Host 'Press any key to exit.'
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                exit
            }else{
            # -intentionally left blank
            }
            # Aborts installation until i learn how to do backward swtches, so this stays as a workaround.
            if ($updateDev -eq 3){
                Write-Host 'Installation was aborted.'
                Write-Host
                Write-Host 'Press any key to exit.'
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                 exit
            }else{
            # -intentionally left blank
            }
        } 
    else {
        # If there is no previous version of SDVP present, an else statement will trigger instead for dev
	Write-Host
        Write-Host "It looks like there isn't any existing installations of SDVP on this computer."
        Write-Host 'Performing quick install, buckle up!' -ForegroundColor Blue
        Set-Location -Path '~/AppData/Roaming/.minecraft/shaderpacks'
        Write-Host
        Start-Sleep -Seconds 0.25
        Write-Host 'Performing quick installation from dev channel...' -ForegroundColor Green
        Invoke-WebRequest -uri "https://github.com/Eldeston/Super-Duper-Vanilla/archive/refs/heads/master.zip" -OutFile ( New-Item -Path "super-duper-vanilla_dev.zip" -Force )
        Expand-Archive -Path 'super-duper-vanilla_dev.zip' -DestinationPath 'Super-Duper-Vanilla' -Force
        Remove-Item 'super-duper-vanilla_dev.zip'
        Write-Host 'Super Duper Vanilla was successfully installed!' -ForegroundColor Green
        Write-Host 'Installation method: quickInstallDev'
        Write-Host
        Start-Sleep -Seconds 0.25
        Write-Host 'Press any key to exit.'
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        exit}
    }
            #Abort
        "3" {$validAnswer = $true
            Write-Host 'Installation was aborted.'
            Write-Host
            Write-Host 'Press any key to exit.'
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        }
        Default {
        	Clear-Host
		Write-Host "That wasn't quite right, maybe give it another shot?"}
    }
}
