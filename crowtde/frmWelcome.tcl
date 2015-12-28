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
 
namespace eval ::frmWelcome {
	variable vars
	array set vars [list progress 0]
	
	variable wInfo
	array set wInfo ""
}
 
proc ::frmWelcome::show {path} {
	variable wInfo
	set frmWelcome [toplevel $path]

	set logo [::crowImg::get_image crow_logo]
	set img [label $frmWelcome.img -image $logo -relief groove -bd 2]
	set pbr [ProgressBar $frmWelcome.pbr -maximum 10 -variable ::frmWelcome::vars(progress) -relief groove -bd 1 -fg blue]
	pack $img -expand 1 -fill both
	pack $pbr -fill x
	wm withdraw $frmWelcome
	wm overrideredirect $frmWelcome 1
	wm deiconify $frmWelcome
	update
	set geometry [split [lindex [split [wm geometry $frmWelcome] "+"] 0] "x"]
	set w [lindex $geometry end-1]
	set h [lindex $geometry end]
	set x [expr {([winfo screenwidth .]/2 - $w/2)}]
	set y [expr {([winfo screenheight .]/2 - $h/2)}]
	wm geometry $frmWelcome +$x+$y
	wm resizable $frmWelcome 0 0
	set wInfo(frmWelcome) $frmWelcome
}

proc ::frmWelcome::bye {} {
	variable wInfo	
	destroy $wInfo(frmWelcome)
}

proc ::frmWelcome::incr_progress {} {
	variable vars
	incr vars(progress)
	update
}

