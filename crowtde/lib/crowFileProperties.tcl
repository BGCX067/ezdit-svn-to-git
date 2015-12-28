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

package provide crowFileProperties 1.0
package require BWidget

namespace eval ::crowFileProperties {
	variable vars
	array set vars ""
	variable wInfo
	array set wInfo ""
}

proc ::crowFileProperties::show {path fpath} {
	variable vars
	variable wInfo
	
	switch -exact -- $::tcl_platform(platform) {
		"windows" {
			twapi::file_properties_dialog $fpath
			return
		}
		"unix" -
		default {}
	}
	
	Dialog $path -title [::msgcat::mc "File Properties"] -modal local
	set fmeMain [$path getframe]
	set nb [NoteBook $fmeMain.nb ]
	$nb insert end general -text [::msgcat::mc "General"]
	$nb insert end permissions -text [::msgcat::mc "Permissions"]
	set fmeGeneral [$nb getframe general]
	set fmePermissions [$nb getframe permissions]

	array set finfo ""
	file stat $fpath finfo
	set finfo(atime) [clock format $finfo(atime) -format "%x %r"]
	set finfo(mtime) [clock format $finfo(mtime) -format "%x %r"]
	set finfo(ctime) [clock format $finfo(ctime) -format "%x %r"]
	set vars(size) ""
	set cut 0
	for {set i [expr [string length $finfo(size)]-1]} {$i >= 0} {incr i -1} {
		incr cut
		set vars(size) [string index $finfo(size) $i]$vars(size)
		if {$cut == 3} {
			set cut 0
			set vars(size) ",$vars(size)"
		}
	}
	set vars(size) [string trim $vars(size) ","]
	
	set fmePathName [frame $fmeGeneral.fmePathName -bd 2 -relief groove -pady 2 -padx 2]
	grid [label $fmePathName.lblPath -text [::msgcat::mc "Location:"] -anchor w -justify left ] \
		-row 0 -column 0 -sticky "we"  -pady 1
	grid [label $fmePathName.txtPath -text [file dirname $fpath] -anchor w -justify left  -width 25] \
		-row 0 -column 1 -sticky "we" -pady 1 -padx 3
	grid [label $fmePathName.lblName -text [::msgcat::mc "Name:"] -anchor w -justify left ] \
		-row 1 -column 0 -sticky "we" -pady 1
	grid [label $fmePathName.txtName -text [file tail $fpath] -bd 1 -relief ridge -anchor w -justify left] \
		-row 1 -column 1 -sticky "we" -pady 1 -padx 3
	grid rowconfigure $fmePathName 0 -weight 1	
	grid columnconfigure $fmePathName 1 -weight 1	
	pack $fmePathName -fill x -padx 3 -pady 3

	set fmeTypeSize [frame $fmeGeneral.typeSize -bd 2 -relief groove -padx 2 -pady 2]
	grid [label $fmeTypeSize.lblType -text [::msgcat::mc "Type:"] \
		-anchor w -justify left ] \
		-row 0 -column 0 -sticky "we" -pady 1
	grid [label $fmeTypeSize.txtType -text [string toupper $finfo(type) 0 0] \
		-anchor w -justify left ] \
		-row 0 -column 1 -sticky "we" -pady 1
	grid [label $fmeTypeSize.lblSize -text [::msgcat::mc "Size:"] \
		-anchor sw -justify left ] \
		-row 1 -column 0 -sticky "we" -pady 1
	grid [label $fmeTypeSize.txtSize -text [concat $vars(size) "Btyes"]\
		-anchor w -justify left ] \
		-row 1 -column 1 -sticky "we" -pady 1
	grid rowconfigure $fmeTypeSize 1 -weight 1	
	grid columnconfigure $fmeTypeSize 1 -weight 1	
	pack $fmeTypeSize -fill x -padx 3 -pady 3

	set fmeTime [frame $fmeGeneral.fmeTime -bd 2 -relief groove -padx 2 -pady 2]
	grid [label $fmeTime.lblATime -text [::msgcat::mc "Accessed:"] -anchor w -justify left ] \
		-row 0 -column 0 -sticky "we" -pady 1
	grid [label $fmeTime.txtATime -text $finfo(atime) -anchor w -justify left ] \
		-row 0 -column 1 -sticky "we" -pady 1 -padx 2	
	grid [label $fmeTime.lblMTime -text [::msgcat::mc "Modified:"] -anchor w -justify left ] \
		-row 1 -column 0 -sticky "we" -pady 1
	grid [label $fmeTime.txtMTIme -text $finfo(mtime) -anchor w -justify left ] \
		-row 1 -column 1 -sticky "we" -pady 1 -padx 2
	grid [label $fmeTime.lblCTime -text [::msgcat::mc "Changed:"] -anchor w -justify left ] \
		-row 2 -column 0 -sticky "we" -pady 1
	grid [label $fmeTime.txtCTime -text $finfo(ctime) -anchor w -justify left ] \
		-row 2 -column 1 -sticky "we" -pady 1 -padx 2
	grid rowconfigure $fmeTime 3 -weight 1
	grid columnconfigure $fmeTime 2 -weight 1
	pack $fmeTime -expand 1 -fill both -padx 3 -pady 3
	
	set varList ""
	set mask 0x800
	set fme [TitleFrame $fmePermissions.fmeSid -text [::msgcat::mc "SID"] -bd 2 -relief groove ]
	grid $fme -row 0 -column 3 -sticky "news" -padx 5 -pady 2
	set fme [$fme getframe]
	array set bits [list suid [::msgcat::mc "Set UID"] sgid [::msgcat::mc "Set GID"] sticky "Sticky"]
	foreach bit "suid sgid sticky" {
		checkbutton $fme.chk$bit -text $bits($bit) -anchor w \
			-variable ::crowFileProperties::vars(sid,$bit)
		if {($mask & $finfo(mode))==0} {
			set vars(sid,$bit) 0
		} else {
			set vars(sid,$bit) 1
		}
		set mask [expr $mask>>1]
		pack $fme.chk$bit -side top -expand 1 -fill both
	}
	
	set col 0
	set mask 0x100
	array set acls [list owner [::msgcat::mc "Owner"] group [::msgcat::mc "Group"] other [::msgcat::mc "Other"]]
	array set attrs [list r [::msgcat::mc "Read"] w [::msgcat::mc "Write"] x [::msgcat::mc "execute"]]
	foreach acl "owner group other" {
		set fme [TitleFrame $fmePermissions.fme$acl -text $acls($acl) -bd 2 -relief groove ]
		grid $fme -row 0 -column $col -sticky "news" -padx 5 -pady 2
		set fme [$fme getframe]
		foreach bit "r w x" {
			checkbutton $fme.chk$bit -text $attrs($bit) -anchor w \
				-variable ::crowFileProperties::vars($acl,$bit)
			if {($mask & $finfo(mode))==0} {
				set vars($acl,$bit) 0
			} else {
				set vars($acl,$bit) 1
			}
			set mask [expr $mask>>1]
			pack $fme.chk$bit -side top -expand 1 -fill both
		}
		incr col
	}
		
	set fme [TitleFrame $fmePermissions.fmeOwner -text [::msgcat::mc "Owner"] -bd 2 -relief groove ]
	grid $fme -row 1 -column 0 -columnspan 4 -sticky "news" -padx 5 -pady 2
	set fme [$fme getframe]
	label $fme.lblUser -text [::msgcat::mc "Owner"] -anchor w -justify left
	label $fme.lblGroup -text [::msgcat::mc "Group"] -anchor w -justify left
	set vars(user) [::crowFileProperties::uid_to_name $finfo(uid)]
	set vars(group) [::crowFileProperties::gid_to_name $finfo(gid)]
	set vars(recursive) 0
	ComboBox $fme.cmbUser -textvariable ::crowFileProperties::vars(user) \
		-values [::crowFileProperties::get_users] -editable false 
	ComboBox $fme.cmbGroup -textvariable ::crowFileProperties::vars(group) \
		-values [::crowFileProperties::get_groups] -editable false 
	checkbutton $fme.chkRecursive -text [::msgcat::mc "recursive apply"] -anchor w \
		-variable ::crowFileProperties::vars(recursive) -state disabled
	if {$finfo(type) eq "directory"} {$fme.chkRecursive configure -state normal}
	grid $fme.lblUser -row 0 -column 0 -sticky "we"
	grid $fme.cmbUser -row 0 -column 1 -sticky "we" -padx 5
	grid $fme.lblGroup -row 1 -column 0 -sticky "we"
	grid $fme.cmbGroup -row 1 -column 1  -sticky "we" -padx 5
	grid $fme.chkRecursive -row 2 -column 0 -columnspan 2 -sticky "we"
	grid rowconfigure $fme 2 -weight 1	
	grid columnconfigure $fme 1 -weight 1
	
	grid rowconfigure $fmePermissions 2 -weight 1	
	grid columnconfigure $fmePermissions 4 -weight 1	
	
	$nb raise general

	pack [frame $fmeMain.sep1] -side top -padx 5 -pady 2
	pack $nb -expand 1 -fill both -padx 5 -side top

	set fmeButton [frame $fmeMain.fmeButton -bd 1 -relief raised]
	button $fmeButton.btnOk -text [::msgcat::mc "Accept"] -command [list ::crowFileProperties::btn_accept_click $fpath]
	button $fmeButton.btnCancel -text [::msgcat::mc "Cancel"] -command [list $path enddialog ""]

	pack $fmeButton.btnOk -expand 1 -side left -padx 5 -pady 5
	pack $fmeButton.btnCancel -expand 1 -side left -padx 5 -pady 5
	pack $fmeButton -expand 0 -fill x -side top -padx 5
	pack $nb -expand 1 -fill both
	wm minsize $path 420 400
	set wInfo(dialog) $path
	$path draw
	destroy $path
}

