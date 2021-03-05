outputfile='test.1.2.txt'
stackversion='2020.12'
module="EESSI-posix/$stackversion"

export EESSI_HOST_CPU=skylake

echo -e "\nTest with no environment variables set, using using $module"
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
