
# @@ Meta Begin
# Package img::gif 1.3
# Meta activestatetags ActiveTcl Public Img
# Meta as::origin      http://sourceforge.net/projects/tkimg
# Meta category        Tk Image Format
# Meta description     This s support for the gif image format.
# Meta platform        linux-glibc2.3-ix86
# Meta require         {img::base 1.3-2}
# Meta require         {Tcl 8.4-9}
# Meta require         {Tk 8.4-9}
# Meta subject         gif
# Meta summary         gif Image Support
# @@ Meta End


if {![package vsatisfies [package provide Tcl] 8.4]} return

package ifneeded img::gif 1.3 [string map [list @ $dir] {
        # ACTIVESTATE TEAPOT-PKG BEGIN REQUIREMENTS

        package require img::base 1.3-2
        package require Tcl 8.4-9
        package require Tk 8.4-9

        # ACTIVESTATE TEAPOT-PKG END REQUIREMENTS

            load [file join {@} libtkimggif1.3.so]

        # ACTIVESTATE TEAPOT-PKG BEGIN DECLARE

        package provide img::gif 1.3

        # ACTIVESTATE TEAPOT-PKG END DECLARE
    }]