proc ::crowFileProperties::btn_accept_click {path} {
	variable vars
	variable wInfo
	::crowFileProperties::chown $path $vars(user) $vars(group) $vars(recursive)
	set mode 0
	foreach bit [list $vars(sid,suid) $vars(sid,sgid) $vars(sid,sticky) \
			$vars(owner,r) $vars(owner,w) $vars(owner,x) \
			$vars(group,r) $vars(group,w) $vars(group,x) \
			$vars(other,r) $vars(other,w) $vars(other,x)] {
		set mode [expr (($mode<<1) | $bit)]
	}
	::crowFileProperties::chmod $path $mode $vars(recursive)
	$wInfo(dialog) enddialog ""
}

proc ::crowFileProperties::chown {path user group recursive} {
	array set finfo ""
	file stat $path finfo
	set uname [::crowFileProperties::uid_to_name $finfo(uid)]
	set gname [::crowFileProperties::uid_to_name $finfo(gid)]
	if {![string equal $uname $user] || ![string equal $gname $group]} {
		if {$recursive} {
			exec chown -R ${user}.${group} $path
		} else {
			exec chown ${user}.${group} $path
		}
	}
}

proc ::crowFileProperties::chmod {path mode recursive} {
	array set finfo ""
	file stat $path finfo
	if {$mode != ($finfo(mode) & 0xfff)} {
		if {$recursive} {
			exec chmod -R [format "%o" $mode] $path
		} else {
			exec chmod [format "%o" $mode] $path
		}
	}
}

