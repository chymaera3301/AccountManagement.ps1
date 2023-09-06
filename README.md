Scripts are ran within Power Automate Desktop, process utilizes both Web and Desktop flows <br/>

>The Web flow is started when a webhook is received from an HR service, containing JSON<br/>
>>JSON is then parsed and variables created in PAW*<br/>
>>Data is then sent to PAD* where attached Powershell scripts and Desktop Recordings are utilized<br/>
>>Data from PAD* is converted to JSON, parsed, then sent back to PAW*<br/>
>>Sharepoint lists are then updated for tracking. Shows when an item is in process, then if it passed or failed<br/>
>>Emails sent out to those in management roles containing associated account information<br/>
>>Additional email sent to Account Management to add access that has yet to be automated<br/>

PAW = Power Automate Web<br/>
PAD = Power Automate Desktop<br/>
>Power Automate configuration not available<br/>
<p>Sensative information has been swapped out with *******<br/>
"%variable%" is used as variables that Power Automate feeds into the Powershell script <br/><p/>
