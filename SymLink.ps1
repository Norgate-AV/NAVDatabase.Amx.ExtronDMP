#!/usr/bin/env pwsh
#Requires -RunAsAdministrator

<#
 _   _                       _          ___     __
| \ | | ___  _ __ __ _  __ _| |_ ___   / \ \   / /
|  \| |/ _ \| '__/ _` |/ _` | __/ _ \ / _ \ \ / /
| |\  | (_) | | | (_| | (_| | ||  __// ___ \ V /
|_| \_|\___/|_|  \__, |\__,_|\__\___/_/   \_\_/
                 |___/

MIT License

Copyright (c) 2023 Norgate AV Services Limited

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

[CmdletBinding()]

param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ModulePath = "C:\Program Files (x86)\Common Files\AMXShare\Duet\module",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $IncludePath = "C:\Program Files (x86)\Common Files\AMXShare\AXIs",

    [Parameter(Mandatory = $false)]
    [switch]
    $Delete = $false
)

$prevPWD = $PWD
Set-Location $PSScriptRoot

try {
    $moduleFiles = Get-ChildItem -File "**/*.tko" -Recurse | Where-Object { $_.FullName -notmatch "(.git|.history|node_modules)" }
    $includeFiles = Get-ChildItem -File "**/*.axi" -Recurse | Where-Object { $_.FullName -notmatch "(.git|.history|node_modules)" }

    if (!$moduleFiles -and !$includeFiles) {
        Write-Host "No files found"
        exit 1
    }

    $ModulePath = Resolve-Path $ModulePath
    $IncludePath = Resolve-Path $IncludePath

    !$Delete ? (Write-Host "Creating symlinks...") : (Write-Host "Deleting symlinks...")

    foreach ($file in $includeFiles) {
        $linkPath = "$IncludePath/$($file.Name)"

        if ($Delete) {
            Write-Verbose "Deleting symlink: $linkPath"
            Remove-Item -Path $linkPath -Force | Out-Null
            continue
        }


        $target = $file.FullName
        Write-Verbose "Creating symlink: $linkPath -> $target"
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $target -Force | Out-Null
    }

    foreach ($file in $moduleFiles) {
        $linkPath = "$ModulePath/$($file.Name)"

        if ($Delete) {
            Write-Verbose "Deleting symlink: $linkPath"
            Remove-Item -Path $linkPath -Force | Out-Null
            continue
        }

        $target = $file.FullName
        Write-Verbose "Creating symlink: $linkPath -> $target"
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $target -Force | Out-Null
    }
}
catch {
    Write-Host $_.Exception.GetBaseException().Message -ForegroundColor Red
    exit 1
}
finally {
    Set-Location $prevPWD
}
