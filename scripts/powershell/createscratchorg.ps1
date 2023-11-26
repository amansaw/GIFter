# Run the Salesforce CLI command to list orgs and capture the JSON output
$sfdxOrgListOutput = sf org list --verbose --json

# Parse the JSON output
$orgList = $sfdxOrgListOutput | ConvertFrom-Json

# Find the default Dev Hub alias from the JSON
$defaultDevHubAlias = $orgList.result.devHubs | Where-Object { $_.connectedStatus } | Select-Object -ExpandProperty alias

# Check if the Dev Hub is not authenticated
if (-not $defaultDevHubAlias) {
    Write-Host "Default Dev Hub is not authenticated. Please authenticate your Dev Hub first and rerun the script."
    exit 1 # Exit the script with an error code
}
else{
    Write-Host "Default Dev Hub is authenticated."

    # Generate a unique scratch org alias based on email format and current date-time
    $email = Read-Host -Prompt "Enter your email address (e.g., your.email@example.com)"
    $scratchOrgAlias = Read-Host -Prompt "Enter your Scratch Org Alias"

    # Use Git to detect the current branch as the feature branch
    $githubBranch = (git rev-parse --abbrev-ref HEAD)

    # Create a temporary directory for the deployment
    $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "DeployTemp_$githubBranch")

    # Copy the files from the current branch to the temporary directory
    Copy-Item -Path "." -Destination $tempDir.FullName -Recurse -Force

    # Create a Salesforce scratch org
    sf org create scratch --set-default --definition-file config/project-scratch-def.json -a $scratchOrgAlias --duration-days 30 --admin-email $email 

    # Install nebula Logger
    sf package install --wait 20 --security-type AdminsOnly --package 04t5Y000001Mjx5QAC

    # Push the code to the scratch org
    sf project deploy start -o $scratchOrgAlias --wait 20 --metadata-dir $tempDir.FullName

    # Assign the default user in the scratch org to this permission set
    sf org assign permset --name GIFter
    sf org assign permset --name LoggerAdmin

    # Remove the temporary directory
    Remove-Item -Path $tempDir.FullName -Recurse -Force

    # open the scratch org
    sf org open --path lightning/n/GIFter
}
