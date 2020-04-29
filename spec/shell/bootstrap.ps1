# Variables
$role=$args[0]

# Configure PowerShell Execution Policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

#########################################################
#########################################################
$installLatestBeta = $true
# OR install a version directly
#$env:chocolateyVersion="0.9.10-beta-20160402"
#$env:chocolateyVersion="0.9.8.33"
$installLocalFile = $false
$localChocolateyPackageFilePath = 'c:\packages\chocolatey.0.10.0.nupkg'

$ChocoInstallPath = "$($env:SystemDrive)\ProgramData\Chocolatey\bin"
$env:ChocolateyInstall = "$($env:SystemDrive)\ProgramData\Chocolatey"
$env:Path += ";$ChocoInstallPath"
$DebugPreference = "Continue";
$env:ChocolateyEnvironmentDebug = 'true'

# PowerShell will not set this by default (until maybe .NET 4.6.x). This
# will typically produce a message for PowerShell v2 (just an info
# message though)
try {
    # Set TLS 1.2 (3072) as that is the minimum required by Chocolatey.org.
    # Use integers because the enumeration value for TLS 1.2 won't exist
    # in .NET 4.0, even though they are addressable if .NET 4.5+ is
    # installed (.NET 4.5 is an in-place upgrade).
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
}
catch {
    Write-Output 'Unable to set PowerShell to use TLS 1.2. This is required for contacting Chocolatey as of 03 FEB 2020. https://chocolatey.org/blog/remove-support-for-old-tls-versions. If you see underlying connection closed or trust errors, you may need to do one or more of the following: (1) upgrade to .NET Framework 4.5+ and PowerShell v3+, (2) Call [System.Net.ServicePointManager]::SecurityProtocol = 3072; in PowerShell prior to attempting installation, (3) specify internal Chocolatey package location (set $env:chocolateyDownloadUrl prior to install or host the package internally), (4) use the Download + PowerShell method of install. See https://chocolatey.org/docs/installation for all install options.'
}

function Install-LocalChocolateyPackage {
param (
  [string]$chocolateyPackageFilePath = ''
)

  if ($chocolateyPackageFilePath -eq $null -or $chocolateyPackageFilePath -eq '') {
    throw "You must specify a local package to run the local install."
  }

  if (!(Test-Path($chocolateyPackageFilePath))) {
    throw "No file exists at $chocolateyPackageFilePath"
  }

  if ($env:TEMP -eq $null) {
    $env:TEMP = Join-Path $env:SystemDrive 'temp'
  }
  $chocTempDir = Join-Path $env:TEMP "chocolatey"
  $tempDir = Join-Path $chocTempDir "chocInstall"
  if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir)}
  $file = Join-Path $tempDir "chocolatey.zip"
  Copy-Item $chocolateyPackageFilePath $file -Force

  # unzip the package
  Write-Output "Extracting $file to $tempDir..."
  $shellApplication = new-object -com shell.application
  $zipPackage = $shellApplication.NameSpace($file)
  $destinationFolder = $shellApplication.NameSpace($tempDir)
  $destinationFolder.CopyHere($zipPackage.Items(),0x10)

  # Call chocolatey install
  Write-Output "Installing chocolatey on this machine"
  $toolsFolder = Join-Path $tempDir "tools"
  $chocInstallPS1 = Join-Path $toolsFolder "chocolateyInstall.ps1"

  & $chocInstallPS1

  Write-Output 'Ensuring chocolatey commands are on the path'
  $chocInstallVariableName = "ChocolateyInstall"
  $chocoPath = [Environment]::GetEnvironmentVariable($chocInstallVariableName)
  if ($chocoPath -eq $null -or $chocoPath -eq '') {
    $chocoPath = 'C:\ProgramData\Chocolatey'
  }

  $chocoExePath = Join-Path $chocoPath 'bin'

  if ($($env:Path).ToLower().Contains($($chocoExePath).ToLower()) -eq $false) {
    $env:Path = [Environment]::GetEnvironmentVariable('Path',[System.EnvironmentVariableTarget]::Machine);
  }
}

if (!(Test-Path $ChocoInstallPath)) {
  # Install Chocolatey
  if ($installLocalFile) {
    Install-LocalChocolateyPackage $localChocolateyPackageFilePath
  } else {
    if ($installLatestBeta) {
      iex ((new-object net.webclient).DownloadString('https://chocolatey.org/installabsolutelatest.ps1'))
    } else {
      iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
    }
  }
}

#Update-SessionEnvironment
choco feature enable -n autouninstaller
choco feature enable -n allowGlobalConfirmation
choco feature enable -n logEnvironmentValues
#####################################################
#####################################################

& "C:\\ProgramData\\chocolatey\choco" install git
& "C:\\ProgramData\\chocolatey\choco" install ruby

Copy-Item C:/Users/Administrator/AppData/Local/Temp/kitchen/modules/puppetcode C:/ProgramData/PuppetLabs/code/environments/production -Force

Set-Location C:/ProgramData/PuppetLabs/code/environments/production

& 'C:/Tools/ruby27/bin/gem.cmd' install r10k

# Copy Puppet manifests in all-in-one Puppet file to apply them
Copy-Item -Path "C:/Users/Administrator/AppData/Local/Temp/kitchen/modules/puppetcode/*" -Destination "C:/ProgramData/PuppetLabs/code/environments/production" -Recurse -Force
Copy-Item -Path "C:/etc/puppet/spec/hiera.test.yaml" -Destination "C:/ProgramData/PuppetLabs/code/environments/production/hiera.yaml"

Remove-Item "C:/ProgramData/PuppetLabs/code/environments/production/manifests/temp.pp"

Copy-Item -Path "C:/ProgramData/PuppetLabs/code/environments/production/site/role/manifests/windows/$role.pp" -Destination "C:/ProgramData/PuppetLabs/code/environments/production/manifests/temp.pp"

Get-ChildItem -Path 'C:/ProgramData/PuppetLabs/code/environments/production/site/profile/manifests/' -Recurse | Where-Object { $_.extension -eq ".pp" } | % {
   Get-Content $_.FullName | Add-Content "C:/ProgramData/PuppetLabs/code/environments/production/manifests/temp.pp"
}

Write-Output "include role::windows::$role" | Add-Content "C:/ProgramData/PuppetLabs/code/environments/production/manifests/temp.pp"

# Install the Puppet Modules
r10k puppetfile install

# Finalize the Puppet apply
& "C:\\Program Files\\Puppet Labs\\Puppet\\bin\\puppet.bat" apply --hiera_config=C:/ProgramData/PuppetLabs/code/environments/production/hiera.yaml C:/ProgramData/PuppetLabs/code/environments/production/manifests/temp.pp