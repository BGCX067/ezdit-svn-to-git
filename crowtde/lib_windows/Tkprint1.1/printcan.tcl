# --- printcan.tcl --- Test routine for TkPrint 1.1
#
# Copyright(C) I.B.Findleton, 1999. All Rights Reserved

# This script can be used to demonstrate the features of the
# TkPrint 1.1 package. This script shows how to capture a
# Canvas to a metafile or an image file, and how to print
# windows or captured metafiles to a native Windows printer.

package require Tkprint

# Set some default values...
#
# Here I am assuming that the metafile format is Enhanced, the only generally
# useful format supported under 32 bit Windows environments. The default file
# name is "test" with the "emf" extension.
#
# Note that the other possible metafile formats, Aldus and Windows 3.1, are not
# usually supported by newer applications, and, in the case of the Windows 3.1
# format, the images can not be scaled.
#
# Setting the color depth to something
# other than 24 will cause the dithering routines to operate on the image. Usually,
# the printer driver will do a better job than the ditering routines, but, it
# does depend on the image and the printer.
#
# By changing the values of the XOrigin and YOrigin locations, the image can be
# placed anywhere on the page. Note that the values are in inches. It is possible
# to put the image in a location that causes part of the image to not be on the
# page. Use the scale factors to adjust the size of metafile images.
#
# Note that the scale factors can be set to any arbitrary value. This will cause
# undesireable distortion of the image if consideration is not given to the aspect
# ratio of the original display used to create the canvas.

set Data(FileName) "test.emf"
set Data(Format) enhanced
set Data(ColorDepth) 24
set Data(XOrigin) 0.0
set Data(YOrigin) 0.0
set Data(Paginate) 1
set Data(XScale) 1.0
set Data(YScale) 1.0

# Create a labeled text entry

proc LabeledEntry { w label var args } {

	catch { destroy $w }

	set f [frame $w]

	eval { entry $f.entry -textvariable $var -width 30  } $args
	label $f.label -text $label

	pack $f.entry -side right -anchor e
	pack $f.label -side left -anchor w -fill x

	return $w
	}

# Prompt the user for the values of the options to be used...

proc SetOptions {} {

	global Data

	catch { destroy .prompt }

	set f [toplevel .prompt]

	set f0 [frame $f.actions -bd 2 -relief ridge]
	button $f0.ok -text "Ok" -command { destroy .prompt }

	set f1 [frame $f.options -bd 2 -relief ridge]
	radiobutton $f1.enhanced -text "Enhanced Metafile Format" -variable Data(Format) -value enhanced -anchor w
	radiobutton $f1.aldus -text "Aldus Placable Metafile Format" -variable Data(Format) -value aldus -anchor w
	radiobutton $f1.windows -text "Windows 3.1 Metafile Format" -variable Data(Format) -value windows -anchor w
	checkbutton $f1.paginate -text "Print Page Header" -variable Data(Paginate) -anchor w

	set f2 [LabeledEntry $f1.label "Metafile File Name" Data(FileName) -width 20]
	set f3 [LabeledEntry $f1.color "Color Depth in bits (1,4,8 or 24)" Data(ColorDepth) -width 5 ]
	set f4 [LabeledEntry $f1.xorg "Horizontal location in inches" Data(XOrigin) -width 5]
	set f5 [LabeledEntry $f1.yorg "Vertical location in inches" Data(YOrigin) -width 5]
	set f6 [LabeledEntry $f1.xscale "Horizontal scale factor" Data(XScale) -width 5]
	set f7 [LabeledEntry $f1.yscale "Vertical scale factor" Data(YScale) -width 5]

	pack $f1.enhanced $f1.aldus $f1.windows $f1.paginate $f2 $f3 $f4 $f5 $f6 $f7 \
							-side top -fill x -expand y -anchor w

	pack $f1

	pack $f0.ok -side left
	pack $f0 -expand y -fill x

	tkwait window .prompt

	}

proc OptionValue { value yes no } {

	if { $value != 0 } { return $yes } else { return $no }
	}

proc IsEqual { value test yes no } {

	if { $value == $test } { return $yes } else { return $no }
	}

proc testit {} {

	global Data

	catch { destroy .actions .image }

	set f1 [frame .actions -bd 2 -relief ridge]
	set f2 [frame .image -bd 2 -relief ridge]

	button $f1.b1 -text "Print Canvas" -command \
				{SetOptions; update; PrintWindow .image.c -position $Data(XOrigin),$Data(YOrigin) \
								-paginate [OptionValue $Data(Paginate) true false] \
								-colordepth $Data(ColorDepth) }
	button $f1.b2 -text "To Clipboard" -command \
				{ MetaFile .image.c -clipboard true -format $Data(Format) }
	button $f1.b3 -text "Create MetaFile" -command \
				{ MetaFile .image.c -file $Data(FileName) -format $Data(Format)}
	button $f1.b4 -text "Print MetaFile" -command \
				{ SetOptions; update; MetaFile .image.c -format $Data(Format) -position $Data(XOrigin),$Data(YOrigin) \
									-paginate [OptionValue $Data(Paginate) true false] \
									-scale $Data(XScale)[IsEqual $Data(YScale) 1.0 "" ,$Data(YScale)] }
	button $f1.b5 -text "Capture Image" -command \
				{ Capture .image.c -clipboard true -colordepth $Data(ColorDepth) }
	button $f1.b6 -text "Options" -command \
				{ SetOptions }

	pack $f1.b1 $f1.b2 $f1.b3 $f1.b4 $f1.b5 $f1.b6 -side left

	set cv [canvas $f2.c -height 400 -width 500 -background gray80]
	set tx [text $f2.c.t -foreground red -background yellow]

	 # Draw Some Stuff on the Canvas

	 $cv create oval 100 100 200 200 -fill red
	 $cv create oval 200 200 300 300 -fill green
	 $cv create oval 100 100 300 300 -fill blue
	 $cv create oval 100 300 200 200 -fill yellow

	 $cv create line 10 10 10 390 490 390 490 10 10 10 -width 2

	 $cv create text 20 20 -text "This is a test canvas" -font "Arial 20" -anchor nw

	 set bt [button $f2.c.b1 -text "A Button"]

	 $cv create window 20 320 -height 60 -width 340 -window $tx -anchor nw
	 $cv create window 400 320  -width 60 -height 20 -window $bt -anchor nw

	 $tx insert end "This is text in an embedded window..."

	 pack $cv -fill both -expand yes

	 pack $f1 $f2 -side top -fill x -expand yes

    wm title . "Print Canvas Test Harness"

}

testit
