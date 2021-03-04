local eessi_version = "2020.12"
local eessi_root = "/cvmfs/pilot.eessi-hpc.org/"

--
-- We do need some packages unfortunately that should be pretty standard.
--
local posix = require( 'posix' )

--
-- Some initialisations.
-- 

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

local archspec_cpu = os.getenv( 'EESSI_ARCHSPEC_CPU' ) 
if ( mode() == 'load' ) then
    if ( archspec_cpu == nil ) then
        LmodMessage( 'EESSI: No CPU architecture given, so the generic ' .. eessi_cpu_family .. ' software stack will be used. ' ..
                      'Set the environment variable EESSI_ARDHSPEC_CPU to the CPU in your system as determined by archspec to get an optimized software stack.'  )
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
-- pushenv( "PS1", "[EESSI pilot " .. eessi_version .. "] $ " )

-- -----------------------------------------------------------------------------
--
-- General initialisation and initialisation of the compatibility layer
--

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
                       pathJoin( eessi_root, eessi_version, '/init/eessi_software_subdir_for_host.py' ) .. ' ' ..  
                       pathJoin( eessi_root, eessi_version )
LmodMessage( 'TODO: Can we now run ' .. detect_command .. ' and capture the output instead of using the full mapping?')

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
local eessi_software_path = eessi_root .. eessi_version .. "/software/" .. eessi_software_subdir
-- Double check that the software path indeed exists. Otherwise there is a problem with the mounts
-- or the EESSI stack is seriously broken.
if ( not isDir( eessi_software_patjh ) ) then
    LmodError(  'EESI: Software directory ' .. eessi_softwarE_path .. ' not found, the EESSI distribution seems to be broken' )
end
setenv( "EESSI_SOFTWARE_SUBDIR", eessi_software_subdir )
setenv( "EESSI_SOFTWARE_PATH",   eessi_software_path )

-- This block still needs refinement as the init script allows for alternative module 
-- structures.
setenv( "EESSI_MODULE_PATH",     pathJoin( eessi_software_path, "/modules/all" ) )
prepend_path( "MODULEPATH",      pathJoin( eessi_software_path, "/modules/all" ) )

-- Set LMOD_RC. This may be a problem if it is already set in the system for other reasons!
-- We use pushenv to ensure that it is set back to the original value when unloading the module.
pushenv( "LMOD_RC",               pathJoin( eessi_software_path, "/.lmod/lmodrc.lua" ) )
