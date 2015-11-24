Configuration SitefinityWebApp
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -ModuleName cNtfsAccessControl

    Node $AllNodes.NodeName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $false
        }
        
        #Install neccessary Windows features        
        foreach ($feature in $Node.WindowsFeatures)
        {
            WindowsFeature $feature
            {
                Ensure = "Present"
                Name = $feature
            }
        }

        #Download a package of the Sitefinity website
        xRemoteFile "SitefinityWebApp"
        {
            Uri = $Node.SitefinityWebAppSource
            DestinationPath = "$env:SystemDrive\SitefinityWebApp.zip"
        }

        #Extract the package to where the site will be ran from
        Archive "SitefinityWebApp"
        {
            Ensure = "Present"
            Path = "$env:SystemDrive\SitefinityWebApp.zip"
            Destination = $Node.SitefinityWebAppRoot
            Validate = $true
            Checksum = "SHA-256"
            Force = $true 
            DependsOn = "[xRemoteFile]SitefinityWebApp"            
        }

        #Provide application pool idenity with read permissions over site root
        cNtfsPermissionEntry RootFolderPermissions
        {
            Ensure = "Present"
            Path = $Node.SitefinityWebAppRoot
            ItemType = 'Directory'
            Principal = "NetworkService"
            DependsOn = "[Archive]SitefinityWebApp"
            AccessControlInformation =
            @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Read'
                }
            )
        }

        #Provide application pool identity with write permissions over App_Data folder
        cNtfsPermissionEntry AppDataFolderPermissions
        {
            Ensure = "Present"
            Path = [string]::Concat($Node.SitefinityWebAppRoot,"\App_Data")
            ItemType = 'Directory'
            Principal = "NetworkService"
            DependsOn = "[Archive]SitefinityWebApp"
            AccessControlInformation =
            @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                }
            )
        }

        #Remove default website
        xWebsite DefaultSite
        {
            Ensure = "Absent"
            Name = "Default Web Site"
            PhysicalPath = "C:\inetpub\wwwroot" 
        }

        #Create application pool using Script resource
        #For some reason the script resource doesnot work well with configuration data. Must be researched further
        Script CreateAppPool
        {
            SetScript = {
                $appPoolName = "SitefinityWebApp"
                New-WebAppPool -Name $appPoolName
                $appPool = Get-Item "IIS:\AppPools\$appPoolName"
                $appPool.processModel.identityType = "NetworkService"
                $appPool.processModel.idleTimeout = [TimeSpan]::FromMinutes(0)
                $appPool.processModel.idleTimeoutAction = "Suspend"
                $appPool.recycling.periodicRestart.time = [TimeSpan]::FromMinutes(0)
                $appPool.managedPipelineMode = "Integrated"
                $appPool.managedRuntimeVersion = "v4.0"
                $appPool | Set-Item
            }
            GetScript = { <# This must return a hash table #> }
            TestScript = 
            {
                Test-Path IIS:\AppPools\SitefinityWebApp
            }
        }

        #Add the Sitefinity website to IIS on port 80.
        xWebsite SitefinityWebApp
        {
            Name = $Node.SitefinityWebAppSiteName
            ApplicationPool = $Node.SitefinityWebAppPoolName
            Ensure = "Present"
            State = "Started"
            PhysicalPath = $Node.SitefinityWebAppRoot
            BindingInfo = @(
                            @(MSFT_xWebBindingInformation
                            {
                                Protocol = "HTTP"
                                Port = 80
                            })
                          )
            DependsOn = @("[Script]CreateAppPool","[xWebsite]DefaultSite", "[Archive]SitefinityWebApp")
        }
    }
}