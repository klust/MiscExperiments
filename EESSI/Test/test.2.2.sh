outputfile='test.2.2.txt'
stackversion='2020.12'
module="EESSI-posix/$stackversion"

export EESSI_HOST_CPU=skylake

export EESSI_MODULE_SUBDIR='modules/tools'

echo -e "\nTest with EESSI_MODULE_SUBDIR=$EESSI_MODULE_SUBDIR, using $module"
module load $module

echo "$module, default module path" >$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile

module unload $module
echo "After unloding $module:" >>$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile
cat $outputfile
