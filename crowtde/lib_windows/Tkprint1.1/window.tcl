# --- window.tcl --- Capture a window to a file or to a printer page

# Copyright (C) I.B.Findleton, 1999. All Rights reserved

# This file contains some basic implementations of the window capture and window
# printing functions of the Tkprint 1.1 package. This file is loaded into the interp
# whenever the extension is loaded.

package require Tkprint 1.1

# Make the window the topmost window on the screen

proc RaiseWindowToTop { w } {

# This manipulation of the window is just one way of bringing the desired window
# to the top of the window stack...

	wm iconify $w
	wm deiconify $w
}

proc GrabWindow { w { file "capture.bmp" } } {

	RaiseWindowToTop $w

# The delay of 500 ms is to allow time for the system to redraw the window to be
# captured. If the delay is too short, then the window contents will be captured
# incompletely.

	after 250 "GrabIt $w $file"
	puts stdout "Wait capture of $w ..."
	}

# Do the actual grab of the window contents

proc GrabIt { w file } {

	Capture $w -file $file
	puts stdout "Window $w captured to file $file!"
	}

# Print a window from the screen

proc PrintAWindow { w { title "" } } {

	RaiseWindowToTop $w

	after 250 "PrintIt $w \"$title\""
	puts stdout "Wait printing of $w ..."
	}

# Do the actual printing of the window

proc PrintIt { w title } {

	if { $title != "" } {
		PrintWindow $w -title $title
	} else {
		PrintWindow $w
		}
	puts stdout "Window $w printed!"
	}

# Get the text to be printed. This version checks for some selection, then if it finds
# a selection it returns only the selected lines for printing, otherwise, the entire
# contents of the text are returned.

proc GetTextToPrint { w } {

	set lines ""

	catch { set lines [$w get sel.first sel.last] }

	if { $lines == "" } {
		set lines [$w get 1.0 end]
		}
	return $lines
	}

# This function will allow manipulation of windows being captured before the image
# is actually grabbed. Such things as setting a title can be done.

proc ConfigureCaptureWindow { w title } {

	if { $title != "" } {
		wm title $w "$title"
		update idletasks;
		}
	}

