# sf-cntnr-poc

Containerize Sitefinity applications on Windows Server 2016 using [Docker](https://www.docker.com/). This sample is based on [Windows Containers Quick Start - Docker](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/manage_docker). The necessary configurations of the Sitefinity container are handled with Powershell DSC. Configuration catalog and its data file are located in the **dsc/** folder

## Prerequisites 

1. Windows Container Host running Windows Server 2016. I am using Azure VM created from **Windows Server 2016 Core with Containers Tech Preview 4** image, which comes with Docker pre-installed.
2. Sitefinity project connected to a database. The project's root folder must be zipped and the zip archive must be accessible from a webserver.
3. Some knowledge about using Powershell DSC to configure Windows machines

## Getting started

1. Clone the repository to your Container Host.
2. Edit the **dsc/sfwebapp-data.psd1** to provide the path to your Sitefinity site zip archive:

	```json
	SitefinityWebAppSource = "YourWebsiteArchiveURL"
	```
3. If you are using Azure VM then you will have the base container, from which the Sitefinity container will be created predefined. Double check this by running:

	```cmd
	docker images
	```
This should return a list of available images:

	REPOSITORY | TAG | IMAGE ID | CREATED | VIRTUAL SIZE
	----------------|------|-------------|-------------|-----------------
	windowsservercore | latest | 6801d964fda5 | 3 weeks ago | 0 B
	windowsservercore | 10.0.10586.0 | 6801d964fda5 | 3 weeks ago | 0 B
	
	If you will not be using the same base image, edit the **dockerfile** and change the base image:
	```
	FROM windowsservercore:latest
	```
4. Build the Sitefinity container image by running the Docker build command

	```cmd
	docker build -t <imageName> <localPathToClonedRepo>
	```
5. Before running the container you may want to make sure that Windows Firewall is not blocking communication over port 80. Use this Powershell command:

	```powershell
	if (!(Get-NetFirewallRule | where {$_.Name -eq "TCP80"})) {
	    New-NetFirewallRule -Name "TCP80" -DisplayName "HTTP on TCP/80" -protocol tcp -LocalPort 80 -Action Allow -Enabled True
	}
	```
6. Run the container using the Docker run command:

	```cmd
	docker run --name <containerName> -it -p 80:80 <imageName> cmd
	```
	This will run a new container from your specified image and open communication over port 80.
