<#
.SYNOPSIS
  Change the startup type for a Windows Service using a Hybrid Runbook Worker

.DESCRIPTION
  This runbook allows you to change the startup type of a Windows Service via a Hybrid Runbook Worker.

  If the service is already set to the supplied Startup Type, a Warning is generated, but the runbook does not fail.

  Exit codes are as follows:

  0 - The script executed succesfully.
  1 - Invalid parameters specified.
  2 - Could not successfully change the startup type.
  4 - No or multiple services found using the provided name.
  99 - Unhandled exception.

  The output is formatted as JSON for easy consumption in a LogicApp. Sample output is provided below:

  {
	"success": true,
	"message": "Startup Type changed successfully.",
	"errorCode": 0
  }

.PARAMETER StartupType
   Mandatory, can be one of the following: Automatic, Manual, Disabled
   The target service's startup type will be changed to this.

.PARAMETER ServiceName
   Mandatory, no default set.
   The name of the Windows Service that you want to perform the action on.
   Although you can specify a wildcard (i.e. 'App*' will match AppIdSvc and AppMgmt), the script will generate an error if it finds more than one
   service. Monitor for exit code 4 if this is unintended.

.NOTES
   AUTHOR: Marcel du Preez
   LASTEDIT: December 8, 2022
#>

Param
(
  [Parameter (Mandatory= $true)]
  [string] $StartupType,
  [Parameter (Mandatory= $true)]
  [string] $ServiceName
)

function ProvideResponse()
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory= $true)]
		[string]$OutputMessage,
		[Parameter(Mandatory= $false)]
		[int]$ErrorCode
	)

	$payload = @{
		success = ($errorCode -eq 0)
		message = $OutputMessage
		exitCode = $errorCode
	}

	Write-Output (ConvertTo-Json $payload)
}

$GLOBAL:ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Write-Verbose "Runbook started."

# Parameter checking
if(($StartupType.ToLowerInvariant() -ne 'Automatic') -and 
   ($StartupType.ToLowerInvariant() -ne 'Manual') -and 
   ($StartupType.ToLowerInvariant() -ne 'Disabled'))
{
	$errorMessage = "Invalid startup type supplied."
	ProvideResponse -OutputMessage $errorMessage -ErrorCode 1
	Write-Error $errorMessage -ErrorAction Continue
	throw $errorMessage
}

Write-Verbose "Service $ServiceName will be changed to this startup type: $startupType"
Write-Verbose "Checking if service exists..."

$service = Get-Service $ServiceName -ErrorAction SilentlyContinue

if($service.Length -gt 1)
{
	$errorMessage = "Found more than one service with the supplied ServiceName parameter."
	ProvideResponse -OutputMessage $errorMessage -ErrorCode 4
	Write-Error $errorMessage -ErrorAction Continue 
	throw $errorMessage
}
elseif ($service.Length -eq 1) 
{
	Write-Verbose "Found service. Current startup type is: $($service.StartType)"

    if($service.StartType -eq $StartupType)
    {
        $warningMessage = "Startup Type is already set to $StartupType. No action performed."
        ProvideResponse -OutputMessage $warningMessage -ErrorCode 0
        Write-Warning $warningMessage 
    }
    else 
    {
        Write-Verbose "Changing startup type to $startupType"
        
        try 
        {
            $service | Set-Service -StartupType $startupType
        }
        catch
        {
            ProvideResponse -OutputMessage $_.Exception -ErrorCode 99
            Write-Error -Message $_.Exception -ErrorAction Continue
            throw $_.Exception
        }
        
        Write-Verbose "Confirming startup type has changed..."
        $service = Get-Service $ServiceName
        if($service.StartType -ne $startupType)
        {
            $errorMessage = "Startup type could not be changed successfully."
            ProvideResponse -OutputMessage $errorMessage -ErrorCode 2
			Write-Error $errorMessage -ErrorAction Continue 
			throw $errorMessage
        }
        else 
        {
            $successMessage = "Startup Type changed successfully."
            Write-Verbose $successMessage
            ProvideResponse -OutputMessage $successMessage -ErrorCode 0
        }
    }
}
else
{
	$errorMessage = "Could not find a service called '$ServiceName'."
	ProvideResponse -OutputMessage $errorMessage -ErrorCode 4
	Write-Error $errorMessage -ErrorAction Continue
	throw $errorMessage
}
