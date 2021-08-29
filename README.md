# Eliminate-Checks-SCCM
Goal is to eliminate the need to do manual checks like run sccm and reinstall failed updates from windows or restart windows if sccm had downloaded and installed windows patch update.
What this script does is it is run using powershell. It will pull data from the text file call fruits.txt. Inside lies the KB number that is required for the clients' to update. E.g. KB5005033 (August 2021 cumulative update).
It will then pull the registry for any new keys created.
Task 1. It's purpose is to shutdown the laptop if it contains the KB# installed in the get-hotfix.
Task 2. It's second purpose is to restart the client if registry contains new keys that matches the written ones.
Task 3. It's last purpose is to open and run sccm and it's related batch file and wait for KB# to be pushed down and installed. If it failed it will display error message, beep and user has to intervene. During the course of batch file process, if it gets stuck, the script will pause the script, beep and user has to intervene. 
