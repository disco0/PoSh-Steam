function Switch-SteamUser(){
   <#
    .SYNOPSIS
	Switch Steam login to supplied username, skipping Steam Guard if unnecessary.
	
    .DESCRIPTION
      Takes supplied username in the parameter $Username and substitutes it into  
    the AutologinUser value in the Steam registry key. If the supplied username
    has successfully entered a two factor authetication code previously then no 
    password or code will be needed—otherwise first time logins will require 
    them as normal.

    .PARAMETER Username
	Specifies the Steam Username to be used for login
	
    .EXAMPLE
	C:\PS> Switch-Steam SteamUsername
	
    .LINK
	Module Repo => https://github.com/disco0/PoSh-Steam
   #>
	[cmdletbinding()]
	Param( [Parameter(Mandatory=$True, Position=1)]
           [string]$Username                        )	

    $shh = @{ ErrorAction = 'SilentlyContinue' }
    
  # Define Steam paths and initial registry values
    $SteamReg     = "Registry::HKEY_CURRENT_USER\Software\Valve\Steam"
    $SteamRegKeys = Get-ItemProperty $SteamReg
    $SteamExe     = $SteamRegKeys.SteamExe
	$AutoLoginUserInit    = $SteamRegKeys.AutoLoginUser
	$RememberPasswordInit = $SteamRegKeys.RememberPassword

  # Exit Steam
    if (Get-Process @shh Steam)
    { 
		Write-Host 'Stopping Steam process...'
        try 
        {
            & $SteamExe -Shutdown
            Wait-Process Steam    
        }
        catch { Write-Error "Stopping Steam process failed."; return }
    }

  # Set AutoLoginUser value to new username input
    #TODO: Catch error at registry change
	Set-ItemProperty -Path $SteamReg -Name AutoLoginUser -Value $Username

  # Validate Change and set RememberPassword value to 1, if update fails roll back to original 
    if( (Get-ItemProperty $SteamReg -Name AutoLoginUser ) -NotMatch $Username )
    {
		Set-ItemProperty -Path $SteamReg -Name AutoLoginUser -Value $AutoLoginUserInit
		Write-Output "Username change failed."
    }
    else 
    {
		Set-ItemProperty $SteamReg -Name RememberPassword 1
		& $SteamExe
	}   
}
