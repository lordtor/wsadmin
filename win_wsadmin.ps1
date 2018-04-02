#!powershell
# This file is part of Ansible
# Copyright (c) 2017 Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#Requires -Module Ansible.ModuleUtils.Legacy.psm1
#Requires -Module Ansible.ModuleUtils.CommandUtil.psm1
Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

# Cleanse CLIXML from stderr (sift out error stream data, discard others for now)
Function Cleanse-Stderr($raw_stderr) {
    Try {
        # NB: this regex isn't perfect, but is decent at finding CLIXML amongst other stderr noise
        If($raw_stderr -match "(?s)(?<prenoise1>.*)#< CLIXML(?<prenoise2>.*)(?<clixml><Objs.+</Objs>)(?<postnoise>.*)") {
            $clixml = [xml]$matches["clixml"]

            $merged_stderr = "{0}{1}{2}{3}" -f @(
               $matches["prenoise1"],
               $matches["prenoise2"],
               # filter out just the Error-tagged strings for now, and zap embedded CRLF chars
               ($clixml.Objs.ChildNodes | ? { $_.Name -eq 'S' } | ? { $_.S -eq 'Error' } | % { $_.'#text'.Replace('_x000D__x000A_','') } | Out-String),
               $matches["postnoise"]) | Out-String

            return $merged_stderr.Trim()

            # FUTURE: parse/return other streams
        }
        Else {
            $raw_stderr
        }
    }
    Catch {
        "***EXCEPTION PARSING CLIXML: $_***" + $raw_stderr
    }
}

$params = Parse-Args $args -supports_check_mode $false
$wasdir = Get-AnsibleParam -obj $params -name "wasdir" -type "str" -failifempty $true
$washost =   Get-AnsibleParam -obj $params -name "washost" -type "str" -default ""
$wasport =    Get-AnsibleParam -obj $params -name "wasport" -type "str" -default ""
$conntype =  Get-AnsibleParam -obj $params -name "conntype" -type "str" -default ""
$lang =     Get-AnsibleParam -obj $params -name "lang" -type "str" -default "jython"
$was_params = Get-AnsibleParam -obj $params -name "was_params" -type "str" -default ""
$tracefile = Get-AnsibleParam -obj $params -name "tracefile" -type "str" -default ""
$username =  Get-AnsibleParam -obj $params -name "username" -type "str" -default ""
$d = -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
[Environment]::SetEnvironmentVariable($d, (Get-AnsibleParam -obj $params -name "password" -type "str"  -default ""),"Process")
$script =   Get-AnsibleParam -obj $params -name "script" -type "str" -default ""
$script_params =  Get-AnsibleParam -obj $params -name "script_params" -type "str" -default ""
$was_command =  Get-AnsibleParam -obj $params -name "was_command" -type "str" -default ""
$accept_cert = Get-AnsibleParam -obj $params -name "accept_cert" -type "bool" -default $false
If ([Environment]::GetEnvironmentVariable($d)){
        $new_password = " -password `%"+$d+"`% "
}Else{
    $new_password = ""
}
$argument = ""
IF ($script -ne "" -and $was_command -ne ""){
    Fail-Json -obj $result -message "Use only one parameter script or command"
}Else{
    $argument = ""
    If ($script -ne ""){
        $argument = " -f "+ $script + $script_params
    }
    If ($was_command -ne ""){
        $argument = " -c "+ $was_command
    }
}
If ($username -ne ""){ $username = " -username " +$username  + " " }
If ($conntype -ne ""){ $conntype = " -conntype " +$conntype  + " " }
If ($lang -ne ""){ $lang = " -lang " +$lang  + " " }Else{ $lang = " -lang jython " }
If ($washost -ne ""){ $washost = " -host  " + $washost + " " }
If ($wasport -ne ""){ $wasport = " -port " + $wasport + " " }
If ($tracefile -ne ""){ $tracefile = " -tracefile " + $tracefile  + " " }
If ($accept_cert -ne $true){
    If ($new_password -ne "")
    {
        $raw_command_line = "wsadmin.bat " + $lang + $conntype + $washost + $wasport + $was_params + $username + $new_password + $tracefile + $argument
    }    Else {
        $raw_command_line = "wsadmin.bat " + $lang + $conntype + $washost + $wasport + $was_params + $username + $tracefile + $argument
    }
}Else{
        $raw_command_line = "echo yes| wsadmin.bat " + $lang + $conntype + $washost + $wasport + $was_params + $argument
}

$raw_command_line = $raw_command_line.Trim()
If($wasdir -and -not $(Test-Path $wasdir)) {Exit-Json @{msg="Error, since $wasdir not exists";cmd=$raw_command_line;changed=$false;skipped=$false;rc=1} }
$result = @{
    changed = $true
    cmd = $raw_command_line
}
$exec_application = "cmd"
if (-not ($exec_application.EndsWith(".exe"))) {
    $exec_application = "$($exec_application).exe"
}
$exec_args = "/c $raw_command_line"
$command = "$exec_application $exec_args"
$start_datetime = [DateTime]::UtcNow
try {
    $command_result = Run-Command -command $command -working_directory $wasdir
    [Environment]::SetEnvironmentVariable($d,'',"Process")
} catch {
    $result.changed = $false
    [Environment]::SetEnvironmentVariable($d,'',"Process")
    try {
        $result.rc = $_.Exception.NativeErrorCode
    } catch {
        $result.rc = 2
    }
    Fail-Json -obj $result -message $_.Exception.Message
}
$result.stdout = $command_result.stdout
$result.stderr = Cleanse-Stderr $command_result.stderr
$result.rc = $command_result.rc
$end_datetime = [DateTime]::UtcNow
$result.start = $start_datetime.ToString("yyyy-MM-dd hh:mm:ss.ffffff")
$result.end = $end_datetime.ToString("yyyy-MM-dd hh:mm:ss.ffffff")
$result.delta = $($end_datetime - $start_datetime).ToString("h\:mm\:ss\.ffffff")
If ($result.rc -ne 0) {
    [Environment]::SetEnvironmentVariable($d,'',"Process")
    Fail-Json -obj $result -message "non-zero return code"
}

Exit-Json $result
