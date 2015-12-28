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


package provide crowFont 1.0

package require BWidget
package require msgcat

namespace eval ::crowFont {
	variable rcPath
	variable fonts
	array set fonts ""
	variable cmds
	array set cmds ""
	variable vars
	array set vars ""
}
proc ::crowFont::init {} {
	variable fonts
	variable rcPath
	variable cmds
	 
	set rcPath [file join $::env(HOME) ".CrowTDE" "Font.rc"]
	set fonts(smallest) [font create -family "Arial" -size "8"]
	set fonts(smaller) [font create -family "Arial" -size "10"]
	set fonts(medium) [font create -family "Arial" -size "11"]
	set fonts(larger) [font create -family "Arial" -size "12"]
	set fonts(largest) [font create -family "Arial" -size "14"]
	set fonts(menu) [font create -family "Arial" -size "8"]
	set fonts(text) [font create -family "Fixedsys" -size "12"]
	
	set cmds(smallest) "font create -family Arial -size 8"
	set cmds(smaller) "font create -family Arial -size 10"
	set cmds(medium) "font create -family Arial -size 11"
	set cmds(larger) "font create -family Arial -size 12"
	set cmds(largest) "font create -family Arial -size 14"
	set cmds(menu) "font create -family Arial -size 8"
	set cmds(text) "font create -family Fixedsys -size 12"
	
	if {![file exists $rcPath]} {::crowFont::save_rc}
	::crowFont::load_rc
	return
}

proc ::crowFont::btnApply_click {} {
	variable vars
	variable fonts
	variable cmds
	foreach item [list smaller medium larger menu text] {
		font configure $fonts($item) -family $vars(${item}_font) -size $vars(${item}_size)
		set cmds($item) [list font create -family $vars(${item}_font) -size $vars(${item}_size)]
		::crowFont::save_rc		
	}
}

proc ::crowFont::get_font {name} {
	variable fonts
	if {[info exists fonts($name)]} {return $fonts($name)}
	
	return $fonts(medium)
}

proc ::crowFont::get_frame {path} {
	variable fonts
	set fmeMain [frame $path]
	set fontList [lsort -dictionary [font families]]
	set sizeList [list 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]
	
	set lblTitle [label $fmeMain.lblTitle -text [::msgcat::mc "Fonts setting"] -bd 2 -relief groove]
	grid $lblTitle -row 0 -column 0 -columnspan 3 -sticky "we"
	
	array set labelMap [list  \
		smaller  [::msgcat::mc "Small font"]  \
		medium [::msgcat::mc "normal font"] \
		larger [::msgcat::mc "Large font"] \
		menu [::msgcat::mc "Menu font"] \
		text [::msgcat::mc "Editor font"] \
	]
	
	set row 1
	foreach item [list smaller medium larger menu text] {
		label $fmeMain.lbl$item -text $labelMap($item) -anchor w -justify left -font $fonts($item)
		set ::crowFont::vars(${item}_font) [font configure $fonts($item) -family]
		set ::crowFont::vars(${item}_size) [font configure $fonts($item) -size]
		ComboBox $fmeMain.cmb${item}Font -values $fontList -editable 0 \
			-highlightthickness 0 -relief groove \
			-textvariable ::crowFont::vars(${item}_font) \
			-entrybg white \
			-modifycmd [list ::crowFont::preview $fmeMain.lbl$item $item]
		ComboBox $fmeMain.cmb${item}Size -values $sizeList -editable 0 \
			-width 4 -highlightthickness 0 -relief groove \
			-textvariable ::crowFont::vars(${item}_size) \
			-entrybg white \
			-modifycmd [list ::crowFont::preview $fmeMain.lbl$item $item]
		
		grid $fmeMain.lbl$item -row $row -column 0 -sticky we
		grid $fmeMain.cmb${item}Font -row $row -column 1 -sticky we
		grid $fmeMain.cmb${item}Size -row $row -column 2 -sticky we
		incr row
	}
	set fmeBtn [frame $fmeMain.fmeBtn]
	set btnApply [button $fmeBtn.btnApply -text [::msgcat::mc "Apply"] -command {::crowFont::btnApply_click}]
	pack $btnApply -anchor e -padx 5 -pady 5 -ipadx 2 -ipady 2
	grid $fmeBtn -row $row -column 0 -sticky "news" -columnspan 3
	#incr row
	grid rowconfigure $fmeMain $row -weight 1
	grid columnconfigure $fmeMain 1 -weight 1
	
	return $fmeMain
}

proc ::crowFont::preview {widget item} {
	variable vars
	$widget configure -font [list $vars(${item}_font) $vars(${item}_size)]
} 

proc ::crowFont::set_font {name cmd} {
	variable fonts
	variable cmds
	font delete $fonts($name)
	set cmds($name) $cmd
	set fonts($name) [eval $cmd]
	::crowFont::save_rc
	return
}

proc ::crowFont::load_rc {} {
	variable fonts
	variable cmds
	variable rcPath
	if {![file exists $rcPath]} {return}
	set fd [open $rcPath r]
	set data [split [read -nonewline $fd] "\n"]
	close $fd
	foreach item $data {
		set f [split [string trim $item] ":"]
		::crowFont::set_font [lindex $f 0] [lindex $f 1]
	}
	return
}

proc ::crowFont::save_rc {} {
	variable rcPath
	variable cmds
	set fd [open $rcPath w]
	set fontList [array get cmds]
	foreach {key val} $fontList {puts $fd ${key}:${val}}
	close $fd
	return
}

::crowFont::init

