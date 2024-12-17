# Created By: Notorious-AFK
# Website: Hoyland.Cloud
# Date: 17-12-2024
#
# Description: 
#   A script to populate Managers to users based on a CSV file.
#
# Warning:
#   Will fail for Guests or alt-mails. Which is fine for my usecase.
#   A guest should not be a manager IMHO.
# 
# Assumptions: 
#   Input format and data for CSV is correct. "UserUPN, ManagerUPN".
#   Edit Variables to match your running env.
#
# Todo: 
#   What are all these IF statements. Feels ugly, idk.
#   Blaming Copilot for this.
#
####

# Install the Microsoft Graph module
Install-Module Microsoft.Graph -Scope CurrentUser

# Authenticate to Microsoft Graph
Disconnect-MgGraph
Connect-MgGraph -Scopes "User.ReadWrite.All"

#### CHANGE VARIABLES START ####

# CSV file containing: "UserUPN", "ManagerUPN" as headers
$filepath = "\path\to\file\user_and_manager.csv"

# Create a log file for results
$logFilePath = "\path\to\file\log.csv"

#### CHANGE VARIABLES END ####

# Import the CSV file
$users = Import-Csv -Path $filepath

# Initialize the log array
$log = @()

# Function to check if a user exists
function UserExists {
    param (
        [string]$UserUPN
    )
    try {
        $user = Get-MgUser -UserId $UserUPN -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Iterate over each row in the CSV file
foreach ($User in $Users) {
    if ($User.ManagerUPN -ne "No Manager Found" -and $User.UserUPN -ne $User.ManagerUPN) {
        if (UserExists -UserUPN $User.UserUPN) {
            if (UserExists -UserUPN $User.ManagerUPN) {
                $Manager = @{
                    "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($User.ManagerUPN)"
                }
                try {
                    Set-MgUserManagerByRef -UserId $User.UserUPN -BodyParameter $Manager
                    $result = "Successfully updated manager for user $($User.UserUPN) to $($User.ManagerUPN)"
                    Write-Output $result
                    $log += [PSCustomObject]@{
                        UserUPN = $User.UserUPN
                        ManagerUPN = $User.ManagerUPN
                        Result = $result
                    }
                } catch {
                    if ($_.Exception.Message -match "404") {
                        $result = "Manager $($User.ManagerUPN) does not exist for user $($User.UserUPN), skipping..."
                    } else {
                        $result = "Failed to update manager for user $($User.UserUPN): something went wrong"
                    }
                    Write-Output $result
                    $log += [PSCustomObject]@{
                        UserUPN = $User.UserUPN
                        ManagerUPN = $User.ManagerUPN
                        Result = $result
                    }
                }
            } else {
                $result = "Manager $($User.ManagerUPN) does not exist, skipping..."
                Write-Output $result
                $log += [PSCustomObject]@{
                    UserUPN = $User.UserUPN
                    ManagerUPN = $User.ManagerUPN
                    Result = $result
                }
            }
        } else {
            $result = "User $($User.UserUPN) does not exist, skipping..."
            Write-Output $result
            $log += [PSCustomObject]@{
                UserUPN = $User.UserUPN
                ManagerUPN = $User.ManagerUPN
                Result = $result
            }
        }
    } elseif ($User.UserUPN -eq $User.ManagerUPN) {
        $result = "User UPN and Manager UPN are the same for user $($User.UserUPN), skipping..."
        Write-Output $result
        $log += [PSCustomObject]@{
            UserUPN = $User.UserUPN
            ManagerUPN = $User.ManagerUPN
            Result = $result
        }
    } else {
        $result = "No manager found for user $($User.UserUPN), skipping..."
        Write-Output $result
        $log += [PSCustomObject]@{
            UserUPN = $User.UserUPN
            ManagerUPN = $User.ManagerUPN
            Result = $result
        }
    }
}

# Export the log to a CSV file
$log | Export-Csv -Path $logFilePath -NoTypeInformation
Write-Output "Manager field update process completed. Log written to $logFilePath."
