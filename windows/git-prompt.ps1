<#
.SYNOPSIS
    Provides Git prompt functions to enrich your PowerShell prompt.
.DESCRIPTION
    Provides a set of functions to retrieve Git related information about the current directory, including branch name, upstream status, local status, etc.
    Keep it next to your Powershell profiles.
    Link this script to the PowerShell profile directory the following way:
	> ${PSProfileDirectory} = "$(Split-Path (${Env:PSModulePath}).split(";")[0] -parent)\"
	> New-Item -ItemType SymbolicLink -Path ${PSProfileDirectory} -Name git-prompt.ps1 -Value "<Path to this script>" -Force

	Default markers:
		Local is ahead of upstream - >
		Local is behind upstream - <
		Local is equal to upstream - =
		Local has diverged from upstream - <>
		Staged changes - +
		Stashed files - $
		Unstaged changes - *
		Untracked files - %
#>

Enum DetachedStyle {
	Branch = 1		# relative to newer tag or branch (master~4)
	Contains = 2	# relative to newer annotated tag (v1.6.3.2~35)
	Default = 0		# exactly matching tag
	Describe = 3	# relative to older annotated tag (v1.6.3.1-13-gdd42c2f)
	Tag = 4			# relative to any older tag (v1.6.3.1-13-gdd42c2f)
}

function Get-GitBranch([System.String] ${DetachedState} = "DETACHED") {
    if (-Not $(Test-GitDirectory)) {
        return ""
    }

    if (Test-GitHeadIsBranch) {
        ${branchReference} = $(Get-GitHead).Substring(5)
        ${branch} = Split-Path -Leaf ${branchReference}
    }
    else {
        ${branch} = ${DetachedState}
	}

    return "${branch}"
}

function Get-GitDirectory {
	${directory} = Get-Location

	while (${directory} -ne "" -And -Not $(Test-Path "${directory}/.git")) {
		${directory} = Split-Path ${directory} -Parent
	}

	if (${directory} -ne "") {
		return "${directory}/.git"
	}
	
	return ""
}

function Get-GitHash([System.Boolean] ${UseShortFormat} = ${True},
						[DetachedStyle] ${Style} = [DetachedStyle]::Default) {
	if (-Not $(Test-GitDirectory)) {
		return ""
    }

    if (Test-GitHeadIsBranch) {
		${gitDirectory} = Get-GitDirectory
		${branchReference} = $(Get-GitHead).Substring(5)
		${hash} = Get-Content "${gitDirectory}/${branchReference}"
    }
    else {
		${hash} = Get-GitHead
	}

	if (${UseShortFormat}) {
		${hash} = ${hash}.Substring(0, 7)
	}

    return "${hash}"
}

function Get-GitHead {
	${gitDirectory} = Get-GitDirectory
	
	return $(Get-Content "${gitDirectory}/HEAD")
}

function Get-GitStatus {
    return ""
}

function Get-GitUpstream([System.Boolean] ${UseVerboseFormat} = ${False}, 
							[System.Boolean] ${UseName} = ${False}, 
							[System.Boolean] ${UseLegacyCounting} = ${False}) {	
	# verbose == ${UseVerboseFormat}
	# legacy == ${UseLegacyCounting}
	# name == ${UseName}

	${upstream} = "@{upstream}"

	if (${UseLegacyCounting}) { # For older versions of Git.
		${commits} = $(git rev-list --left-right ${upstream}...HEAD)

		if (${commits} -ne "") {
			
		}
		else {
			${behindCount} = 0
			${aheadCount} = 0
		}
	}
	else {		
		${count} = $(git rev-list --count --left-right ${upstream}...HEAD) -Split "\t"
		${behindCount} = [System.Convert]::ToInt64(${count}[0])
		${aheadCount} = [System.convert]::ToInt64(${count}[1])
	}
	
	# 		local commit behind=0 ahead=0
	# 		for commit in $commits
	# 		do
	# 			case "$commit" in
	# 			"<"*) ((behind++)) ;;
	# 			*)    ((ahead++))  ;;
	# 			esac
	# 		done
	# 		count="$behind	$ahead"
	
	# # calculate the result
	# if [[ -z "$verbose" ]]; then
	# 	case "$count" in
	# 	"") # no upstream
	# 		p="" ;;
	# 	"0	0") # equal to upstream
	# 		p="=" ;;
	# 	"0	"*) # ahead of upstream
	# 		p=">" ;;
	# 	*"	0") # behind upstream
	# 		p="<" ;;
	# 	*)	    # diverged from upstream
	# 		p="<>" ;;
	# 	esac
	# else
	# 	case "$count" in
	# 	"") # no upstream
	# 		p="" ;;
	# 	"0	0") # equal to upstream
	# 		p=" u=" ;;
	# 	"0	"*) # ahead of upstream
	# 		p=" u+${count#0	}" ;;
	# 	*"	0") # behind upstream
	# 		p=" u-${count%	0}" ;;
	# 	*)	    # diverged from upstream
	# 		p=" u+${count#*	}-${count%	*}" ;;
	# 	esac
	# 	if [[ -n "$count" && -n "$name" ]]; then
	# 		__git_ps1_upstream_name=$(git rev-parse \
	# 			--abbrev-ref "$upstream" 2>/dev/null)
	# 		if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
	# 			p="$p \${__git_ps1_upstream_name}"
	# 		else
	# 			p="$p ${__git_ps1_upstream_name}"
	# 			# not needed anymore; keep user's
	# 			# environment clean
	# 			unset __git_ps1_upstream_name
	# 		fi
	# 	fi
	# fi
}

function Test-GitDirectory {
	return $(Get-GitDirectory) -ne ""
}

function Test-GitHeadIsBranch {
	return $(Get-GitHead).StartsWith("ref: ")
}