# Tcl package index file for Tkprint 1.1

# Copyright(C) I.B.Findleton, 1999. All Rights Reserved

proc TkPrintInit { dir } {

	load [file join $dir tkprt11.dll] tkprint
	source [file join $dir window.tcl]
	}

package ifneeded Tkprint 1.1 "[list TkPrintInit $dir]"

