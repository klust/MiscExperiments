outputfile='test.2.0.txt'
stackversion='2020.12'

export EESSI_MODULE_SUBDIR='modules/tools'

echo -e "\nTest with EESSI_MODULE_SUBDIR=$EESSI_MODULE_SUBDIR, running the default EESSI init script"
source /cvmfs/pilot.eessi-hpc.org/$stackversion/init/bash

echo "Init script, default module path" >$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "EPREFIX=$EPREFIX" >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile

cat $outputfile
