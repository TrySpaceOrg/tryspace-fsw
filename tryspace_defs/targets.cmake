######################################################################
#
# Master config file for cFS target boards
#
######################################################################

# The MISSION_NAME will be compiled into the target build data structure
# as well as being passed to "git describe" to filter the tags when building
# the version string.
SET(MISSION_NAME "TrySpace")

# MDG dedication. September 16, 2023 changed us all. RIP.
SET(SPACECRAFT_ID 0x17)

# The "MISSION_GLOBAL_APPLIST" is a set of apps/libs that will be built
# for every defined target.  These are built as dynamic modules
# and must be loaded explicitly via startup script or command.
# This list is effectively appended to every TGTx_APPLIST in targets.cmake.
# Example:
list(APPEND MISSION_GLOBAL_APPLIST
    #
    # cFS Apps
    #
        ci_lab
        #sch
        to_lab
)

# FT_INSTALL_SUBDIR indicates where the black box test data files (lua scripts) should
# be copied during the install process.
SET(FT_INSTALL_SUBDIR "host/functional-test")

# Each target board can have its own HW arch selection and set of included apps
SET(MISSION_CPUNAMES cpu1)

SET(cpu1_PROCESSORID 1)
SET(cpu1_APPLIST) # Note: Using all ${MISSION_GLOBAL_APPLIST} automatically
SET(cpu1_FILELIST cfe_es_startup.scr)
SET(cpu1_SYSTEM amd64-linux-gnu)
