# This file is automatically generated and will be overwritten
namespace eval twapi {
    variable package_name twapi
    if {$::tcl_platform(machine) eq "amd64"} {
        variable dll_base_name twapi64
    } else {
        variable dll_base_name twapi
    }
}
# The build_id is generated automatically on every build
set twapi::build_id 1272869615
