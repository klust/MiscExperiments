local eessi_version = myModuleVersion()
local eessi_root = '/cvmfs/pilot.eessi-hpc.org/'

--
-- We do need some packages unfortunately that should be pretty standard.
--
local posix = require( 'posix' )

--
-- Some initialisations.
-- 

-- Table mapping possible values for arcspec_cpu onto the host triple 
-- (family, vendor, arch) where vendor is omitted in some cases.
local arch_mapping = {
    x86_64 =         { family = 'x86_64',                    arch = 'generic' },
    nocona =         { family = 'x86_64',                    arch = 'generic' },
    core2 =          { family = 'x86_64',                    arch = 'generic' },
    nehalem =        { family = 'x86_64',                    arch = 'generic' },
    westmere =       { family = 'x86_64',                    arch = 'generic' },
    sandybridge =    { family = 'x86_64',                    arch = 'generic' },
    ivybridge =      { family = 'x86_64',                    arch = 'generic' },
    hasswell =       { family = 'x86_64',  vendor = 'intel', arch = 'haswell' },
    broadwell =      { family = 'x86_64',  vendor = 'intel', arch = 'haswell' },
    skylake =        { family = 'x86_64',  vendor = 'intel', arch = 'haswell' },
    skylake_avx512 = { family = 'x86_64',  vendor = 'intel', arch = 'skylake_avx512' },
    cascadelake =    { family = 'x86_64',  vendor = 'intel', arch = 'skylake_avx512' },
    icelake =        { family = 'x86_64',  vendor = 'intel', arch = 'skylake_avx512' },
    bulldozer =      { family = 'x86_64',                    arch = 'generic' },
    piledriver =     { family = 'x86_64',                    arch = 'generic' },
    steamroller =    { family = 'x86_64',                    arch = 'generic' },
    excavator =      { family = 'x86_64',                    arch = 'generic' },
    zen =            { family = 'x86_64',                    arch = 'generic' },
    zen2 =           { family = 'x86_64',  vendor = 'amd',   arch = 'zen2' },
    zen3 =           { family = 'x86_64',  vendor = 'amd',   arch = 'zen3' },
    power9le =       { family = 'ppc64le',                   arch = 'power9le' },
    aarch64 =        { family = 'aarch64',                   arch = 'generic' },
    thunderx2 =      { family = 'aarch64',                   arch = 'thunderx2' },
    a64fx =          { family = 'aarch64',                   arch = 'a64fx' },
    graviton =       { family = 'aarch64',                   arch = 'generic' },
    graviton2 =      { family = 'aarch64',                   arch = 'graviton2' }
}

local supported_family = { x86_64 = true, ppc64le = true,  aarch64 = true }

local helpstring = string.gsub( [[
This module enables the EESSI EESSI_VERSION pilot. It is not needed to 
execute the initialisation scripts after loading this module.

The module accepts the following optional environment variables that should be 
set and exported before loading the module to influence the EESSI configuration
activated by the module:
  * EESSI_HOST_CPU: The CPU architecture as would be returned by 
    ``archspec cpu``. To know the best value, you may contact your system 
    manager (if you are working on a managed system) who may even have set it
    in the system initialisation scripts, or initialise EESSI once through the
    initialisation scripts and then run ``archspec cpu``. 
    When not set, a generic software layer will be activated that may not be
    optimised well for your particular system.
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

local archspec_cpu = os.getenv( 'EESSI_HOST_CPU' ) 
if ( mode() == 'load' ) then
    if ( archspec_cpu == nil ) then
        LmodMessage( 'EESSI: No CPU architecture given, so the generic ' .. eessi_cpu_family .. ' software stack will be used. ' ..
                      'Set the environment variable EESSI_HOST_CPU to the CPU in your system as determined by archspec to get an optimized software stack.'  )
        archspec_cpu = eessi_cpu_family
    elseif ( arch_mapping[archspec_cpu] == nil ) then
        LmodError( 'EESSI: ' .. archspec_cpu .. ' is an unsupported CPU.' )
    elseif ( arch_mapping[archspec_cpu].family ~= eessi_cpu_family ) then
        LmodError( 'EESSI: The CPU ' .. archspec_cpu .. ' does not correspond to the CPU family detected from the OS.' )
    end
else
    -- No need to print warnings if we are not loading the module, and error messages don't make sense either
    -- as they should not occur unless the user already broke the environment by unsetting variables.
    if ( archspec_cpu == nil ) then
        archspec_cpu = eessi_cpu_family
    end
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
local eessi_software_subdir
if ( arch_mapping[archspec_cpu].vendor == nil ) then
    eessi_software_subdir = pathJoin( arch_mapping[archspec_cpu].family, arch_mapping[archspec_cpu].arch )
else
    eessi_software_subdir = pathJoin( arch_mapping[archspec_cpu].family, arch_mapping[archspec_cpu].vendor, arch_mapping[archspec_cpu].arch )
end

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
