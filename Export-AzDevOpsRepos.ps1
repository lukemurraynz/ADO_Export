$apiVersion = '7.1' # Update API version to 6.0

if ($env:AGENT_ID) {
    # Running in Azure DevOps
    $personalAccessToken = "$env:pat" # Assuming PAT is stored as a secret variable in the pipeline
    $organization = "$env:AzDevOpsOrg"

}
else {
    # Running on a local PC
    $personalAccessToken = ''
    $organization = ''
}

$base64AuthInfo = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($personalAccessToken)"))
$headers = @{Authorization = ("Basic {0}" -f $base64AuthInfo) }

# Get all projects
$projects = Invoke-RestMethod -Uri "https://dev.azure.com/$organization/_apis/projects?api-version=$apiVersion" -Method Get -Headers $headers -Verbose

# Output the count and names of the projects
Write-Host "Number of projects: $($projects.value.Count)"
Write-Host "Project names: $($projects.value | ForEach-Object { $_.name })"

# For each project, get all repositories and download them as zip

# Ensure the repositories directory exists before starting the loop
$repositoriesPath = "$env:SYSTEM_DEFAULTWORKINGDIRECTORY/repositories"
if (-not (Test-Path -Path $repositoriesPath)) {
    Write-Host "Creating repositories directory: $repositoriesPath"
    New-Item -ItemType Directory -Path $repositoriesPath | Out-Null
}

$projects.value | ForEach-Object {
    $projectName = $_.name

    if (-not [string]::IsNullOrWhiteSpace($projectName)) {
        $projectName = $projectName.Replace(' ', '%20')
        $result = Invoke-RestMethod -Uri "https://dev.azure.com/$organization/$projectName/_apis/git/repositories?api-version=$apiVersion" -Method Get -Headers $headers -Verbose

        $result.value | ForEach-Object {
            $repoName = $_.name
            Write-Host "Attempting to clone repository: $repoName"

            if (-not [string]::IsNullOrWhiteSpace($repoName)) {
                $repoId = $_.id
                $zipUrl = "https://dev.azure.com/$organization/$projectName/_apis/git/repositories/$repoId/items?scopePath=/&recursionLevel=Full&api-version=$apiVersion&`$format=zip"
                $outputPath = "repositories/$repoName.zip"
                Write-Host "Output path: $outputPath"
                # Ensure the directory exists before trying to download the file
                $directoryPath = Split-Path -Path $outputPath -Parent
                if (-not (Test-Path -Path $directoryPath)) {
                    Write-Host "Creating directory: $directoryPath"
                    New-Item -ItemType Directory -Path $directoryPath | Out-Null
                }
                try {
                    Write-Host "Starting download for $repoName from $zipUrl"
                    Invoke-WebRequest -Uri $zipUrl -OutFile $outputPath -Headers $headers
                    Write-Host "Download completed for $repoName"
                }
                catch {
                    Write-Host "Failed to download $repoName from $zipUrl"
                    Write-Host $_.Exception.Message
                }
            }
        }
    }
}

# Check if the repositories directory exists before trying to upload it
if (Test-Path -Path "$env:SYSTEM_DEFAULTWORKINGDIRECTORY/repositories") {
    Write-Host "Repositories directory exists, uploading as artifact"
    Write-Host "##vso[artifact.upload containerfolder=repositories;artifactname=AzureDevOpsExportedRepositories;]$env:SYSTEM_DEFAULTWORKINGDIRECTORY/repositories"
}
else {
    Write-Host "Repositories directory does not exist, cannot upload as artifact"
}
