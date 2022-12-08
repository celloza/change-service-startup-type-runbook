# change-service-startup-type-runbook
An Azure Runbook that allows changing the startup type of a Windows Service through a Hybrid Runbook Worker.

# Introduction

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

Can be used in conjunction with [https://github.com/grimstoner/control-windows-service-runbook](https://github.com/grimstoner/control-windows-service-runbook) to stop or start the service as part of environment automations.

# Sample usage

![image](https://user-images.githubusercontent.com/3426823/206464783-b9f3c4a1-e82a-41ba-adf9-bdae373b2b47.png)

# Sample output

![image](https://user-images.githubusercontent.com/3426823/206464530-f9d49150-b39b-420d-bcc4-ae32abd73160.png)
