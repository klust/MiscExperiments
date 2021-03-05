outputfile='test.1.0.txt'
stackversion='2020.12'

echo -e "\nTest with no environment variables set, running the default EESSI init script"
source /cvmfs/pilot.eessi-hpc.org/$stackversion/init/bash

echo "Init script, default module path" >$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile

cat $outputfile
