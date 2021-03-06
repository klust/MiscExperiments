outputfile='test.1.3.txt'
stackversion='2020.12'
module="EESSI-auto/$stackversion"

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
