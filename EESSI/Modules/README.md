# Development of a module to load an EESSI software stack

## External information

  * [EESSI Software Layer issue $68](https://github.com/EESSI/software-layer/issues/68)

## Possible approaches

The main problem is to detect the operating system and the necessary characteristics to determine the
optimal version of the software stack.

Some options:
  1. Let the system define two environment variables: one for the OS and one for the CPU
     architecture as would be returned by ``archspec cpu``. The module file can then contain
     a mapping table to map that architecture onto the best available stack. This table could
     be generated offline via a python script that uses archspec and a list of architectures for
     which EESSI is available. The module can then completely rely on functions that are 
     guaranteed to be available in Lmod.
  2. If we allow the use of the Lua module ``posix.uname`` it is easy to determinte the 
     operating system. One could also determine the processor family, but this is not enough
     to accurately determine the right software stack. It is only enough to run the generic stack
     for that family.
  3. As the steps taken in the previous option are enough to select the right compatibility
     layer, we can then run a script from the init directory to determine the right version of 
     the software stack. This requires some more advanced Lua programming to capture the output
     of a command run in the shell.

## Some testing of system behaviour

| System                                          | uname -s | uname -m |
|-------------------------------------------------|----------|----------|
| MacBook Pro macOS 11.2.2 Core i5-7xxx Kaby Lake | Darwin   | x86_64   |
| Intel Broadwell E5-2680, CentOS 7               | Linux    | x86_64   |
| AMD zen2 EPYC 7282, CentOS 8                    | Linux    | x86_64   |
| AMD zen2 EPYC 7742, Cray                        | Linux    | x86_64   |

## Suggestions from others

