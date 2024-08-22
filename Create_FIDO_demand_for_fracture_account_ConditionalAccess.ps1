####
# Created By: Notorious-AFK
# Date: 22-08-2024
# Description: Created Authentication strength with FIDO2 if none exist, assigns it to the "fracture@*" account using a Conditional Access Policy.
# Warning: Created using Graph Beta. Subject to change. Best effort scripting.
#
# Assumptions: Assumes FIDO-key is already registered for the Fracture account, assumes the UPN is "fracture". Assumes one singular fracture account.
# Todo: Catching FIDO2 not being enabled as a method is not tested. Error handeling generally.
#
#### Install Modules ####
Install-Module -Name Microsoft.Graph.Beta.Identity.SignIns -Force
Install-Module -Name Microsoft.Graph.Users -Force

#### Import modules ####
Import-Module -Name Microsoft.Graph.Beta.Identity.SignIns -Force
Import-Module -Name Microsoft.Graph.Users

#### Authentication ####
Connect-MgGraph -Scopes 'Policy.ReadWrite.AuthenticationMethod', 'User.Read.All', 'Policy.ReadWrite.ConditionalAccess'

#### Check for existing authentication strength policies with FIDO2 ####
$authStrengthPolicies = Get-MgBetaPolicyAuthenticationStrengthPolicy

# Filter policies that include "fido2" in their allowed combinations
$fido2Policies = $authStrengthPolicies | Where-Object { $_.AllowedCombinations -contains "fido2" }

# Check if there is a policy that only contains "fido2"
$fido2OnlyPolicy = $fido2Policies | Where-Object { $_.AllowedCombinations.Count -eq 1 -and $_.AllowedCombinations -contains "fido2" }

if ($fido2OnlyPolicy) {
    $fido2OnlyPolicy | ForEach-Object {
        Write-Output "FIDO2 is the only allowed policy in: $($_.DisplayName)"
        $authStrengthPolicyId = $_.Id
        $authStrengthDisplayName = $_.DisplayName
    }
} else {
#### Create an Authentication strength containing only FIDO2 key if none exists ####
    try{
        Write-Output "No FIDO2 Authentication Policies found. Defining a FIDO2 authentication strength"
        $newPolicy = New-MgBetaPolicyAuthenticationStrengthPolicy -DisplayName "PhysicalFIDO2" -AllowedCombinations @("fido2")
        $authStrengthPolicyId = $newPolicy.Id
        $authStrengthDisplayName = $newPolicy.DisplayName
    }
    Catch{
        Write-Output "Creating authentication strength failed probably due to FIDO2 not being a enabled MFA method. Enable manually."
        #Catching FIDO2 not being enabled is not tested
    }
}

#### Find Fracture account ID ####
$user = Get-MgUser -Filter "startsWith(UserPrincipalName,'fracture')"

#### Establish the CA Policy parameters with variables ####
$params = @{
    DisplayName = "Fracture Account FIDO2 Policy"
    State = "disabled"
    Conditions = @{
        Applications = @{
            IncludeApplications = @("All")
        }
        ClientAppTypes = @("all")
        Users = @{
            IncludeUsers = @($user.Id)
        }
    }
    GrantControls = @{
        AuthenticationStrength = @{
            Id = $authStrengthPolicyId
        }
        Operator = "OR"
    }
    SessionControls = @{
        SignInFrequency = @{
            AuthenticationType = "primaryAndSecondaryAuthentication"
            FrequencyInterval = "timeBased"
            IsEnabled = $true
            Type = "days"
            Value = 1
        }
    }
}

#### Create the Conditional Access Policy ####
New-MgBetaIdentityConditionalAccessPolicy -BodyParameter $params
Write-Output "Policy created in Disabled mode. Review before enabling. Remember to run 'Disconnect-MgGraph' to end the tenant session"
