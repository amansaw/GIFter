# Parse the JSON output
$orgList = sf org list --verbose --json | ConvertFrom-Json

# Find the default Dev Hub alias from the JSON
$defaultDevHubAlias = $orgList.result.devHubs | Where-Object { $_.connectedStatus } | Select-Object -ExpandProperty alias

# Check if the Dev Hub is not authenticated
if (-not $defaultDevHubAlias) {
    Write-Host "Default Dev Hub is not authenticated. Please authenticate your Dev Hub first and rerun the script." -BackgroundColor red -ForegroundColor white
    exit 1 # Exit the script with an error code
}
else{
    Write-Host "Default Dev Hub is authenticated. Proceeding to create a scratch org with dev hub having alias - "$defaultDevHubAlias  -BackgroundColor green -ForegroundColor white

    # Generate a unique scratch org alias based on email format and current date-time
    $email = Read-Host -Prompt "Enter your email address (e.g., your.email@example.com)"
    $scratchOrgAlias = Read-Host -Prompt "Enter your Scratch Org Alias"

    # Use Git to detect the current branch as the feature branch
    $githubBranch = (git rev-parse --abbrev-ref HEAD)

    # Create a Salesforce scratch org
    $scratchOrgErrorCode = sf org create scratch --set-default --definition-file config/project-scratch-def.json -a $scratchOrgAlias --duration-days 30 --admin-email $email 
    if($?){
        # Install nebula Logger
        Write-Host "Installing Nebula Logger"
        sf package install -w 60 --security-type AdminsOnly --package 04t5Y000001Mjx5QAC  --no-prompt

        # Push the code to the scratch org
        sf project deploy start -o $scratchOrgAlias -w 60

        # Assign the default user in the scratch org to this permission set
        sf org assign permset --name GIFter
        sf org assign permset --name LoggerAdmin

        # open the scratch org
        sf org open --path lightning/n/GIFter

        # import data
        #sf data import tree --plan importable-data/Account-Contact-Opportunity-plan.json
    }
    else{
        Write-Host "Scratch Org cannot be created." -BackgroundColor red -ForegroundColor white
    }
}
