-- EESSI startup module
--  * Uses LUA standard library functions for sting and io
--  * Requires posix.uname
-- Calls an external EESSI script for the initialisation.
local eessi_version = myModuleVersion()
local eessi_root = '/cvmfs/pilot.eessi-hpc.org/'

--
-- We do need some packages unfortunately that should be pretty standard.
--
local posix = require( 'posix' )

--
-- Some initialisations.
-- 

local supported_family = { x86_64 = true, ppc64le = true,  aarch64 = true }

local helpstring = string.gsub( [[
This module enables the EESSI EESSI_VERSION pilot. It is not needed to 
execute the initialisation scripts after loading this module.

The module accepts the following optional environment variables that should be 
set and exported before loading the module to influence the EESSI configuration
activated by the module:
  * EESSI_CUSTOM_MODULEPATH: Refer to a different module path. By default, EESSI
    will show all modules that are available on your system in a flat module 
    structure.
  * EESSI_MODULE_SUBDIR: Can be used to only show a specific selection of the 
    module tree. E.g., EESSI_MODULES_SUBDIR='modules/tools' will only show the 
    modules of the ``tools``-class.

Note that if you make any change to the EESSI_ variables between loading and
unloading of the module, your environment may not be fully cleaned up after 
unloading.    
]], 'EESSI_VERSION', eessi_version )
help( helpstring )

whatis( 'Enables the EESSI ' .. eessi_version .. 'pilot.' )

family( 'EESSI' )

--
-- Detect whatever we can detect relatively safely and test the values.
-- We cannot yet use the compatibility layer so not detect everything.
--
local uname_os = posix.uname( '%s' )
local eessi_os_type 
if ( uname_os == 'Linux' ) then
    eessi_os_type = 'linux'
elseif ( uanme_os == 'Darwin' ) then
    eessi_os_type = 'macos'
else
    LmodError( 'EESSI: The operating system ' .. uname_os .. ' as reported by uname -s is not supported' )
end

local eessi_cpu_family = posix.uname( '%m' )
if ( not supported_family[eessi_cpu_family] ) then
    LmodError( 'EESSI: The processor family ' .. eessi_cpu_family .. ' as reported by uname -m is not supported' )
end

-- The problem with overwriting PS1 is that the variable is not
-- correctly restored when unloading the module and no prompt appears.
-- It may be due to a bug in Lmod because pushenv should restore the value
-- when unloading the module.
-- pushenv( 'PS1', '[EESSI pilot ' .. eessi_version .. '] $ ' )

-- -----------------------------------------------------------------------------
--
-- General initialisation and initialisation of the compatibility layer
--

setenv( 'EESSI_PILOT_VERSION',   eessi_version )
setenv( 'EESSI_PREFIX',          pathJoin( eessi_root, eessi_version ) )
setenv( 'EESSI_OS_TYPE',         eessi_os_type )
setenv( 'EESSI_CPU_FAMILY',      eessi_cpu_family )

-- Set EPREFIX since that is basically a standard in Gentoo Prefix
local eprefix = pathJoin( eessi_root, eessi_version, 'compat', eessi_os_type, eessi_cpu_family )
if not isDir( eprefix ) then
    LmodError( 'EESSI compatibility layer at ' .. eprefix .. ' not found. Maybe check the CVMFS mounts?' )
end
setenv( 'EPREFIX',               eprefix )
prepend_path( 'PATH',            pathJoin( eprefix, '/usr/bin' ) )
setenv( 'EESSI_EPREFIX',         eprefix )
setenv( 'EESSI_EPREFIX_PYTHON',  pathJoin( eprefix, '/usr/bin/python3' ) )

-- -----------------------------------------------------------------------------
--
-- Initialisation of the software layer
--

--
-- Determine the the optimal software subdirectory
-- 
local detect_command = pathJoin( eprefix, "/usr/bin/python" ) .. ' ' ..
                       pathJoin( eessi_root, eessi_version, '/init/eessi_software_subdir_for_host.py' ) .. ' ' ..  
                       pathJoin( eessi_root, eessi_version )
-- It turns out (as warned for in the documentation) that a newline character is added to the variable
-- so we need to remove that with gsub
local eessi_software_subdir = capture(  detect_command ):gsub("%s+", "")

--
-- Now do the other initialisations of environment variables.
-- 
local eessi_software_path = eessi_root .. eessi_version .. '/software/' .. eessi_software_subdir
-- Double check that the software path indeed exists. Otherwise there is a problem with the mounts
-- or the EESSI stack is seriously broken.
if ( not isDir( eessi_software_path ) ) then
    LmodError(  'EESI: Software directory ' .. eessi_software_path .. ' not found, the EESSI distribution seems to be broken' )
end
setenv( 'EESSI_SOFTWARE_SUBDIR', eessi_software_subdir )
setenv( 'EESSI_SOFTWARE_PATH',   eessi_software_path )

-- This block still needs refinement as the init script allows for alternative module 
-- structures.
local eessi_custom_module_path = os.getenv( 'EESSI_CUSTOM_MODULEPATH' )
local eessi_module_subdir = os.getenv( 'EESSI_MODULE_SUBDIR' )
local eessi_module_path
if ( eessi_custom_module_path == nil ) then
    -- No EESSI_CUSTOM_MODULEPATH set
    if ( eessi_module_subdir == nil ) then
        -- Neither EESSI_CUSTOM_MODULEPATH nor EESSI_MODULE_SUBDIR are set, so we
        -- use the standard module path.
        eessi_module_path = pathJoin( eessi_software_path, '/modules/all' )
        if ( not isDir( eessi_module_path ) ) then
            LmodError( 'EESSI: The default module directory ' .. eessi_module_path .. ' cannot be found. ' ..
                       'It seems EESSI is broken.' )
        end
    else
        -- EESSI_CUSTOM_module_pathG is not set but EESSI_MODULE_SUBDIR points
        -- to a different module subdirectory in the software subdirectory.
        eessi_module_path = pathJoin( eessi_software_path, eessi_module_subdir )
        if ( not isDir( eessi_module_path ) ) then
            LmodError( 'EESSI: The module directory ' .. eessi_module_path .. ' cannot be found. ' ..
                       'The value of EESSI_MODULE_SUBDIR (' .. eessi_module_subdir .. ') may be bad.' )
        end
    end
else
    eessi_module_path = eessi_custom_module_path
    if ( not isDir( eessi_module_path ) ) then
        LmodError( 'EESSI: The module directory ' .. eessi_module_path .. ' cannot be found. ' ..
                   'The value of EESSI_CUSTOM_MODULEPATH (' .. eessi_custom_module_path .. ') may be bad.' )
    end
end

setenv( 'EESSI_MODULEPATH', eessi_module_path )
prepend_path( 'MODULEPATH', eessi_module_path )

-- Set LMOD_RC. This may be a problem if it is already set in the system for other reasons!
-- We use pushenv to ensure that it is set back to the original value when unloading the module.
pushenv( 'LMOD_RC', pathJoin( eessi_software_path, '/.lmod/lmodrc.lua' ) )
