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

package provide inputDlg 1.0
package require BWidget

namespace eval ::inputDlg {
	variable txtVar
}

proc ::inputDlg::show {path title defTxt args} {
	if {[winfo exists $path]} {destroy $path}
	array set argv "-width 30" 	
	if {[llength $args]} {array set argv $args}
	set ::inputDlg::txtVar $defTxt 
	Dialog $path -title $title -modal local
	set fme [$path getframe]
	set txtInput [entry $fme.txt -textvariable ::inputDlg::txtVar -relief groove -width $argv(-width)]
	
	set fmeBtn [frame $fme.fmeBtn -bd 1 -relief sunken]
	set btnOk [button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] -command [list $path enddialog "OK"] -bd 1 -default active]
	set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] -command [list $path enddialog "CANCEL"] -bd 1]	
	pack $btnOk -expand 1 -fill both -padx 2 -pady 2 -side left
	pack $btnCancel -expand 1 -fill both -padx 2 -pady 2 -side left
	
	pack $txtInput -expand 1 -fill x -pady 1 -side top
	pack $fmeBtn -expand 1 -fill x -pady 1 -side top
	focus $txtInput	
	$txtInput selection range 0 end
	bind $txtInput <KeyRelease-Return> [list $path enddialog "OK"]
	bind $btnOk <KeyRelease-Return> [list $path enddialog "OK"]
	bind $btnCancel <KeyRelease-Return> [list $path enddialog ""]
	set ret [$path draw]
	destroy $path
	return [list $ret $::inputDlg::txtVar]
}

#console show

