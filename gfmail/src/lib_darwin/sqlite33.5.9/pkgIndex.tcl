#
# Tcl package index file
#
# Note sqlite*3* init specifically
#
package ifneeded sqlite3 3.5.9 \
    [list load [file join $dir libsqlite3.5.9.dylib] Sqlite3]
