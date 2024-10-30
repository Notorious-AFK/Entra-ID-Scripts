# Requires User Administrator for the task
# Might require higher privileges to grant consent for script authentication based on tenant configuration
#
#   Author: Notorious-AFK & AI
#
#### CSV format: ####
  # UserPrincipalName
  # user1@example.com
  # user2@example.com
  # user3@example.com

Install-Module Microsoft.Graph -Scope CurrentUser

# Import the Microsoft Graph module
Import-Module Microsoft.Graph.Users

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

# Path to the CSV file
$csvPath = "/path/to/your/file.csv"

# Import the CSV file
$users = Import-Csv -Path $csvPath

# Loop through each user in the CSV
foreach ($user in $users) {
    # Get the user by their UserPrincipalName (or another unique identifier)
    $userId = $user.UserPrincipalName

    # Disable the user by setting accountEnabled to false
    Update-MgUser -UserId $userId -AccountEnabled:$false

    Write-Output "Disabled user: $userId"
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph


