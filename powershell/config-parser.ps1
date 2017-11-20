<#
.SYNOPSIS
    Provides reading and writing functions for configuration files.
.DESCRIPTION
    Provides a set of functions to retrieve and write configuration file content.
    Get-ConfigContent -Path <Config file> -> <Nested dictionaries> - retrieves the content of a configuration file as nested dictionaries.
    Set-ConfigContent -Path <Config file> -> void -InputObject <object> - writes the provided object to a configuration file with the standard config file structure.
    For the specification see: https://en.wikipedia.org/wiki/INI_file.

    Keep it next to your Powershell profiles.
    Link this script to the PowerShell profile directory the following way:
	> ${PSProfileDirectory} = "$(Split-Path (${Env:PSModulePath}).split(";")[0] -parent)\"
	> New-Item -ItemType SymbolicLink -Path ${PSProfileDirectory} -Name config-parser.ps1 -Value "<Path to this script>" -Force

.EXAMPLE
	TODO: fill this once finalized.
#>

# TODO: tests.

Enum DuplicateHandlings {
    Abort       = 0 # Displays an error message and aborts parsing.
    Ignore      = 1 # Displays a warning message and ignores the additional occurrences after the first value.
    Merge       = 2 # Displays a warning message and merges the occurrences to a single value.
    Override    = 3 # Displays a warning message and replaces the old value with the new value.
}

function Get-ConfigContent([System.String] ${Path}, [System.Boolean] ${IsCaseSensitive} = ${False}) {
    if (-Not [System.IO.File]::Exists(${Path})) {
        Write-Host "Error: specified file <" + ${Path} + "> does not exist"

        return ${Null}
    }

    ${lines} = Get-Content -Path "${Path}"
    ${configObject} = Read-ConfigLines -Lines ${lines} -IsCaseSensitive ${IsCaseSensitive}

    return ${configObject}
}

function Join-ConfigBrokenLines([System.String[]] ${Lines}, [System.Int] ${LineIndex}) {
    ${jointLine} = ""
    
    if (${Lines}[${LineIndex}].EndsWith('\')) {
        while (${Lines}[${LineIndex}].EndsWith('\')) {
            ${jointLine} += ${Lines}[${LineIndex}].Substring(0, ${Lines}[${LineIndex}].Length - 1)
            
            ++${LineIndex}
        }
        
        ${jointLine} += ${Lines}[${LineIndex}].Substring(0, ${Lines}[${LineIndex}].Length - 1)
    } else {
        ${jointLine} = ${Lines}[${LineIndex}]
    }

    return [System.Tuple]::Create(${LineIndex}, ${jointLine})
}

function Read-ConfigLines([System.String[]] ${Lines},
                            [System.Boolean] ${IsCaseSensitive} = ${False},
                            [DuplicateHandlings] ${SectionDuplicateHandling} = [DuplicateHandlings]::Merge,
                            [DuplicateHandlings] ${KeyDuplicateHandling} = [DuplicateHandlings]::Abort,
                            [System.Boolean] ${SuppressSectionWarnings} = ${False},
                            [System.Boolean] ${SuppressKeyWarnings} = ${False}) {
    ${configObject} = @{}
    ${currentLine} = ""
    ${currentSection} = ""
    for (${lineIndex} = 0; ${lineIndex} -lt ${Lines}.Length; ++${lineIndex}) {
        ${tuple} = Join-ConfigBrokenLines -Lines ${Lines} -LineIndex ${lineIndex}
        ${lineIndex} = ${tuple}.Item1
        ${currentLine} = ${tuple}.Item2
        ${currentLine} = Split-ConfigLineAtComment -Line ${currentLine}
        ${currentLine} = ${currentLine}.Trim()

        if (${currentLine} -eq "") { # Empty or comment-only line.
            continue
        } elseif (${currentLine}.StartsWith("[") -And
                ${currentLine}.LastIndexOf("]") -ne -1) { # Section.        
            ${currentSection} = ${currentLine}.Substring(1, ${currentLine}.LastIndexOf("]") - 1).Trim()
            ${existsAlready} = ${False}

            if (${IsCaseSensitive}) {
                ${existsAlready} = ${configObject}["${currentSection}"] -ne ${Null}
            } else {
                ${tuple} = Search-ConfigCaseInsensitiveKeys -Keys ${configObject}.Keys -SearchedKey ${currentSection}
                ${existsAlready} = ${tuple}.Item1
                
                if (${existsAlready}) {
                    ${currentSection} = ${tuple}.Item2
                }
            }

            if (-Not ${ExistsAlready}) {
                ${configObject}["${currentSection}"] = @{}
            }
        } elseif (${currentLine}.Contains("=") -And
                ${currentLine}.Split("=").Length -eq 2) { # Key-value pair.
            ${key} = ${currentLine}.Split("=")[0]
            ${value} = ${currentLine}.Split("=")[1]

            if (${IsCaseSensitive}) {
                ${existsAlready} = ${configObject}["${currentSection}"]["${key}"] -ne ${null}
            } else {
                ${tuple} = Search-ConfigCaseInsensitiveKeys -Keys ${configObject}["${currentSection}"].Keys -SearchedKey ${key}
                ${existsAlready} = ${tuple}.Item1

                if (${existsAlready}) {
                    ${key} = ${tuple}.Item2
                }
            }

            if 
        } else { # Unsupported line type.
            Write-Host "Error: invalid line among config lines at index <" + ${lineIndex}.ToString() + ">: <" + ${currentLine}.ToString() + ">"
        }
    }

    return ${configObject}
}

function Search-ConfigCaseInsensitiveKeys([System.String[]] ${Keys}, [System.String] ${SearchedKey}) {
    foreach (${key} in ${Keys}) {
        if (${key}.ToLower() -eq ${SearchedKey}.ToLower()) {
            return [System.Tuple]::Create(${True}, ${key})
        }
    }

    return [System.Tuple]::Create(${False}, ${Null})
}

function Set-ConfigContent {

}

function Split-ConfigLineAtComment([System.String] ${Line}) {
    return ${Line}.Split(@("#", ";"))[0]
}