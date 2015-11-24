FROM windowsservercore:latest
RUN powershell Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; Install-Module -Name xWebAdministration,xPSDesiredStateConfiguration,cNtfsAccessControl -Force
ADD dsc /dsc
RUN powershell . C:\dsc\sfwebapp.ps1; SitefinityWebApp -ConfigurationData 'C:\dsc\sfwebapp-data.psd1' -OutputPath 'C:\dsc'
RUN powershell Start-DscConfiguration -Path 'C:\dsc' -Wait -Verbose