proc ::crowFileProperties::get_group_table {} {
	set fd [open "/etc/group" r]
	set groups [split [read $fd] "\n"]
	close $fd
	set ret ""
	foreach group $groups {
		set items [split $group ":"]
		if {[llength $items]==4} {
			lappend ret [lindex $items 2] [lindex $items 0]
		}
	}
	return $ret
}

proc ::crowFileProperties::get_user_table {} {
	set fd [open "/etc/passwd" r]
	set users [split [read $fd] "\n"]
	close $fd
	set ret ""
	foreach user $users {
		set items [split $user ":"]
		if {[llength $items]==7} {
			lappend ret [lindex $items 2] [lindex $items 0]
		}
	}
	return $ret
}

proc ::crowFileProperties::get_groups {} {
	set ret ""
	array set groups [::crowFileProperties::get_group_table]
	foreach key [array names groups] {
		lappend ret $groups($key)
	}
	return [lsort -dictionary $ret]
}

proc ::crowFileProperties::get_users {} {
	set ret ""
	array set users [::crowFileProperties::get_user_table]
	foreach key [array names users] {
		lappend ret $users($key)
	}
	return [lsort -dictionary $ret]
}

proc ::crowFileProperties::uid_to_name {uid} {
	array set users [::crowFileProperties::get_user_table]
	return $users($uid)
}

proc ::crowFileProperties::gid_to_name {gid} {
	array set groups [::crowFileProperties::get_group_table]
	return $groups($gid)
}
