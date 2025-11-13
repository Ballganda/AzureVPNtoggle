# AzureVPNtoggle
Part of setting up a script for Azure VPN that does not ask you for admin every single time
  
Ther high level instructions:  
Copy the vpntoggle.bat file to a location you want it to stay  
I use a location like "C:\Users\%username%\Utilities\VPN Toggle\"  
Lets assume for this instr. "C:\Users\%username%\Utilities\VPN Toggle\vpntoggle.bat"  
  
Open vpntoggle.bat with text editor and replace 'SET "VpnName=MyVPN"' with your VPN name
This assumes you have your Azure VPN setup already. It whould be visible in Control Panel\Network and Internet\Network Connections  
  
Open Windows Task Scheduler make a new folder in the Task Schduler Library. I named mine 'VPN' which will be in a shortcut target later  
Make a new task I names mine 'vpnStart' again name used will be used in target of shortcut later  
General tab:  
Select Run only when user is logged on  
Select Run With highest Privileges  
Actions tab:
Action-Start a program  
Details-C:\Users\user\Utilities\VPN Toggle\vpntoggle.bat  
'user' is the %username%, I did not check if var here works  
Settings Tab:
Check Allow task to be run on demand

Make a shortcut to run this task manually 'on demand':  
Windows explorer right click/new/shortcut 
Type the location of the item : C:\Windows\System32\schtasks.exe /RUN /TN \VPN\vpnStart
*This assumes the folder in task scheduler is VPN and the task name is vpnStart*  
Name it something catchy like VPN Toggle.  
  
Done this shortcut now toggles...well mine does. 
