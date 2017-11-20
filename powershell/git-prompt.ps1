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

.NOTES
	As of the time of writing this script using the git functionality (like git rev-parse) resulted in decreased performance compared to using naked file system operations to retrieve the same information.
	Thus I have decided to retrieve the necessary information through naked file system operations instead of using the git command line tool.

.EXAMPLE
	TODO: fill this once finalized.
#>

# TODO: tests.

Enum DetachedStyles {
	Branch 		= 1	# relative to newer tag or branch (master~4)
	Contains	= 2	# relative to newer annotated tag (v1.6.3.2~35)
	Default		= 0	# exactly matching tag
	Describe	= 3	# relative to older annotated tag (v1.6.3.1-13-gdd42c2f)
	Tag			= 4	# relative to any older tag (v1.6.3.1-13-gdd42c2f)
}

. "${PSScriptRoot}/config-parser.ps1"

function Get-GitBranch([System.String] ${DetachedState} = "DETACHED") {
    if (-Not $(Test-GitDirectory)) {
        return ""
    }

    if (Test-GitHeadIsBranch) {
        ${branchReference} = $(Get-GitHead).Substring(5)
        ${branch} = Split-Path -Leaf ${branchReference}
    } else {
        ${branch} = ${DetachedState}
	}

    return "${branch}"
}

function Get-GitConfig([System.String] ${GitDirectory}) {
    if (-Not [System.IO.File]::Exists("${directory}/config")) {
		return ${Null}
	}
	
	${gitConfig} = $(Get-ConfigContent -Path "${directory}/config")

	if (${gitConfig} -eq ${Null} -Or
			${gitConfig}["core"] -eq ${Null} -Or
			${gitConfig}["core"]["repositoryformatversion"] -eq ${Null}) {
		return ${Null}
	}
	
	return ${gitConfig}
}

function Get-GitDirectory {
	${directory} = Get-Location

	while (${directory} -ne "" -And 
			-Not [System.IO.Directory]::Exists("${directory}/.git") -And
			$(Get-GitConfig ${directory}) -eq ${Null}) {	# Check bare repository.
		${directory} = Split-Path ${directory} -Parent
	}

	if (${directory} -ne "" -And
			[System.IO.Directory]::Exists("${directory}/.git")) {
		return "${directory}/.git"
	} elseif ($(Get-GitConfig -Path "${directory}/config") -ne ${Null}) {
		return "${directory}"
	}
	
	return ""
}

function Get-GitHash([System.Boolean] ${UseShortFormat} = ${True},
						[DetachedStyles] ${Style} = [DetachedStyles]::Default) {
	if (-Not $(Test-GitDirectory)) {
		return ""
    }

    if (Test-GitHeadIsBranch) {
		${gitDirectory} = Get-GitDirectory
		${branchReference} = $(Get-GitHead).Substring(5)
		${hash} = Get-Content "${gitDirectory}/${branchReference}"
    } else {
		${hash} = Get-GitHead
	}

	if (${UseShortFormat}) {
		${hash} = ${hash}.Substring(0, 7)
	}

    return "${hash}"
}

function Get-GitHead {
	if (-Not $(Test-GitDirectory)) {
        return ""
	}

	${gitDirectory} = Get-GitDirectory
	
	return $(Get-Content "${gitDirectory}/HEAD")
}

