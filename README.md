# Introduction
This project exports Azure DevOps repositories. It uses a PowerShell script to clone all repositories in a given Azure DevOps organization and download them as ZIP files. The script is run on a schedule by an Azure Pipelines CI pipeline.

> Blog article can be found here: [https://luke.geek.nz/azure/export-azure-devops-repos-azure-storage-account/](https://luke.geek.nz/azure/export-azure-devops-repos-azure-storage-account/)

# Build and Test
To build and test this project, you need to set up an Azure Pipelines CI pipeline using the provided configuration file. The pipeline will automatically run the PowerShell script on a schedule.

# PowerShell Script
The PowerShell script, [`Export-AzDevOpsRepos.ps1`](Export-AzDevOpsRepos.ps1), is responsible for cloning all repositories in a given Azure DevOps organization and downloading them as ZIP files. It uses the Azure DevOps REST API to fetch all projects and their respective repositories. For each repository, it generates a URL to download the repository as a ZIP file and saves it to a local directory. If the script is run in an Azure Pipelines environment, it also uploads the directory containing the downloaded repositories as a pipeline artifact.

# Azure Pipelines
The Azure Pipelines configuration file, [`.azure-pipelines/pipeline.ci.adoexport.yml`](.azure-pipelines/pipeline.ci.adoexport.yml), sets up a CI pipeline that runs the PowerShell script on a schedule. The pipeline is configured to run on the latest Windows agent. It uses the Azure CLI task to run the PowerShell script and to manage access to an Azure storage account. After the script has run, the pipeline downloads any ZIP files produced as artifacts and copies them to the Azure storage account. The pipeline is scheduled to run daily at midnight.

The storage account container structure is as follows:

BUILD NAME/BUILD ID/ARTIFACT NAME (ie, AzureDevOpsExport/739/AzureDevOpsExportedRepositories)

Each new Build, will be in a different ID. Recommended to use BLob Lifecycle policies, to archive or delete old DevOps repo archives.

# Contribute
Contributions are welcome. Please submit a pull request or open an issue to discuss your proposed changes.
