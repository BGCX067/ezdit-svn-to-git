
# @@ Meta Begin
# Package zlibtcl 1.2.3
# Meta activestatetags ActiveTcl Public
# Meta as::author      {Jan Nijtmans}
# Meta as::origin      http://sourceforge.net/projects/tkimg
# Meta as::origin      http://sourceforge.net/projects/tkimg
# Meta description     A variant of the libz system library made suitable
# Meta description     for direct loading as a Tcl package.
# Meta license         BSD
# Meta platform        macosx-universal
# Meta require         {Tcl 8.4}
# Meta summary         zlib Support
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded zlibtcl 1.2.3 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require Tcl 8.4

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            load [file join {@} libzlibtcl1.2.3.dylib]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide zlibtcl 1.2.3

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
