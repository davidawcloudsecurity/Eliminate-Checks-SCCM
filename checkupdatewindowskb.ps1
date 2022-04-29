#this command pulls the KB# from the directory you put after -Path
$fruits = Get-Content -Path .\fruits.txt
#this command push the string of folder/boolean usually found in the registry if Windows need to reboot
$pendingRebootKeys = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
#this command is set to check if windows need to restart
$results = (Get-Item $pendingRebootKeys -ErrorAction SilentlyContinue).Property    
#this command set the stage for default. Assuming the patch is updated.
$nextstep = 3

#this command eats up bytes and is unneccsary but helps the user aware that the process is about to start in 5seconds.
function timer_display {
For ($i=5; $i -gt 1; $i–-) {  
    Write-Progress -Activity " " -SecondsRemaining $i
    Start-Sleep -seconds 1
}
}

#this command runs the operation DEs usually do to pull patch, run Muass and open SCCM
function push_down {
Start-Process -FilePath ".\NoSleep.exe" -Verb runAs
Start-Process -Wait -FilePath ".\gpupdateforces.bat" -Verb runAs
 
#loop for 90s just to ensure the batch file run it's course
For ($i=90; $i -gt 1; $i–-) {  
    Write-Progress -Activity " " -SecondsRemaining $i
    Start-Sleep -seconds 1
}

#if gpupdate got stuck the below will prompt user to intervene and a beep sound will alarm. the get-process is another way to check if cmd is running
#$task_list = get-process -name 'CMD' | select-object id 
if(tasklist | findstr /C:cmd) {Write-output 'Gpupdate is stuck'; [console]::beep(2000,750); Read-Host -Prompt "Resolve Gpupdate batch file"}

#I need to redo the muassh to close the batch file with the command 'exit' at the end, after it open sccm
Start-Process -FilePath ".\MUASSH.bat"  -Verb runAs

For ($i=90; $i -gt 1; $i–-) {  
    Write-Progress -Activity " " -SecondsRemaining $i
    Start-Sleep -seconds 1
}

#if muass batch got stuck. This is how it will alert the user
if(tasklist | findstr /C:cmd) {Write-output 'Muass is stuck'; [console]::beep(2000,500); Read-Host -Prompt "Resolve Gpupdate batch file"}

#this is unneccesary but will show progress bar. It constantly checks the registry if there is a need to reboot.
Do
{
#by right each update takes about 2 hours or less so this will loop for 7200 seconds and update the progress bar every 72s
for ($counter = 1; $counter -le 100; $counter++)
{
    Write-Progress -Activity "Update Progress" -Status "$counter% Complete:" -PercentComplete $counter;
    Start-Sleep -seconds 72
#this command is like the above but only collects boolean and if the above doesn't exist, the error message is ignore.
	$results = (Get-Item $pendingRebootKeys -ErrorAction SilentlyContinue).Property    
    if ($results){
    #break the for loop 
    $counter = 100
	Write-Progress -Activity "Update Progress" -Status "$counter% Complete:" -PercentComplete $counter;
	Start-Sleep -seconds 5
    }
    
}

    if (!$results){
    Write-Output 'It has been two hours, nothing is pushed down. Hold Ctrl+Break to stop program'
    }
#go through windowsupdate.log to see if string match 'failed'
    if($string = Get-WinEvent -FilterHashtable @{Providername='Microsoft-Windows-WindowsUpdateClient';Level=1,2} | Select-String -InputObject {$_.message} -Pattern 'Failed')
    {Write-Output $string; read-host -prompt 'Script detects Windows fail to update. Any key to continue or Ctrl C to stop script'
    }

}
Until ($results)
#run the loop until new keys appears in the registry.
}

#this checks the text file and compare it with the latest patch. Take note it only checks forward. It won't check backwards. If you are checking for July patch, it will show June patch. If July is patched, KB# won't show anything for June.
foreach($fruit in $fruits)
{
if (!(Get-Hotfix $fruit))
{
    Write-Output "Patch missing is $fruit"
    #sets the stage to open SCCM
    $nextstep = 1
    break
}

}
if ($results){
    #sets the stage to restart the laptop
    $nextstep = 2
}

#runs the command as mentioned above
switch ($nextstep)
{
    1 { Write-Output "$fruit is missing. Commencing patch update in 5s"; Start-Sleep -seconds 1; timer_display; push_down; Write-Output "Restart requires. Restarting in 5s"; Start-Sleep -seconds 1; timer_display; Restart-Computer -ComputerName localhost }
    2 { Write-Output "Restart requires. Restarting in 5s"; Start-Sleep -seconds 1; timer_display; Restart-Computer -ComputerName localhost -Force}
    3 { Write-Output "All patches exist. Shutdown in 5s"; Start-Sleep -seconds 2; timer_display; Stop-Computer -ComputerName localhost -Force}
}