function Get-GitStatus([DetachedStyles] ${Style} = [DetachedStyles]::Default) {
	${gitStatus} = ""

	${location} = Get-Location
	${gitDirectory} = Get-GitDirectory

	if (${gitDirectory} -eq "") {
		return ""
	}

	${isBareRepository} = -Not ${gitDirectory}.Contains(".git")
	${isInsideGitDirectory} = ${location}.StartsWith(${gitDirectory})
	${isInsideWorkTree} = ${gitDirectory} -ne "" -And -Not ${isBareRepository} -And -Not ${location}.Contains(".git")
	${shortHash} = Get-GitHash -UseShortFormat ${True}

	${rebaseDirectory} = "${gitDirectory}/rebase-merge"
	
	if ([System.IO.Directory]::Exists(${rebaseDirectory})) {
		${branch} = Get-Content -Path "${rebaseDirectory}/head-name"
		${step} = Get-Content -Path "${rebaseDirectory}/msgnum"
		${total} = Get-Content -Path "${rebaseDirectory}/end"

		if ([System.IO.File]::Exists("${rebaseDirectory}/interactive")) {
			${gitStatus} += "|REBASE-interactive"
		} else {
			${gitStatus} += "|REBASE-manual"
		}
	} else {
		${rebaseApplyDirectory} = "${gitDirectory}/rebase-apply"
		
		if ([System.IO.Directory]::Exists(${rebaseApplyDirectory})) {
			${step} = Get-Content -Path "${rebaseApplyDirectory}/next"
			${total} = Get-Content -Path "${rebaseApplyDirectory}/last"

			if ([System.IO.File]::Exists("${rebaseApplyDirectory}/rebasing")) {
				${branch} = Get-Content -Path "${rebaseApplyDirectory}/head-name"
				${gitStatus} += "|REBASE"
			} elseif ([System.IO.File]::Exists("${rebaseApplyDirectory}/applying")) {
				${gitStatus} += "|AM"
			} else {
				${gitStatus} += "|AM/REBASE"
			}
		} elseif ([System.IO.File]::Exists("${gitDirectory}/MERGE_HEAD")) {
			${gitStatus} += "|MERGING"
		} elseif ([System.IO.File]::Exists("${gitDirectory}/CHERRY_PICK_HEAD")) {
			${gitStatus} += "|CHERRY-PICKING"
		} elseif ([System.IO.File]::Exists("${gitDirectory}/REVERT_HEAD")) {
			${gitStatus} += "|REVERTING"
		} elseif ([System.IO.File]::Exists("${gitDirectory}/BISECT_LOG")) {
			${gitStatus} += "|BISECTING"
		}

		if (${branch} -eq "" -And $(Test-Symlink -Path "${gitDirectory}/HEAD")) {
			# TODO: remove git usage for performance reasons.
			${branch} = $(git symbolic-ref HEAD)
		} elseif (${branch} -eq "") {
			${head} = Get-Content -Path "${gitDirectory}/HEAD"
			${branch} = ${head}.TrimStart("ref: ")

			if (${head} -eq ${branch}) {
				${isDetached} = ${True}
				
				# TODO: remove git usage for performance reasons.
				switch (${Style}) {
					[DetachedStyles]::Branch {
						${branch} = $(git describe --contains --all HEAD)
					}
					[DetachedStyles]::Contains {
						${branch} = $(git describe --contains HEAD)
					}
					[DetachedStyles]::Default {
						${branch} = $(git describe --tags --exact-match HEAD)
					}
					[DetachedStyles]::Describe {
						${branch} = $(git describe HEAD)
					}
					[DetachedStyles]::Tag {
						${branch} = $(git describe --tags HEAD)
					}
					Default {
						${branch} = $(git describe --tags --exact-match HEAD)
					}
				}

				if (${branch} -eq "") {
					${branch} = "(${shortHash}...)"
				}
			}
		}
	}

	if (${step} -ne ${Null} -And ${total} -ne ${Null}) {
		${gitStatus} += " ${step}/${total}"
	}

	# 	local w=""
	# 	local i=""
	# 	local s=""
	# 	local u=""
	# 	local c=""
	# 	local p=""

	# 	if [ "true" = "$inside_gitdir" ]; then
	# 		if [ "true" = "$bare_repo" ]; then
	# 			c="BARE:"
	# 		else
	# 			b="GIT_DIR!"
	# 		fi
	# 	elif [ "true" = "$inside_worktree" ]; then
	# 		if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] &&
	# 		[ "$(git config --bool bash.showDirtyState)" != "false" ]
	# 		then
	# 			git diff --no-ext-diff --quiet || w="*"
	# 			git diff --no-ext-diff --cached --quiet || i="+"
	# 			if [ -z "$short_sha" ] && [ -z "$i" ]; then
	# 				i="#"
	# 			fi
	# 		fi
	# 		if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ] &&
	# 		git rev-parse --verify --quiet refs/stash >/dev/null
	# 		then
	# 			s="$"
	# 		fi

	# 		if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] &&
	# 		[ "$(git config --bool bash.showUntrackedFiles)" != "false" ] &&
	# 		git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' >/dev/null 2>/dev/null
	# 		then
	# 			u="%${ZSH_VERSION+%}"
	# 		fi

	# 		if [ -n "${GIT_PS1_SHOWUPSTREAM-}" ]; then
	# 			__git_ps1_show_upstream
	# 		fi
	# 	fi

	# 	local z="${GIT_PS1_STATESEPARATOR-" "}"

	# 	# NO color option unless in PROMPT_COMMAND mode
	# 	if [ $pcmode = yes ] && [ -n "${GIT_PS1_SHOWCOLORHINTS-}" ]; then
	# 		__git_ps1_colorize_gitstring
	# 	fi

	# 	b=${b##refs/heads/}
	# 	if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
	# 		__git_ps1_branch_name=$b
	# 		b="\${__git_ps1_branch_name}"
	# 	fi

	# 	local f="$w$i$s$u"
	# 	local gitstring="$c$b${f:+$z$f}$r$p"

	# 	if [ $pcmode = yes ]; then
	# 		if [ "${__git_printf_supports_v-}" != yes ]; then
	# 			gitstring=$(printf -- "$printf_format" "$gitstring")
	# 		else
	# 			printf -v gitstring -- "$printf_format" "$gitstring"
	# 		fi
	# 		PS1="$ps1pc_start$gitstring$ps1pc_end"
	# 	else
	# 		printf -- "$printf_format" "$gitstring"
	# 	fi
}

