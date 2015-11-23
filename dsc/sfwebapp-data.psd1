@{
    AllNodes = 
    @(
        @{
            NodeName = "*"
            PSDscAllowPlainTextPassword = $true    
        },
        @{
            NodeName = "localhost"
            WindowsFeatures = @("Web-Server","Web-WebServer","Web-Common-Http","Web-Http-Errors","Web-Static-Content","Web-Health","Web-Http-Logging","Web-Request-Monitor","Web-Performance","Web-Stat-Compression","Web-Dyn-Compression","Web-Security","Web-Filtering","Web-App-Dev","Web-Net-Ext45","Web-Asp-Net45","Web-ISAPI-Ext","Web-ISAPI-Filter","NET-Framework-45-Features","NET-Framework-45-Core", "NET-Framework-45-ASPNET","NET-WCF-Services45","NET-WCF-HTTP-Activation45","WAS","WAS-Process-Model","WAS-Config-APIs")
            SitefinityWebAppSource = "YourWebsiteArchiveURL"
            SitefinityWebAppRoot = "C:\Websites\SitefinityWebApp"
            SitefinityWebAppPoolName = "sitefinitywebapp"
            SitefinityWebAppSiteName = "sitefinitywebapp"
        }
    );    
}