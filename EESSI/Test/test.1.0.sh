outputfile='test.1.0.txt'

echo -e "\nTest with no environment variables set, running the default EESSI init script"
source /cvmfs/pilot.eessi-hpc.org/2020.12/init/bash

echo "Init script, default module path" >$outputfile
env | egrep ^EESSI | sort >>$outputfile
cat $outputfile
