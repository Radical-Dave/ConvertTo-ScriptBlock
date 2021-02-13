<#PSScriptInfo

.VERSION 0.0

.GUID beae9bf9-f016-416e-8443-d756a8799ff9

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell script

.LICENSEURI https://github.com/Radical-Dave/ConvertTo-ScriptBlock/blob/main/LICENSE

.PROJECTURI https://github.com/Radical-Dave/ConvertTo-ScriptBlock

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#
.SYNOPSIS
Create PowerShell Script in folder [Name]/[Name].ps1 based on template

.DESCRIPTION
Create PowerShell Script in folder [Name]/[Name].ps1 based on template
Template and Repos aka Destination path can be persisted using -PersistForCurrentUser

.EXAMPLE
PS> .\Create-Script 'name'

.EXAMPLE
PS> .\Create-Script 'name' 'template'

.EXAMPLE
PS> .\Create-Script 'name' 'template' 'd:\repos'

.EXAMPLE
PS> .\Create-Script 'name' 'template' 'd:\repos' -PersistForCurrentUser

.Link
https://github.com/radical-dave/create-script
http://www.get-powershell.com/post/2008/12/11/ConvertTo-ScriptBlock.aspx
https://techstronghold.com/scripting/@rudolfvesely/powershell-tip-convert-script-block-to-string-or-string-to-script-block/
.OUTPUTS
    System.String
#>
#####################################################
#  ConvertTo-ScriptBlock
#####################################################
[CmdletBinding(SupportsShouldProcess)]
Param(
	# Name of new script
	[Parameter(Mandatory = $false, position=0)] [string]$name,
    # Description of script [default - from template]
	[Parameter(Mandatory = $false, position=1)] [string]$description = "",
    # Name of template to use [default - template] - uses -PersisForCurrentUser
	[Parameter(Mandatory = $false, position=2)] [string]$template = "",
    # Repos path - uses PersistForCurrentUser so it can run from anywhere, otherwise uses current working directory
	[Parameter(Mandatory = $false, position=3)] [string]$repos,
	# Save repos path to env var for user
	[Parameter(Mandatory = $false)] [switch]$PersistForCurrentUser,
    # Force - overwrite if index already exists
    [Parameter(Mandatory = $false)] [switch]$Force
)
begin {
	$ErrorActionPreference = 'Stop'
	$PSScriptName = $MyInvocation.MyCommand.Name.Replace(".ps1","")
    $name = "$PSScriptName-Test"
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
    if ($PSCallingScript) { Write-Verbose "PSCallingScript:$PSCallingScript"}
	Write-Verbose "$PSScriptName $name $template"

    $scope = "User" # Machine, Process
    $eKey = "cs"
    $rKey = "repos"
    $tKey = "template"

	if (!$repos) { # is there some git cmd/setting we can use?
		$repos = [Environment]::GetEnvironmentVariable("$eKey-$rKey", $scope)
		if (!$repos) {
			Write-Verbose "repos path has NOT been persisted using -PersistForCurrentUser"
			$repos = Get-Location
		} else {
			Write-Verbose "repos path was persisted using -PersistForCurrentUser!"
		}
	}

    if (!$template) { # is there some git cmd/setting we can use?
		$template = [Environment]::GetEnvironmentVariable("$eKey-$tKey", $scope)
		if (!$repos) {
			Write-Verbose "repos path has NOT been persisted using -PersistForCurrentUser"
			$repos = Get-Location
		} else {
			Write-Verbose "repos path was persisted using -PersistForCurrentUser!"
		}
	}

    $path = Join-Path $repos $name
}
process {	
	Write-Verbose "$PSScriptName $name $template start"
	Write-Verbose "path:$path"

	#if (Test-Path $name) {
		if($PSCmdlet.ShouldProcess($name)) {
    
            if ($PersistForCurrentUser) {
                Write-Output "PersistForCurrentUser-repos:$repos,template:$template"
                [Environment]::SetEnvironmentVariable("$eKey-$rKey", $repos, $scope)
                [Environment]::SetEnvironmentVariable("$eKey-$tKey", $template, $scope)                
                if (!$name) { Exit 0 }
            }

			if (Test-Path $path) {
				if (!$Force) {
					Write-Error "ERROR $path already exists. Use -Force to overwrite."
					EXIT 1
				} else {
					Write-Verbose "$path already exist. -Force used - removing."
					Remove-Item $path -Recurse -Force | Out-Null
				}
			}

			if (!(Test-Path $path)) {
				Write-Verbose "Creating: $path"
				New-Item -Path $path -ItemType Directory | Out-Null
			}

            if (!$template) { $template = $MyInvocation.MyCommand.Path}
            Write-Verbose "template:$template"
            if (Test-Path $template) {
                $content = Get-Content $template
            } else { # pull/copy this file instead?
                $content = @"

                <#PSScriptInfo

                .VERSION 1.0
                
                .GUID @@guid@@
                
                .AUTHOR @@author@@
                
                .COMPANYNAME 
                
                .COPYRIGHT 
                
                .TAGS 
                
                .LICENSEURI 
                
                .PROJECTURI 
                
                .ICONURI 
                
                .EXTERNALMODULEDEPENDENCIES 
                
                .REQUIREDSCRIPTS 
                
                .EXTERNALSCRIPTDEPENDENCIES 
                
                .RELEASENOTES
                
                
                #>
                
                <# 
                
                .DESCRIPTION 
                @@description@@
                
                #> 
                Param()
"@
            }
            Write-Verbose "content:$content"
            $content = $content.Replace("@@guid@@", "$(New-Guid)")
            $content = $content.Replace("@@author@@", $env:USERNAME)
            $content = $content.Replace("@@description@@", $description)
            $content | Out-File Join-Path $path "$name.ps1"
        }

        Write-Verbose "$PSScriptName $name end"
        return $path
    #}
}