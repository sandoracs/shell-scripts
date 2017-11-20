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

# TODO: tests.

. "${PSScriptRoot}/git-prompt.ps1"

function Get-PromptCurrentPath {
    ${currentHome} = ${Home} -replace '\\', '\\' # Note: this is required though it seems like an idempotent operation, it is not.
    ${currentPath} = $($(Get-Location) -replace ${currentHome}, '~') -replace '\\', '/'

    return ${currentPath}
}

function Get-PromptDate {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

function Get-PromptGit {
    ${gits} = @()
    ${gits} += Get-GitBranch
    # ${gits} += Get-GitHash
    # ${gits} += Get-GitUpstreamStatus

    # ${gitString} = "("
    # foreach (${git} in ${gits}) {
    #     if (${git} -ne "") {
    #         if (${gitString} -eq "(") {
    #             ${gitString} += ${git}
    #         }
    #         else {
    #             ${gitString} += " " + ${git}
    #         }
    #     }
    # }
    # ${gitString} += ")"

    if (${gitString} -eq "()") {
        return ""
    }

    return ${gitString}
}

function prompt {
    Write-Host "`n$(Get-PromptDate)" -NoNewline
    Write-Host " ${Env:ComputerName}" -NoNewline -ForegroundColor Green
    Write-Host " ${Env:UserName}" -NoNewline -ForegroundColor Green
    Write-Host " @ " -NoNewline
    Write-Host $(Get-PromptCurrentPath) -NoNewline -ForegroundColor Cyan

    ${git} = Get-PromptGit
    if (${git} -ne "") {
        Write-Host " ${git}" -NoNewLine -ForegroundColor Yellow
    }

    return "`r`n> "
}