# Coal's CentOS 7 Compile Scripts

**NOTICE: THIS IS MEANT TO BE RAN FROM BRAND NEW INSTALLS OR UPDATES TO INSTALLS FROM THIS SCRIPT**

*This script is subject to change and using it is at your own risk*

**Command To Start The Process From a New CentOS 7 Install**

*What This Script Does*

- Command pulls the most current copy of the compile script executes it 
- Updates the componants as needed  
- Pulls the newest HighFidelity code and compiles it 
- Creates a user named `hifi` to run HighFidelity DS/AC under (for security reasons)
- Writes to the `/etc/profile.d/coal.sh` file the aliases for these local commands 
- Runs the DS/AC stack for the first time      
  - Just a notice, you can access this via a web browser at address `http://IPADDRESS:40100`

*The Initial Command to Run

`bash <(curl -Ls https://raw.githubusercontent.com/nbq/hifi-compile-scripts/master/centos7-compile-hifi.sh)`
 
# Future updates and utility commands

**After running the above command, once you log in again you can call the following commands locally**

- **compilehifi** - Does a force compile on highfidelity
- **recompilehifi** - Does a recompile only if one is required
- **runhifi** - Run highfidelity
- **killhifi** - Kill all running highfidelity instances

## Beta Test on Ubuntu Server (generally a Digital Ocean Droplet

**Run these commands on an Ubuntu 15.04 x64 Server**

```
apt-get update && apt-get upgrade -y && apt-get install curl -y
bash <(curl -Ls https://raw.githubusercontent.com/nbq/hifi-compile-scripts/master/ubuntu-compile-hifi.sh)
```

---

## lexicon
keyword | description
--------|------------
AC      | Assignment Client - Each assignment runs on an assignment-client
DS      | Domain Server - The domainserver makes sure that the assignments are collaborating
HiFi    | High Fidelity
