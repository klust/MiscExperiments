outputfile='test.1.0.txt'
stackversion='2020.12'
module="EESSI-auto/$stackversion"

export EESSI_MODULE_SUBDIR='modules/tools'

echo -e "\nTest with EESSI_CUSTOM_MODULEPATH=$EESSI_CUSTOM_MODULEPATH, using $module"
module load $module

echo "$module, default module path" >$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile

module unload $module
echo "After unloding $module:" >>$outputfile
env | egrep ^EESSI | sort >>$outputfile
echo "MODULEPATH=$MODULEPATH" >>$outputfile
cat $outputfile
