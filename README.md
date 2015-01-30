# Coal's CentOS 7 Compile Scripts

**NOTICE: THESE ARE MEANT TO BE RAN FROM BRAND NEW INSTALLS ONLY**

*These script are subject to change and using them are at your own risk*

**Command To Start The Process From a New CentOS 7 Install**

*To understand exactly what this script does, refer to the `compilehifi` command reference below*

*What This Script Does*

- Command pulls the most current copy of the compile script executes it 
- Updates the componants as needed  
- Pulls the newest HighFidelity code and if needed, compiles it 
- Creates a user named `hifi` to run HighFidelity DS/AC under (for security reasons)
- Writes to the `.bashrc` file the aliases for these local commands 
- Runs the DS/AC stack for the first time      
  - Just a notice, you can access this via a web browser at address `http://IPADDRESS:40100`

*The Initial Command to Run

`bash <(curl -Ls https://raw.githubusercontent.com/nbq/hifi-compile-scripts/master/centos7-compile-hifi.sh)`
 
# Future updates and utility commands

**After running the above command once, you can call the following commands locally**

- compilehifi
- runhifi

*compilehifi*

- Reference the section "What This Script Does" above. 

*runhifi*

- Command pulls the most current copy of the run script which does the following
- Kills any running HighFidelity DS/AC processes
- Runs the commands, as premade user `hifi`, to start the domain-server and assignment-client 
- Keeps you from ever having to handle any manual commands to change to the hifi user to run the commands
