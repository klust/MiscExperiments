# Development of a module to load an EESSI software stack

## External information

  * [EESSI Software Layer issue #68](https://github.com/EESSI/software-layer/issues/68)

## Possible approaches

The main challenge in the development of this module is to detect the operating system and the necessary characteristics to determine the optimal version of the software stack.

Some options:
  1. Let the system define an environment variable for the CPU architecture as would be returned 
     by ``archspec cpu``. The module file can then contain a mapping table to map that architecture 
     onto the best available stack. This table could be generated offline via a python script that 
     uses archspec and a list of architectures for which EESSI is available. 
     Moreover we simply assume that the OS is Linux or macOS but don't check if it isn't
     anything else. We simply check for the existence of a typeical directory in macOS and conclude
     it is macOS if that directory exists and Linux otherwise.
     The module can then completely rely on functions that are guaranteed to be available in Lmod.
  2. If we allow the use of the Lua module ``posix.uname`` it is easy to determinte the 
     operating system. One could also determine the processor family, but this is not enough
     to accurately determine the right software stack. It is only enough to run the generic stack
     for that family.
  3. As the steps taken in the previous option are enough to select the right compatibility
     layer, we can then run a script from the init directory to determine the right version of 
     the software stack. This requires some more advanced Lua programming to capture the output
     of a command run in the shell.

## Implementation

### The initialization process

Variables read by the init script
  * EESSI_CUSTOM_MODULEPATH
  * EESSI_MODULE_SUBDIR

Additional variables read by the module files
  * EESSI_HOST_CPU: Variant 1 and 2

Input variables from the init script currently not used
  * EESSI_SILENT

Output variables:
  * EESSI_PILOT_VERSION
  * EESSI_PREFIX
  * EESSI_OS_TYPE
  * EESSI_CPU_FAMILY
  * EPREFIX
  * EESSI_EPREFIX
  * EESSI_EPREFIX_PYTHON
  * EESSI_SOFTWARE_SUBDIR
  * EESSI_SOFTWARE_PATH
  * EESSI_MODULEPATH
All these variables will be unset when unloading the module.

Modified variables:
  * PATH: Add the compatility layer to the front
  * MODULEPATH: EESSI modules added to the front
  * LMOD_RC: Changed in a revertible way through ``pushenv``
These variables will be restored to their original value when unloading the module.

We tried to do the same with ``PS1`` but that didn't work. After unloading, no prompt was visible. It is not clear what is causing this. It may just be that Lmod gets confused with the many special characters that may be present in the prompt.

### Variant 1: EESSI-env

This variant uses only functions listed in the Lmod manual page 
"[Lua Modulefile Functions"](https://lmod.readthedocs.io/en/latest/050_lua_modulefiles.html)
and functions that are part of the Lua standard libraries (in particular ``string.gsub``).

  * The module relies on a table that does the mapping between the host CPU architecture
    (a name compatible with ``archspec cpu``) and the software directory. The current 
    table is built by hand but it should be possible to write a Python script that generates 
    it offline when preparing a new version of the EESSI stack. For each 
    archspec CPU namem, it returns the family (used by both the compatibility layer and the 
    software layer) and the vendor and arch (used only by the software layer).
  * We rely on the user to specify the CPU architecture in an ``archspec cpu``-compatible
    form through the environment variable ``EESSI_HOST_CPU`` which is mandatory in this variant.
  * We assume that the user is running either Linux or macOS and detect which OS is used 
    by looking for a file that should only exist on macOS.

The code is work-in-progress.

### Variant 2: [EESSI-posix](EESSI-posix)

This variant builds on variant 1, but uses optional Lua-functionality that may not be
present on all systems. In particular, the current inplementation uses
  * ``posix.uname``.
We do avoid calling external commands and gathering their input though.

Similarities and differences with variant 1:
  * The module relies on the same archspec mapping table as the variant 1 script.
  * The module contains an additional table, ``supported_family``, that is simply a 
    trick to quickly test if the CPU family detected automatically is supported by the
    module.
  * For the OS detection, we now rely on the output of ``uname -s`` obtained via the
    ``posix.uanme`` function (which will actually use the ``uname`` function)
  * The environment variable ``EESSI_HOST_CPU`` is now optional
      * When not specified, the CPU family is obtained through ``uname -m`` and the 
        generic layer for this architecture is offered. The module does print a warning
        though encouraging the user to set the environment variable.
      * When given, the module checks if it is compatible with the CPU family given by
        ``uname -m`` but furthermore assumes it is correct and uses the mapping table
        to determinse which version of the software layer to offer.
  * Except for those local changes in the code, the module is identical to variant 1.

### Variant 3: EESSI-auto

This variant builds on variant 2. Whereas in variant 2 we used some limited additional Lua functionality to detect all information needed to start the right compartibility layer and offer at least a working generic software layer without further user input through environment variables, we go one step further in varaint 3 and call the same Python script that is used by the regular initialization script to determine the software layer.

  * The archspec mapping table is no longer needed here. We did maintain the 
    ``supported_family``-table for now as it does help us to produce better error messages.
  * For the initialisation of the compatibility layer we rely on ``uname -s`` and 
    ``uname -m`` as in variant 2.
  * For the initialisation of the software layer we call the 
    ``eessi_software_subdir_for_host.py``-script using the Python interpreter from the comatibility layer. It does require some additional Lua functionality to call the script and capture its output.

The code is work-in-progress.

## Additional stuff used during the design

### Some testing of system behaviour (just to be sure)

| System                                          | uname -s | uname -m |
|-------------------------------------------------|----------|----------|
| MacBook Pro macOS 11.2.2 Core i5-7xxx Kaby Lake | Darwin   | x86_64   |
| Intel Broadwell E5-2680, CentOS 7               | Linux    | x86_64   |
| AMD zen2 EPYC 7282, CentOS 8                    | Linux    | x86_64   |
| AMD zen2 EPYC 7742, Cray                        | Linux    | x86_64   |

'''Lua
-- TODO
local detect_command = pathJoin( eprefix, "/usr/bin/python" ) .. ' ' ..
                       pathJoin( eessi_root, eessi_version, '/init/eessi_software_subdir_for_host.py' ) .. ' ' ..  
                       pathJoin( eessi_root, eessi_version )
LmodMessage( 'TODO: Can we now run ' .. detect_command .. ' and capture the output instead of using the full mapping?')
'''

Lua code blocks to call an external routine an read the output:
```Lua
local file = assert(io.popen('echo "skylake"', 'r'))
local output = file:read('*all')
file:close()
print(output)
```
```Lua
file = assert(io.popen('sleep 10 ; echo "skylake"', 'r'))
output = file:read('*all')
file:close()
print(output)
```



