outputfile='test.3.3.txt'
stackversion='2020.12'
module="EESSI-auto/$stackversion"

export EESSI_CUSTOM_MODULEPATH='/cvmfs/pilot.eessi-hpc.org/2020.12/software/x86_64/generic/modules/math'

echo -e "\nTest with EESSI_CUSTOM_MODULEPATH=$EESSI_CUSTOM_MODULEPATH, using $module"
module load $module

echo "$module, default module path" >$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "EPREFIX=$EPREFIX" >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile

module unload $module
echo "After unloding $module:" >>$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile
cat $outputfile
