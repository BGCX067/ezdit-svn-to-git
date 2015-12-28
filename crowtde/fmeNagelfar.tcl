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

namespace eval ::fmeNagelfar {
	variable wInfo
	array set wInfo ""
	variable vars
	array set vars ""

	variable images
	array set images ""
	variable tagCounter 0
}

proc ::fmeNagelfar::check {fpath} {
	variable vars
	if {$fpath eq ""} {set fpath $vars(txtFile)}
	
	::fmeTaskMgr::raise "Nagelfar"
	::fmeNagelfar::clear_msg
	if {$fpath eq "" || ![file exists $fpath]} {return}
	set vars(txtFile) $fpath
	set tp [interp create]
	$tp eval [list set ::Nagelfar(embedded) 1]
	$tp eval [list source [file join $::crowTde::appPath "lib" "nagelfar.tcl"]]
	set ret [$tp eval [list synCheck $fpath [file join $::crowTde::appPath "lib" "syntaxdb.tcl"]]]	
	
	update idletasks
	foreach item $ret {
		if {[regexp {Line ([0-9]+): ([WE]) (.*)} $item -> line type msg]} {
			switch -- $type {
				W {set color "blue"}
				E {set color "red"}
				default {set color ""}
			}
			set out [format "[msgcat::mc Line] %d: %s" $line $msg]
			::fmeNagelfar::put_lmsg $out $fpath $line 0 $color
			update idletasks
		}
	}
	interp delete $tp
}

proc ::fmeNagelfar::choose_file {} {
	variable vars
	set ret [tk_getOpenFile -filetypes [list [list "ALL" "*.*"] ] -title [::msgcat::mc "Choose File"]]
	if {$ret eq "" || $ret eq "-1"} {return}
	set vars(txtFile) $ret
	return
}

proc ::fmeNagelfar::clear_msg {} {
	variable wInfo
	set txt $wInfo(txt)
	
	$txt configure -state normal
	$txt delete 0.0 end
	$txt configure -state disabled
}

proc ::fmeNagelfar::goto {fpath line pos} {
	::fmeProjectManager::file_open $fpath
	::fmeTabEditor::file_raise $fpath
	set editor [::fmeTabEditor::get_curr_editor]
	if {![winfo exists $editor]} {return}
	::crowEditor::goto_pos $editor $line.$pos
	focus [::crowEditor::get_text_widget $editor]
}


proc ::fmeNagelfar::init {path} {
	variable wInfo
	variable vars
	set fmeMain [frame $path]
	
	set fmeFun [frame $fmeMain.fmeFun -bd 1 -relief groove]
	set lblTitle [label $fmeFun.lblTitle -text [::msgcat::mc "File:"]]
	set txtFile [entry $fmeFun.txtFile -textvariable ::fmeNagelfar::vars(txtFile) \
		-disabledbackground white \
		-width 45 \
		-disabledforeground black \
		-state disabled ]
	set btnSel [button $fmeFun.btnSel -image [::crowImg::get_image ofolder] -command {::fmeNagelfar::choose_file}]
	set btnCheck [button $fmeFun.btnCheck -image [::crowImg::get_image syntax_check] -command {::fmeNagelfar::check ""}]
#	set btnClear [button $fmeFun.btnClear -image [::crowImg::get_image clear_output] -command {::fmeNagelfar::clear_msg}]
		
	bind $btnSel <Enter> [list puts sbar msg [::msgcat::mc "Select File..."]]
	bind $btnCheck <Enter> [list puts sbar msg [::msgcat::mc "Do Check"]]
	DynamicHelp::add $btnSel -text [::msgcat::mc "Select File"]
	DynamicHelp::add $btnCheck -text [::msgcat::mc "Do Check"]
	pack $lblTitle $txtFile $btnSel $btnCheck -side left -padx 2 -pady 1
#	pack $btnClear -side right -padx 2 -pady 1
	
	set sw [ScrolledWindow $fmeMain.sw]
	
	set txt [text $sw.txt \
		-height 5 \
		-bg white \
		-relief groove \
		-font [::crowFont::get_font text]]
	$sw setwidget $txt
	
	set m [menu $txt.menu -tearoff 0]
	$m add command -compound left -label [::msgcat::mc "Save Output..."] \
		-image [::crowImg::get_image save] \
		-command {::fmeNagelfar::save_output}
		
	$m add separator
	$m add command -compound left -label [::msgcat::mc "Clear"] \
		-image [::crowImg::get_image clear] \
		-command {::fmeNagelfar::clear_msg}
		
	bind $txt <ButtonRelease-3> [list tk_popup $m %X %Y]

	$txt configure -state disabled
	
	set wInfo(txt) $txt
	set wInfo(fmeMain) $fmeMain
	
	pack $fmeFun -fill x
	pack $sw -expand 1 -fill both 
	
	return $fmeMain
}

proc ::fmeNagelfar::put_lmsg {msg fpath line pos color} {
	variable wInfo
	variable tagCounter
	incr tagCounter
	set txt $wInfo(txt)
	
	$txt configure -state normal
	$txt insert end $msg
	$txt tag add tag$tagCounter "end -1 line linestart" "end -1 line lineend"

	if {$color ne ""} {
		$txt tag configure tag$tagCounter -foreground $color
	} 	
	
	$txt insert end "\n"
	$txt tag bind tag$tagCounter <ButtonPress-1> [list ::fmeNagelfar::goto $fpath $line $pos]
	$txt tag bind tag$tagCounter <Enter> "$txt configure -cursor hand2 ; $txt tag configure tag$tagCounter -underline 1"
	$txt tag bind tag$tagCounter <Leave> "$txt configure -cursor arrow ; $txt tag configure tag$tagCounter -underline 0"	
	$txt see end
	$txt configure -state disabled
}


proc ::fmeNagelfar::put_msg {msg} {
	variable wInfo
	set txt $wInfo(txt)
	
	$txt configure -state normal
	$txt insert end "$msg\n"
	$txt see end
	$txt configure -state disabled
}


proc ::fmeNagelfar::save_output {} {
	variable wInfo
	set txt $wInfo(txt)
		
	set ret [tk_getSaveFile -filetypes [list [list {All Type} {*.*}]] -title [::msgcat::mc "Save"]]
	if {$ret ne ""} {
		set fd [open $ret w]
		puts $fd [$txt get 0.0 end]
		close $fd
	}
}


