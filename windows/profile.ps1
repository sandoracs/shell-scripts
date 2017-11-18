<#
.SYNOPSIS
    Powershell profile.
.DESCRIPTION
    Personal PowerShell configuration profile to describe behavior of PowerShell. Similar to .profile/.bash_profile.
    
    Link this script to the PowerShell profile directory the following way:
    > ${PSProfileDirectory} = "$(Split-Path (${Env:PSModulePath}).split(";")[0] -parent)\"
    > ${PSProfileName} = "Microsoft.PowerShell_profile.ps1"
    > ${VSCodeProfileName} = "Microsoft.VSCode_profile.ps1"
    > New-Item -ItemType SymbolicLink -Path ${PSProfileDirectory} -Name ${PSProfileName} -Value "<Path to this script>" -Force
    > New-Item -ItemType SymbolicLink -Path ${PSProfileDirectory} -Name ${VSCodeProfileName} -Value "<Path to this script>" -Force

    Set the execution policy to remote signed in order to be able to load this script.
    > Set-ExecutionPolicy RemoteSigned
#>

function prompt {
    ${currentHome} = ${Home} -replace '\\', '\\' # Note: this is required though it seems like an idempotent operation, it is not.
    ${currentPath} = $($(Get-Location) -replace ${currentHome}, '~') -replace '\\', '/'

    ${dateTime} = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    ${gitBranch} = Get-GitBranch
    ${gitHash} = Get-GitHash
    #${gitStatus} = Get-GitStatus

    Write-Host "`n${dateTime}" -NoNewline
    Write-Host " ${Env:ComputerName}" -NoNewline -ForegroundColor Green
    Write-Host " ${Env:UserName}" -NoNewline -ForegroundColor Green
    Write-Host " @ " -NoNewline
    Write-Host ${currentPath} -NoNewline -ForegroundColor Cyan

    if ("${gitBranch}" -ne "") {
        Write-Host " (" -NoNewline -ForegroundColor Yellow
        Write-Host "${gitBranch} ${gitHash}" -NoNewline -ForegroundColor Yellow

        if ("${gitStatus}" -ne "") {
            Write-Host " ${gitStatus}" -NoNewline -ForegroundColor Yellow
        }
        
        Write-Host ")" -NoNewline -ForegroundColor Yellow
    }

    return "`r`n> "
}

. "${PSScriptRoot}/git-prompt.ps1"