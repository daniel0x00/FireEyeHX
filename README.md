# FireEyeHX API v3 PowerShell wrapper

Hi! This is a wrapper of the FireEyeHX v3 API. There are two versions: one for PowerShell Core and another one for Windows PowerShell. It has been tested in CentOS 7 Linux, Windows Server 2012, Windows 10 and also using Azure Automation Runbooks using Hybrid Workers on Windows PowerShell. Please note the different braches of the project and install the version you need. Enjoy it!  

## Master branch

For **PowerShell Core** (tested on version 6.1)

### Installation

 1. Method one:
	- Use PowerShell Gallery: 

        ```Import-Module -Name FireEyeHX```
		 
 2. Method two:
	- Clone and import:
	
        ```
        git clone --single-branch -b master git@github.com:daniel0x00/FireEyeHX.git
        Import-Module -Name .\FireEyeHX\FireEyeHX.psm1 -Verbose
        ``` 

## ps5 branch

For **Windows PowerShell** (tested on version 5.0)

### Installation

 1. Method one:
	 - Clone and import:

		```
        git clone --single-branch -b ps5 git@github.com:daniel0x00/FireEyeHX.git
        Import-Module -Name .\FireEyeHX\FireEyeHX.psm1 -Verbose
        ```

## Usage

Creating a Bulk Acquisition against a HostSet:

```
PS C:\> $credential = Get-Credential
PS C:\> $controller = 'https://hxcontroller.domain.com:3000'
PS C:\> 
PS C:\> New-HXSession -Uri $controller -Credential $credential | Find-HXHostSet -Search 'TargetHostSet' | Add-HXBulkAcquisition -Platform win -ScriptFile C:\Users\XXX\Desktop\JustTest-win.json

bulkacquisition_id : 3
revision           : 20180921210323088068235355
comment            : PSAutomaticBulkAcquisition
create_time        : 2018-09-29T21:03:23.088Z
state              : RUNNING
endpoint           : /hx/api/v3/acqs/bulk/3
Uri                : https://hxcontroller.domain.com:3000
TokenSession       : IMXw3MCt6A8ElVhgOh+DLzLObQozF8M4/X1vB0OkBF37ImI=

```