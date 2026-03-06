<#
.SYNOPSIS
    Checks status of important scheduled tasks.

.DESCRIPTION
    Lists key scheduled tasks and their last run status.
    Can check for failed tasks.

.PARAMETER ShowFailed
    Show only failed tasks.

.PARAMETER TaskNames
    Comma-separated list of tasks to check. Default: common Windows tasks.

.EXAMPLE
    .\Check-ScheduledTasks.ps1

.EXAMPLE
    .\Check-ScheduledTasks.ps1 -ShowFailed
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowFailed,

    [Parameter(Mandatory=$false)]
    [string]$TaskNames = "Microsoft\Windows\Defrag,Microsoft\Windows\WindowsUpdate,Microsoft\Windows\Backup,Microsoft\Windows\DiskCleanup,Microsoft\Windows\CertificateServicesClient,Microsoft\Windows\TaskManager"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "=== Scheduled Tasks Status ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

$taskList = $TaskNames -split ","
$tasks = @()
$failed = @()

foreach ($taskName in $taskList) {
    $taskName = $taskName.Trim()
    
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if (-not $task) {
        $task = Get-ScheduledTask -TaskPath "$taskName\*" -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    
    if ($task) {
        $info = Get-ScheduledTaskInfo -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
        
        $lastResult = if ($info.LastTaskResult -eq 0) { "Success" } else { "Failed ($($info.LastTaskResult))" }
        $lastRun = if ($info.LastRunTime) { $info.LastRunTime.ToString("yyyy-MM-dd HH:mm") } else { "Never" }
        
        $status = "Ready"
        if ($task.State -eq "Disabled") { $status = "Disabled" }
        elseif ($task.State -eq "Running") { $status = "Running" }
        
        if ($info.LastTaskResult -ne 0 -and $info.LastTaskResult -ne 267011) {
            $failed += [PSCustomObject]@{
                TaskName = "$($task.TaskPath)$($task.TaskName)"
                Status   = $status
                LastRun  = $lastRun
                Result   = $lastResult
            }
        }
        
        $tasks += [PSCustomObject]@{
            TaskName = "$($task.TaskPath)$($task.TaskName)"
            Status   = $status
            LastRun  = $lastRun
            Result   = $lastResult
        }
    }
}

if ($ShowFailed -or $failed.Count -gt 0) {
    Write-Host "Failed Tasks:" -ForegroundColor Red
    
    if ($failed.Count -gt 0) {
        $failed | Format-Table -AutoSize | Out-String | Write-Host
    } else {
        Write-Host "  No failed tasks" -ForegroundColor Green
    }
} else {
    Write-Host "All Tasks:" -ForegroundColor Yellow
    $tasks | Format-Table -AutoSize | Out-String | Write-Host
}

Write-Host ""
Write-Host "Summary: $($tasks.Count) checked, $($failed.Count) failed" -ForegroundColor White

if ($failed.Count -gt 0) {
    Write-Host "RESULT:WARNING - $($failed.Count) task(s) failed" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "RESULT:OK - All tasks OK" -ForegroundColor Green
    exit 0
}
