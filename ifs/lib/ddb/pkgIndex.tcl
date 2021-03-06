# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.
package ifneeded ::ddb::dbInfo 1.0 [list source [file join $dir db_info.tcl]]
package ifneeded ::ddb::sqlite 1.0 [list source [file join $dir sqlite.tcl]]
package ifneeded ::ddb::tableview 1.0 [list source [file join $dir tableview.tcl]]
package ifneeded ::ddb::validator 1.0 [list source [file join $dir validator.tcl]]


