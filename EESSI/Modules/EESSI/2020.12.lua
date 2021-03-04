local eessi_version = "2020.12"
local eessi_root = "/cvmfs/pilot.eessi-hpc.org/"

local archspec_cpu = os.getenv( 'EESSI_ARCHSPEC_CPU' )
if ( archspec_cpu == nil ) then
    LmodError( 'EESSI: Please set the environment variable EESSI_ARCHSPEC_CPU to the CPU in your system as determined by archspec' )
end

--
-- We do need some packages unfortunately that should be pretty standard.
--
local posix = require( 'posix' )

-- Discovering which software directories to use:
-- - Option 1: Detect the cpu architecture as returned by archspec cpu 
--   and use a mapping in the module file to map that onto the triple 
--   for the host type. That mapping table could always be generated
--   offline during the building of a new EESSI stack.
-- - Option 1bis: Simply ask system managers who want to provide EESSI
--   through a module to set a certain environment variable which this
--   module then picks up. This can avoid calling external programs
--   that may or may not slow down the loading and unloading of the
--   module.
-- - Option 2:
--     + First discover the CPU family which is enough to intialize
--       the correct version of the compatibility layer. (uname -m)
--     * Then use the compatibilty layer to run the Python script 
--       that determines the version of the software layer.
-- When EESSI starts supporting macos we also need to add the code
-- to detect the OS or detect the OS by testing some typical environment
-- variables or directories, e.g., assume that a system that has
-- /System/Library/AppleUSBDevice is a Mac and otherwise it's a Linux
-- machine.

-- Now if we could get the info in the following line elsewhere...
local archspec_cpu = 'skylake'
-- Alternatively, it might be enough if we could only determine the CPU family
-- as that is enough to initialize the compatibility layer. We may then try to
-- use that one to discover further properties.
-- Having lscpu and awk or grep and sed might be enough.

-- Table mapping possible values for arcspec_cpu onto the host triple 
-- (family, vendor, arch) where vendor is omitted in some cases.
-- The followind can't be a local variable. I'm not sure how dangerous that
-- is for Lmod.
arch_mapping = {
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

supported_family = { x86_64 = true, ppc64le = true,  aarch64 = true }

--
-- Detect whatever we can detect relatively safely
--
local uname_os =     posix.uname( '%s' )
local uname_family = posix.uname( '%m' )

--
-- Initilze a number of variables with what we already have
--

local eessi_os_type = '' 
if ( uname_os == 'Linux' ) then
    eessi_os_type = 'linux'
elseif ( uanme_os == 'Darwin' ) then
    eessi_os_type = 'macos'
else
    LmodError( 'EESSI: The operating system ' .. uname_os .. ' as reported by uname -s is not supported' )
end
if ( not supported_family[uname_family] ) then
    LmodError( 'EESSI: The processor family ' .. uname_family .. ' as reported by uname -m is not supported' )
end
local eessi_cpu_family = arch_mapping[archspec_cpu].family
local eessi_cpu_vendor = arch_mapping[archspec_cpu].vendor
local eessi_arch =       arch_mapping[archspec_cpu].arch

local helpstring = string.gsub( [[
This module enables the EESSI EESSI_VERSION pilot. It is not needed to 
execute the initialisation scripts after loading this module.
]], "EESSI_VERSION", eessi_version )
help( helpstring )

local whatisstring = string.gsub(
"Enables the EESSI EESSI_VERSION pilot.",
"EESSI_VERSION", eessi_version )
whatis( whatisstring )

family( "BaseSoftwwareStack" )

-- The problem with overwriting PS1 is that the variable is not
-- correctly restored when unloading the module and no prompt appears.
-- It may be due to a bug in Lmod because pushenv should restore the value
-- when unloading the module.
-- pushenv( "PS1", "[EESSI pilot " .. eessi_version .. "] $ " )

setenv( "EESSI_PILOT_VERSION",   eessi_version )
setenv( "EESSI_PREFIX",          pathJoin( eessi_root, eessi_version ) )
setenv( "EESSI_OS_TYPE",         eessi_os_type )
setenv( "EESSI_CPU_FAMILY",      eessi_cpu_family )

-- Set EPREFIX since that is basically a standard in Gentoo Prefix
local eprefix = pathJoin( eessi_root, eessi_version, 'compat', eessi_os_type, eessi_cpu_family )
if not isDir( eprefix ) then
    LmodError( 'EESSI compatibility layer at ' .. eprefix .. ' not found. Maybe check the CVMFS mounts?' )
end
setenv( "EPREFIX",               eprefix )
prepend_path( "PATH",            pathJoin( eprefix, "/usr/bin" ) )
setenv( "EESSI_EPREFIX",         eprefix )
setenv( "EESSI_EPREFIX_PYTHON",  pathJoin( eprefix, "/usr/bin/python" ) )

-- TODO
local detect_command = pathJoin( eprefix, "/usr/bin/python" ) .. ' ' ..
                       pathJoin( eprefix, '}/init/eessi_software_subdir_for_host.py' ) .. ' ' ..  
                       pathJoin( eessi_root, eessi_version )
LmodMessage( 'TODO: Can we now run ' .. detect_command .. ' and capture the output instead of using the full mapping?')

-- Set variables for the software layer.
local eessi_software_subdir
if ( eessi_cpu_vendor == nil ) then
    eessi_software_subdir = pathJoin( eessi_cpu_family, eessi_arch )
else
    eessi_software_subdir = pathJoin( eessi_cpu_family, eessi_cpu_vendor, eessi_arch )
end
local eessi_software_path = eessi_root .. eessi_version .. "/software/" .. eessi_software_subdir
setenv( "EESSI_SOFTWARE_SUBDIR", eessi_software_subdir )
setenv( "EESSI_SOFTWARE_PATH",   eessi_software_path )

setenv( "EESSI_MODULE_PATH",     pathJoin( eessi_software_path, "/modules/all" ) )
prepend_path( "MODULEPATH",      pathJoin( eessi_software_path, "/modules/all" ) )
-- Set LMOD_RC. This may be a problem if it is already set in the system for other reasons!
-- We use pushenv to ensure that it is set back to the original value when unloading the module.
pushenv( "LMOD_RC",               pathJoin( eessi_software_path, "/.lmod/lmodrc.lua" ) )
