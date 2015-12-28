##################################################################################
# Copyright (C) 2006-2007 Tai, Yuan-Liang                                        #
#                                                                                #
# This program is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by           #
# the Free Software Foundation; either version 2 of the License, or              #
# (at your option) any later version.                                            #
#                                                                                #
# This program is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  #
# GNU General Public License for more details.                                   #
#                                                                                #
# You should have received a copy of the GNU General Public License              #
# along with this program; if not, write to the Free Software                    #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA   #
##################################################################################

package provide crowPanedWindow 1.0

namespace eval ::crowPanedWindow {
	variable wInfo
	array set wInfo "-SashHeight 3 -SashBorderWidth 4 -SashWidth 4 -SashPad 3"
	
	variable vars
	array set vars ""
}
proc ::crowPanedWindow::crowPanedWindow {path orient} {
	variable wInfo
	variable vars
	
	set fmeMain [frame $path]
	set sash [frame $fmeMain.sash -relief groove -bd $wInfo(-SashBorderWidth)]
	set fme1 [frame $fmeMain.fme1 -relief ridge -bd 0]
	set fme2 [frame $fmeMain.fme2 -relief ridge -bd 0]
	
	set fme1_t1 [frame $fme1.t1 -bd 4 -relief ridge ]
	set fme1_t2 [frame $fme1.t2 -bd 4 -relief ridge ]
	set fme1_btn [label $fme1.btn -text "X" -image [::crowImg::get_image close_frame1] -state disabled]
	set fme1_body [frame $fme1.body -bg #987654]
	
	if {$orient eq "h"} {
		place $fme1 -x 0 -y 0 -width 50 -relheight 1.0
		place $sash -x 50 -y 0 -width $wInfo(-SashWidth) -relheight 1.0
		place $fme2 -x 55 -y 0 -width 50 -relheight 1.0
	} else {
		place $fme1 -x 0 -y 0 -relwidth 1.0 -height 50
		place $sash -x 0 -y 50 -relwidth 1.0 -height $wInfo(-SashWidth) 
		place $fme2 -x 0 -y 55 -relwidth 1.0 -height 50		
	}
	set vars($fmeMain,oldPos) 0
	
	set wInfo($fmeMain,fme1) $fme1
	set wInfo($fmeMain,fme1_t1) $fme1_t1
	set wInfo($fmeMain,fme1_t2) $fme1_t2
	set wInfo($fmeMain,fme1_body) $fme1_body
	set wInfo($fmeMain,fme1_btn) $fme1_btn
	set wInfo($fmeMain,fme2) $fme2
	set wInfo($fmeMain,sash) $sash
	set vars($fmeMain,motionState) 0
	set vars($fmeMain,orient) [string tolower [string index $orient 0]]

	bind $fme1 <Configure> [list ::crowPanedWindow::fme1_configure $fmeMain %W]
	bind $fme1_btn <Enter> {%W configure -image [::crowImg::get_image close_frame2] -state normal}
	bind $fme1_btn <Leave> {%W configure -image [::crowImg::get_image close_frame1] -state disabled}
	bind $fme1_btn <ButtonRelease-1> [list ::crowPanedWindow::sash_dclick $fmeMain $sash]
	bind $sash <Enter> [list ::crowPanedWindow::sash_enter $fmeMain %W]
	bind $sash <Leave> [list ::crowPanedWindow::sash_leave $fmeMain %W]
	bind $sash <ButtonPress-1> [list ::crowPanedWindow::sash_press $fmeMain %W %X %Y]
	bind $sash <ButtonRelease-1> [list ::crowPanedWindow::sash_release $fmeMain %W %X %Y]
	if {$orient eq "h"} {
		bind $sash <Motion> [list ::crowPanedWindow::sash_motion $fmeMain %W %X]
	} else {
		bind $sash <Motion> [list ::crowPanedWindow::sash_motion $fmeMain %W %Y]
	}	
	bind $path <Configure> {::crowPanedWindow::fmeMain_configure %W}
	bind $sash <Double-Button-1> [list ::crowPanedWindow::sash_dclick $fmeMain %W]
	
	return $path
}

proc ::crowPanedWindow::sash_enter {widget sash} {
	variable vars
	if {$vars($widget,orient) eq "h"} {
		$sash configure -cursor sb_h_double_arrow
	} else {
		$sash configure -cursor sb_v_double_arrow
	}
}

proc ::crowPanedWindow::sash_leave {widget sash} {
	$sash configure -cursor arrow
}

proc ::crowPanedWindow::sash_dclick {widget sash} {
	variable wInfo
	variable vars
	if {$vars($widget,orient) eq "h"} {
		set pos [winfo x $sash]
		if {$pos > (0 + $wInfo(-SashWidth))} {
			::crowPanedWindow::sash_press $widget $sash $pos 0
			set vars($widget,motionState) 2
			::crowPanedWindow::sash_motion $widget $sash 0
			set vars($widget,motionState) 0
			set vars($widget,oldPos) $pos
		} else {
			if {$vars($widget,oldPos) < 30 } {set vars($widget,oldPos) 150}
			::crowPanedWindow::sash_press $widget $sash 0 0
			set vars($widget,motionState) 2
			::crowPanedWindow::sash_motion $widget $sash $vars($widget,oldPos)
			set vars($widget,motionState) 0
		}
	} else {
		set pos [winfo y $sash]
		if {$pos < ([winfo height $widget] - $wInfo(-SashWidth))} {
			::crowPanedWindow::sash_press $widget $sash 0 $pos
			set vars($widget,motionState) 2
			::crowPanedWindow::sash_motion $widget $sash [expr [winfo height $widget]-$wInfo(-SashWidth)]
			set vars($widget,motionState) 0
			set vars($widget,oldPos) $pos
		} else {
			if {$vars($widget,oldPos) == 0} {set vars($widget,oldPos) [expr [winfo height $widget] -150]}
			if {$vars($widget,oldPos) > [expr [winfo height $widget] -30] } {set vars($widget,oldPos) [expr [winfo height $widget] -150]}
			::crowPanedWindow::sash_press $widget $sash 0 0
			set vars($widget,motionState) 2
			set vars($widget,oy) 0
			::crowPanedWindow::sash_motion $widget $sash $vars($widget,oldPos)
			set vars($widget,motionState) 0
		}		
	}
}

proc ::crowPanedWindow::fmeMain_configure {widget} {
	variable wInfo
	variable vars
	::crowPanedWindow::sash_press $widget $wInfo($widget,sash) 0 0
	if {$vars($widget,orient) ne "h"} {
		set vars($widget,oy) [expr [winfo height $widget] - \
			$wInfo(-SashPad) - $wInfo(-SashWidth) - \
			[winfo height $wInfo($widget,fme1)]]
	}
	set vars($widget,motionState) 2
	::crowPanedWindow::sash_motion $widget $wInfo($widget,sash) 0
	set vars($widget,motionState) 0
}

proc ::crowPanedWindow::fme1_configure {widget fme1} {
	variable wInfo
	variable vars
	if {$vars($widget,orient) eq "h"} {
		set width [winfo width $fme1]
		place $fme1.btn -x [expr $width - 18] -y -2
		place $fme1.t1 -x 3 -y 4 -width [expr $width - 14] -height 3
		place $fme1.t2 -x 3 -y 9 -width [expr $width - 14]  -height 3
		place $fme1.body -x 1 -width [expr $width - 2] -y 17 \
			-height [expr [winfo height $fme1] -18]
	} else {
		set width [winfo width $fme1]
		set height [winfo height $fme1]
		place $fme1.btn -x -2 -y -2
		place $fme1.t1 -x 4 -y 3 -width 3 -height [expr $height - 14]
		place $fme1.t2 -x 9 -y 3 -width 3 -height [expr $height - 14]
		place $fme1.body -x 17  -width [expr $width - 18] \
			-height $height	
	}
}

proc ::crowPanedWindow::set_widget {widget fme1 fme2} {
	variable wInfo
	pack $fme1 -in $wInfo($widget,fme1_body) -expand 1 -fill both
	pack $fme2 -in $wInfo($widget,fme2) -expand 1 -fill both
}

proc ::crowPanedWindow::sash_motion {widget sash pos} {
	variable vars
	variable wInfo
	if {$vars($widget,motionState) == 0} {return}
	if {$vars($widget,orient) eq "h"} {
		set newX [expr $vars($widget,ox) + $pos - $vars($widget,X)]
		if {$newX < 0} {set newX 0}
		if {$newX > [winfo width $widget]} {set newX [winfo width $widget]}
		place configure $sash -x $newX
		raise $sash
		if {$vars($widget,motionState) == 2} { 
			place configure $wInfo($widget,fme1) -width [expr $newX - $wInfo(-SashPad)]
			array set arrInfo [place info $sash]
			set fme2X [expr $arrInfo(-x) + $arrInfo(-width) + $wInfo(-SashPad)]
			set fme2Width [expr [winfo width $widget] - $fme2X]
			place configure $wInfo($widget,fme2) -x $fme2X -width $fme2Width
		}
	} else {
		set newY [expr $vars($widget,oy)+$pos-$vars($widget,Y)]
		if {$newY < 0} {set newY 0}
		if {$newY > [winfo height $widget]} {set newY [expr [winfo height $widget]-$wInfo(-SashWidth)]}
		place configure $sash -y $newY
		raise $sash
		if {$vars($widget,motionState) == 2} { 
		array set arrInfo [place info $sash]
			set fme1Y [expr $arrInfo(-y) + $arrInfo(-height) + $wInfo(-SashPad)]
			place configure $wInfo($widget,fme1) -y $fme1Y \
				-height [expr [winfo height $widget] - $fme1Y]
			place configure $wInfo($widget,fme2) -y 0 -height [expr $arrInfo(-y) - $wInfo(-SashPad)]
		}		
	}
}

proc ::crowPanedWindow::get_sash_pos {widget} {
	variable wInfo
	variable vars
	if {$vars($widget,orient) eq "h"} {
		return [winfo x $wInfo($widget,sash)]
	} else {
		return [winfo y $wInfo($widget,sash)]
	}
}

proc ::crowPanedWindow::set_sash_pos {widget pos} {
	variable vars
	variable wInfo
	::crowPanedWindow::sash_press $widget $wInfo($widget,sash) 0 0
	if {$vars($widget,orient) ne "h"} {set vars($widget,oy) 0}
	set vars($widget,motionState) 2
	::crowPanedWindow::sash_motion $widget $wInfo($widget,sash) $pos
	set vars($widget,motionState) 0	
}

proc ::crowPanedWindow::sash_press {widget sash X Y} {
	variable vars
	variable wInfo
	if {$vars($widget,orient) eq "h"} {
		set vars($widget,ox) [winfo x $sash]
		set vars($widget,X) $X
		$sash configure -cursor sb_h_double_arrow
	} else {
		set vars($widget,oy) [winfo y $sash]
		set vars($widget,Y) $Y
		$sash configure -cursor sb_v_double_arrow
	}
	set ::crowPanedWindow::vars($widget,motionState) 1
}

proc ::crowPanedWindow::sash_release {widget sash X Y} {
	variable vars
	variable wInfo
	if {$vars($widget,orient) eq "h"} {
		set pos $X
	} else {
		set pos $Y
	}
	if {$vars($widget,motionState) == 1} {
		set vars($widget,motionState) 2
		::crowPanedWindow::sash_motion $widget $sash $pos
		set vars($widget,motionState) 0
	}
	#$sash configure -cursor arrow
}

