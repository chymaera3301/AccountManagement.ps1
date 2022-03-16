Scripts are being with Power Automate, using both Web and Desktop flows <br />
  -"%*%" are used as variables that Power Automate feeds into the Powershell script <br />
  
  -The Web flow is started when a webhook is received from HR's onboarding services <br />
    -Which starts the desktop flow, after creating a few accounts it will send the information back to the Web flow <br />
    -Web flow sends one email with new hire account information to managers/supervisors and HR <br />
      -2nd email creates a ticket to add access that couldn't be automated based on our lack of access to some applications <br />

Sensative information has been swapped out with *******
