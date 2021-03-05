outputfile='test.3.0.txt'
stackversion='2020.12'

export EESSI_CUSTOM_MODULEPATH='/cvmfs/pilot.eessi-hpc.org/2020.12/software/x86_64/generic/modules/math'

echo -e "\nTest with EESSI_CUSTOM_MODULEPATH=$EESSI_CUSTOM_MODULEPATH, running the default EESSI init script"
source /cvmfs/pilot.eessi-hpc.org/$stackversion/init/bash

echo "Init script, default module path" >$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile

cat $outputfile
