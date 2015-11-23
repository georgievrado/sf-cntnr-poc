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
        
        foreach ($feature in $Node.WindowsFeatures)
        {
            WindowsFeature $feature
            {
                Ensure = "Present"
                Name = $feature
            }
        }

        xRemoteFile "SitefinityWebApp"
        {
            Uri = $Node.SitefinityWebAppSource
            DestinationPath = "$env:SystemDrive\SitefinityWebApp.zip"
        }

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


        xWebsite DefaultSite
        {
            Ensure = "Absent"
            Name = "Default Web Site"
            PhysicalPath = "C:\inetpub\wwwroot" 
        }

        #for some reason the script resource doesnot work well with configuration data. Must be researched further
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