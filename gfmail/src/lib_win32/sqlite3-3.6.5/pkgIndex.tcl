#
# Tcl package index file
#
# Note sqlite*3* init specifically
#
package ifneeded sqlite3 3.6.5 \
    [list load [file join $dir sqlite365.dll] Sqlite3]
