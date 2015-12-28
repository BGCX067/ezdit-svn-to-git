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

namespace eval ::frmCheckSave {
	variable vars
	array set vars ""
	
	variable wInfo
	array set wInfo ""
}
 
proc ::frmCheckSave::show {path} {
	variable vars
	variable wInfo
	if {[winfo exists $path]} {destroy $path}	
	set editors [string trim [::fmeTabEditor::get_all_editor]]
	if {$editors eq ""} {return 1}
	set vars(lbox) ""
	set prjPath [::fmeProjectManager::get_project_path]
	set len [expr [string length $prjPath] + 1]
	set lastList ""
	foreach editor $editors {
		if {[::crowEditor::get_ch_flag $editor]} {
			set fpath [::crowEditor::get_file $editor]
			
			if {[string first $prjPath $fpath] != 0} {
				lappend lastList $fpath
			} else {
				lappend vars(lbox) [string range $fpath $len end]
			}
		}
	} 
	foreach item $lastList {lappend vars(lbox) $item}
	if {$vars(lbox) eq ""} {return 1}
	set frmMain [Dialog $path -modal local -title [::msgcat::mc "Save"]]
	wm minsize $path 400 400
	wm resizable $path 1 1
	set fmeMain [$frmMain getframe]
	
	set title [label $fmeMain.title -anchor w -justify left \
		-text [::msgcat::mc "Save files ?"]]
	set lbox [listbox $fmeMain.lbox \
		-bg white \
		-relief groove \
		-highlightthickness 0 \
		-listvariable ::frmCheckSave::vars(lbox)]
	
	set fmeBtn [frame $fmeMain.fmeBtn -bd 1 -relief sunken]
	set btnYes [button $fmeBtn.btnYes -text [::msgcat::mc "Yes"] \
		-command [list $path enddialog YES]]
	set btnNo [button $fmeBtn.btnNo -text [::msgcat::mc "No"] \
		-command [list $path enddialog NO]]
	set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] \
		-command [list $path enddialog CANCEL]]
	pack $btnYes -expand 1 -side left -fill both -padx 2 -pady 2
	pack $btnNo -expand 1 -side left -fill both -padx 2 -pady 2
	pack $btnCancel -expand 1 -side left -fill both -padx 2 -pady 2
	
	pack $title -fill x -padx 2
	pack $lbox -expand 1 -fill both -pady 1 -padx 2
	pack $fmeBtn -fill both -fill x -pady 1 -padx 2

	set ret [$path draw]
	if {$ret eq "-1"} {set ret "CANCEL"}
	if {$ret eq "" || $ret eq "CANCEL"} {return 0}
	if {$ret eq "NO"} {
		foreach editor $editors {
			if {[::crowEditor::get_ch_flag $editor]} {::crowEditor::set_ch_flag $editor 0}
		}
		return 1
	}
	foreach editor $editors {
		if {[::crowEditor::get_ch_flag $editor]} {::crowEditor::save $editor}
	}
	return 1
}