function Get-GitRemote {
	if (-Not $(Test-GitDirectory)) {
		return ""
	}

	${upstream} = Get-GitUpstream

	if (${upstream} -eq "") {
		return ""
	}

	return Split-Path ${upstream} -Parent
}

function Get-GitUpstream {
	if (-Not $(Test-GitDirectory)) {
		return ""
	}

	# TODO: remove git usage for performance reasons.
	# read remote from config and use refs/remotes/<REMOTE>/HEAD.
	return $(git rev-parse --abbrev-ref --symbolic-full-name "@{u}")
}

function Get-GitUpstreamBranch {
	if (-Not $(Test-GitDirectory)) {
		return ""
	}

	${upstream} = Get-GitUpstream

	if (${upstream} -eq "") {
		return ""
	}

	return Split-Path ${upstream} -Leaf
}

function Get-GitUpstreamCounts([System.Boolean] ${UseLegacyCounting} = ${False}) {
	if (-Not $(Test-GitDirectory)) {
		return ${Null}
	}

	# Handling these separately is necessary, because git rev-list does not work properly when they are joint.
	${remote} = Get-GitRemote
	${upstreamBranch} = Get-GitUpstreamBranch

	${aheadCount} = 0
	${behindCount} = 0

	if (${UseLegacyCounting}) { # For older versions of Git.
		# TODO: remove git usage for performance reasons.
		${commits} = $(git rev-list --left-right ${remote}/${upstreamBranch}...HEAD)

		if (${commits} -ne "") {
			foreach (${commit} in ${commits}) {
				if (${commit[0]} -eq "<") {
					++${behindCount}
				} elseif (${commit[0]} -eq ">") {
					++${aheadCount}
				}
			}
		}
	} else {
		# TODO: remove git usage for performance reasons.
		${count} = $(git rev-list --count --left-right ${remote}/${upstreamBranch}...HEAD) -Split "\t"
		${behindCount} = [System.Convert]::ToInt64(${count}[0])
		${aheadCount} = [System.convert]::ToInt64(${count}[1])
	}

	return [System.Tuple]::Create(${behindCount}, ${aheadCount})
}

function Get-GitUpstreamStatus([System.Boolean] ${UseVerboseFormat} = ${False}, 
							[System.Boolean] ${UseName} = ${False}, 
							[System.Boolean] ${UseLegacyCounting} = ${False},
							[System.String] ${EqualMarker} = "=",
							[System.String] ${BehindMarker} = "<",
							[System.String] ${AheadMarker} = ">",
							[System.String] ${DivergedMarker} = "<>") {
	if (-Not $(Test-GitDirectory)) {
		return ""
	}

	${counts} = Get-GitUpstreamCounts -UseLegacyCounting ${UseLegacyCounting}

	if (${counts} -eq ${Null}) {
		return ""
	}

	${aheadCount} = ${counts}.Item2
	${behindCount} = ${counts}.Item1

	if (${UseVerboseFormat}) {
		${upstream} = Get-GitUpstream

		if (${behindCount} -eq 0 -And ${aheadCount} -eq 0) {
			${upstreamStatus} = "${upstream}="
		} elseif (${behindCount} -gt 0 -And ${aheadCount} -eq 0) {
			${upstreamStatus} = "${upstream}-${behindCount}"
		} elseif (${behindCount} -eq 0 -And ${aheadCount} -gt 0) {
			${upstreamStatus} = "${upstream}+${aheadCount}"
		} else {
			${upstreamStatus} = "${upstream}-${behindCount}+${aheadCount}"
		}
	} else {
		if (${behindCount} -eq 0 -And ${aheadCount} -eq 0) {
			${upstreamStatus} = ${EqualMarker}
		} elseif (${behindCount} -gt 0 -And ${aheadCount} -eq 0) {
			${upstreamStatus} = ${BehindMarker}
		} elseif (${behindCount} -eq 0 -And ${aheadCount} -gt 0) {
			${upstreamStatus} = ${AheadMarker}
		} else {
			${upstreamStatus} = ${DivergedMarker}
		}
	}

	return ${upstreamStatus}
}

function Test-GitBareRepository {
	${gitDirectory} = $(Get-GitDirectory)

	return ${gitDirectory} -ne "" -And -Not ${gitDirectory}.Contains("/.git")
}

function Test-GitDirectory {
	return $(Get-GitDirectory) -ne ""
}

function Test-GitHeadIsBranch {
	return $(Get-GitHead).StartsWith("ref: ")
}

function Test-Symlink([System.String] ${Path}) {
	if (${Path} -eq "") {
		return ${False}
	}

	${item} = Get-Item ${Path} 2>${Null}

	return ${item} -ne ${Null} -And
		${item}.Attributes -ne ${Null} -And
		${item}.Attributes.ToString() -Match "ReparsePoint"
}