if {![package vsatisfies [package provide Tcl] 8.3]} {return}
package ifneeded mime 1.4.1 [list source [file join $dir mime.tcl]]
