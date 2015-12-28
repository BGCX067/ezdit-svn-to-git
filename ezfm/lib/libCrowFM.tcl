package provide libCrowFM 1.0

namespace eval ::libCrowFM {
	variable Priv
	array set Priv [list SHOW_HIDDEN 1]
}

proc ::libCrowFM::bookmark_add {dir} {
	variable Priv
	set ret ""
	set rc [file join $::dApp::Priv(rcPath) bookmarks.txt]

	set fd [open $rc a]
	puts $fd $dir
	close $fd

	return
}

proc ::libCrowFM::bookmark_ls {} {
	variable Priv
	set ret ""
	set rc [file join $::dApp::Priv(rcPath) bookmarks.txt]
	if {[file exists $rc]} {
		set fd [open $rc r]
		set data [read -nonewline $fd]
		foreach {bk} [split $data "\n"] {
			lappend ret $bk
		}
		close $fd
	}
	return $ret
}


proc ::libCrowFM::dialog_error_show {errMsg} {
	variable Priv

	::ttk::dialog .eDlg \
		-icon "error" \
		-title [::msgcat::mc "Error"] \
		-message $errMsg \
		-labels [list ok [::msgcat::mc "Ok"]] \
		-buttons {ok} \
		-cancel {cancel}
		
	::libCrowFM::dialog_move_center .eDlg
	return
}

proc ::libCrowFM::dialog_move_center {dlg {width ""} {height ""}} {
	tkwait visibility $dlg
	foreach {s x y} [split [wm geometry .] "+"] {break}
	foreach {w h} [split $s "x"] {break}
	
	set oX [expr $x+$w/2]
	set oY [expr $y+$h/2]

	foreach {s x y} [split [wm geometry $dlg] "+"] {break}
	
	foreach {w h} [split $s "x"] {break}	
	if {$width != ""} {set w $width}
	if {$height != ""} {set h $height}
	
	
	set oX [expr $oX-$w/2]
	set oY [expr $oY-$h/2]
	grab set $dlg
	wm geometry $dlg ${w}x${h}+${oX}+${oY}
	
}

proc ::libCrowFM::dialog_progress_hide {args} {
	variable Priv

	set Priv(progress,flag) 0
	set Priv(progress,curr) 0
	set Priv(progress,sizeCurr) 0
	set Priv(progress,sizeMax) "0 MB"	
	if {[winfo exists $Priv(progress,dialog)]} {	after idle [list destroy $Priv(progress,dialog)]	}
	return
}

proc ::libCrowFM::dialog_progress_incr {val} {
	variable Priv

	incr Priv(progress,curr) $val
	set Priv(progress,sizeCurr) [expr int(($Priv(progress,curr)/1048576.0)*10)/10.0]
	update
	return
}

proc ::libCrowFM::dialog_progress_max {max} {
	variable Priv

	$Priv(progress,pbar) configure -maximum $max
	set Priv(progress,sizeMax) [list "/" [expr int(($max/1048576.0)*10)/10.0] "MB"]

	return
}

proc ::libCrowFM::dialog_progress_show {title} {
	variable Priv

	set Priv(progress,flag) 1
	set Priv(progress,curr) 0	
	set Priv(progress,message) ""
	set Priv(progress,sizeCurr) 0
	set Priv(progress,sizeMax) "0 MB"

	set dlg .pDlg

	::ttk::dialog $dlg \
		-title $title \
		-labels [list cancel [::msgcat::mc "Cancel"]] \
		-buttons {cancel} \
		-cancel {cancel} \
		-command {::libCrowFM::dialog_progress_hide}

	set fme [ttk::dialog::clientframe $dlg]
	set icon [::ttk::label $fme.icon -image "tree.progress"]
	set msg [::ttk::label $fme.msg \
		-textvariable ::libCrowFM::Priv(progress,message) \
		-justify left \
		-anchor w \
		-wraplength 335 \
		-width 65]
	set pbar [ttk::progressbar $fme.pbar -orient horizontal -variable ::libCrowFM::Priv(progress,curr)]
	set sizeCurr [::ttk::label $fme.sizeCurr \
		-textvariable ::libCrowFM::Priv(progress,sizeCurr) \
		-justify left \
		-anchor w]
	set sizeMax [::ttk::label $fme.sizeMax \
		-textvariable ::libCrowFM::Priv(progress,sizeMax) \
		-justify left \
		-anchor w]

	grid $icon $msg -sticky "news" -padx 2 -pady 2
	grid $pbar -  -sticky "news" -padx 2 -pady 2
	grid $sizeCurr $sizeMax  -sticky "news" -pady 2
	grid rowconfigure $fme 1 -weight 1
	grid columnconfigure $fme 1 -weight 1
	
	set Priv(progress,pbar) $pbar
	set Priv(progress,dialog) $dlg
	
	::libCrowFM::dialog_move_center $dlg
	
	return
}

proc ::libCrowFM::get_volume_type {drive} {
	switch -exact -- $::tcl_platform(platform) {
		"windows" {
			set type [::twapi::get_drive_type $drive]
		}
		"unix" {
			set type "fixed"
		}
	}
	return $type
}

proc ::libCrowFM::get_user_table {} {
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

proc ::libCrowFM::get_groups {} {
	set ret ""
	array set groups [::libCrowFM::get_group_table]
	foreach key [array names groups] {
		lappend ret $groups($key)
	}
	return [lsort -dictionary $ret]
}

proc ::libCrowFM::get_group_table {} {
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

proc ::libCrowFM::get_users {} {
	set ret ""
	array set users [::libCrowFM::get_user_table]
	foreach key [array names users] {
		lappend ret $users($key)
	}
	return [lsort -dictionary $ret]
}

proc ::libCrowFM::uid_to_name {uid} {
	array set users [::libCrowFM::get_user_table]
	return $users($uid)
}

proc ::libCrowFM::gid_to_name {gid} {
	array set groups [::libCrowFM::get_group_table]
	return $groups($gid)
}

proc ::libCrowFM::file_attribute_apply {files r} {
	variable Priv
	
	set Priv(progress,flag) 1
	::libCrowFM::dialog_progress_show [::msgcat::mc "Apply Attribute"]
	::libCrowFM::dialog_progress_max $Priv(fileSize)
	foreach f $files {
		if {[catch {::libCrowFM::file_attribute_set $f $Priv(chkHidden) $Priv(chkReadonly) $r} errMsg]} {
			::libCrowFM::dialog_error_show $errMsg
			break
		}
	}
	::libCrowFM::dialog_progress_hide
	set Priv(progress,flag) 0
}

proc ::libCrowFM::file_attribute_set {f hidden readonly {r 0}} {
	variable Priv
	
	file attributes $f -hidden $hidden -readonly $readonly
	::libCrowFM::dialog_progress_incr [file size $f]
#	update
	if {[file isfile $f] || $r == 0 || $Priv(progress,flag) == 0} {return}
	foreach item [glob -nocomplain -directory $f *] {
		if {[file tail $f] == "." || [file tail $f] == ".."} {continue}
		::libCrowFM::file_attribute_set $item $hidden $readonly $r
	}
	foreach item [glob -nocomplain -directory $f -types {hidden} *] {
		if {[file tail $f] == "." || [file tail $f] == ".."} {continue}
		::libCrowFM::file_attribute_set $item $hidden $readonly $r
	}	
}

proc ::libCrowFM::file_in_volume {f} {
	set ret ""
	foreach v [file volumes] {
		if {$::tcl_platform(platform) == "windows"} {
			set v [string tolower $v]
			set f [string tolower $f]
		}
		if {[string first $v $f] >= 0} {
			if {[string length $v] > [string length $ret]} {
				set ret $v
			}
		}
	}
	return $ret
}

proc ::libCrowFM::file_permission_apply {files r} {
	variable Priv
	
	set Priv(progress,flag) 1
	::libCrowFM::dialog_progress_show [::msgcat::mc "Apply Permission"]
	::libCrowFM::dialog_progress_max $Priv(fileSize)
	foreach f $files {
		if {[catch {::libCrowFM::file_permission_set $f $r} errMsg]} {
			::libCrowFM::dialog_error_show $errMsg
			break
		}
	}
	::libCrowFM::dialog_progress_hide
	set Priv(progress,flag) 0	
}

proc ::libCrowFM::file_permission_chmod {f mode} {
	array set finfo ""
	file stat $f finfo
	if {$mode != ($finfo(mode) & 0xfff)} {
		file attributes $f -permissions $mode
	}
	array unset finfo
	return
}

proc ::libCrowFM::file_permission_chown {f user group} {
	set uname [file attributes $f -owner]
	set gname [file attributes $f -group]
	if {$user != $uname || $group != $gname} {
		file attributes $f -owner $user -group $group
	}
	return
}

proc ::libCrowFM::file_permission_set {f r} {
	variable Priv
	
	set mode 0
	foreach bit [list $Priv(permissions,sid,suid) $Priv(permissions,sid,sgid) $Priv(permissions,sid,sticky) \
			$Priv(permissions,owner,r) $Priv(permissions,owner,w) $Priv(permissions,owner,x) \
			$Priv(permissions,group,r) $Priv(permissions,group,w) $Priv(permissions,group,x) \
			$Priv(permissions,other,r) $Priv(permissions,other,w) $Priv(permissions,other,x)] {
		set mode [expr (($mode<<1) | $bit)]
	}
	set mode [format "0%o" $mode]
	
	::libCrowFM::file_permission_chmod $f $mode
	::libCrowFM::file_permission_chown $f $Priv(permissions,user) $Priv(permissions,group)
	
	::libCrowFM::dialog_progress_incr [file size $f]

	if {[file isfile $f] || $r == 0 || $Priv(progress,flag) == 0} {return}
	foreach item [glob -nocomplain -directory $f *] {
		if {[file tail $f] == "." || [file tail $f] == ".."} {continue}
		::libCrowFM::file_permission_set $item $r
	}
	foreach item [glob -nocomplain -directory $f -types {hidden} *] {
		if {[file tail $f] == "." || [file tail $f] == ".."} {continue}
		::libCrowFM::file_permission_set $item $r
	}
}

proc ::libCrowFM::file_properties {files} {
	::libCrowFM::file_properties_$::tcl_platform(platform) $files
}

proc ::libCrowFM::file_properties_cb {btn} {
	variable Priv
	set Priv(progress,flag) 0
	return
}

proc ::libCrowFM::file_properties_unix {files} {
	variable Priv
	
	set dlg ".dlgFileProperty"
	
	::ttk::dialog $dlg \
		-title [::msgcat::mc "Properties"] \
		-message [::msgcat::mc "File Properties."] \
		-labels [list cancel [::msgcat::mc "Ok"]] \
		-buttons {cancel} \
		-cancel {cancel} \
		-command {::libCrowFM::file_properties_cb}

	set fme [ttk::dialog::clientframe $dlg]
	set nb [ttk::notebook $fme.nb]
	set fG [ttk::frame $nb.fGeneral] 
	set fP [ttk::frame $nb.fPermission] 
	$nb add $fG -text [::msgcat::mc "General"]
	$nb add $fP -text [::msgcat::mc "Permissions"]
	pack $nb -expand 1 -fill both
	
	
	set varList ""
	set mask 0x800
	set fme [::ttk::labelframe $fP.fmeSid -text [::msgcat::mc "SID"]]
	grid $fme -row 0 -column 3 -sticky "news" -padx 5 -pady 5
	array set bits [list suid [::msgcat::mc "Set UID"] sgid [::msgcat::mc "Set GID"] sticky "Sticky"]
	foreach bit "suid sgid sticky" {
		::ttk::checkbutton $fme.chk$bit -text $bits($bit) \
			-variable ::libCrowFM::Priv(permissions,sid,$bit)
		if {($mask & $finfo(mode))==0} {
			set Priv(permissions,sid,$bit) 0
		} else {
			set Priv(permissions,sid,$bit) 1
		}
		set mask [expr $mask>>1]
		pack $fme.chk$bit -side top -expand 1 -fill both
	}	
	
	set col 0
	set mask 0x100
	array set acls [list owner [::msgcat::mc "Owner"] group [::msgcat::mc "Group"] other [::msgcat::mc "Other"]]
	array set attrs [list r [::msgcat::mc "Read"] w [::msgcat::mc "Write"] x [::msgcat::mc "execute"]]
	foreach acl "owner group other" {
		set fme [::ttk::labelframe $fP.fme$acl -text $acls($acl)]
		grid $fme -row 0 -column $col -sticky "news" -padx 5 -pady 5
		foreach bit "r w x" {
			::ttk::checkbutton $fme.chk$bit -text $attrs($bit) \
				-variable ::libCrowFM::Priv(permissions,$acl,$bit)
			if {($mask & $finfo(mode))==0} {
				set Priv(permissions,$acl,$bit) 0
			} else {
				set Priv(permissions,$acl,$bit) 1
			}
			set mask [expr $mask>>1]
			pack $fme.chk$bit -side top -expand 1 -fill both
		}
		incr col
	}	
	
	set fme [::ttk::labelframe $fP.fmeOwner -text [::msgcat::mc "Owner"]]
	grid $fme - - - -sticky "news" -padx 5 -pady 5
	::ttk::label $fme.lblUser -text [::msgcat::mc "Owner:"] -anchor w -justify left
	::ttk::label $fme.lblGroup -text [::msgcat::mc "Group:"] -anchor w -justify left
	set Priv(user) $finfo(uid)
	set Priv(group) $finfo(gid)
	if {$finfo(uid) != "-"} {
		set Priv(permissions,user) [::libCrowFM::uid_to_name $finfo(uid)]
		set Priv(permissions,group) [::libCrowFM::gid_to_name $finfo(gid)]
	}
	::ttk::combobox $fme.cmbUser -textvariable ::libCrowFM::Priv(permissions,user) \
		-values [::libCrowFM::get_users] -state readonly
	::ttk::combobox $fme.cmbGroup -textvariable ::libCrowFM::Priv(permissions,group) \
		-values [::libCrowFM::get_groups] -state readonly

	grid $fme.lblUser $fme.cmbUser -sticky "we" -padx 2 -pady 5
	grid $fme.lblGroup $fme.cmbGroup  -sticky "we" -padx 2 -pady 5

	grid rowconfigure $fme 2 -weight 1	
	grid columnconfigure $fme 1 -weight 1
			
	set fApply [::ttk::frame $fP.fApply]
	set btnApply [::ttk::button $fApply.btnApply \
		-text [::msgcat::mc "Apply"] \
		-command [list ::libCrowFM::file_permission_apply $files 0]]
	set btnApplyAll [::ttk::button $fApply.btnApplyAll \
		-text [::msgcat::mc "Apply to Enclosed Files."] \
		-command [list ::libCrowFM::file_permission_apply $files 1]]
	pack $btnApplyAll $btnApply -side right -padx 3 -pady 3	
	grid $fApply - - - -sticky "news" -padx 5 -pady 5	
	
	
	
	if {[llength $files] == 1} {
		set f [lindex $files 0]
		set name [file tail $f]
		set path [file dirname $f]
		set mtime [clock format [file mtime $f] -format %c]
		set type [file type $f]
		set icon "__unknow__"
		file stat $f finfo
	} else {
		set icon "__unknow__"
		set name [::msgcat::mc "%s items" [llength $files]]
		set path [file dirname [lindex $files 0]]
		set mtime "---"
		set type "---"
		set finfo(mode) 0
		set finfo(uid) -
		set finfo(gid) -
	}

	set btnIcon [::ttk::button $fG.btnIcon -image $icon]
	set lblName [::ttk::label $fG.lblName -justify left -anchor w -text [::msgcat::mc "Name:"] ]
	set txtName [::ttk::entry $fG.txtName]
	$txtName insert 0 $name
	
	set lblType [::ttk::label $fG.lblType -justify left -anchor w -text [::msgcat::mc "Type:"]]
	set txtType [::ttk::entry $fG.txtType]
	$txtType insert 0 $type
	
	set lblContents [::ttk::label $fG.lblContents -justify left -anchor w -text "Contents:"]
	set txtContents [::ttk::entry $fG.txtContents -state readonly -textvariable ::libCrowFM::Priv(txtContents)]
	
	set lblLocation [::ttk::label $fG.lblLocation -justify left -anchor w -text [::msgcat::mc "Location:"]]
	set txtLocation [::ttk::entry $fG.txtLocation]
	$txtLocation insert 0 $path
	
	set lblMtime [::ttk::label $fG.lblMtime -justify left -anchor w -text [::msgcat::mc "Modified:"]]
	set txtMtime [::ttk::entry $fG.txtMtime -text $mtime]
	$txtMtime insert 0 $mtime


	foreach w [list $txtName $txtType $txtLocation $txtMtime] {
		$w configure -state readonly -width 30
	}
	
	grid $btnIcon $lblName $txtName -padx 10 -pady 5 -sticky "we"
	grid [::ttk::frame $fG.f1] $lblType $txtType -padx 10 -pady 5 -sticky "we"
	grid [::ttk::frame $fG.f2] $lblContents $txtContents -padx 10 -pady 5 -sticky "we"
	grid [::ttk::frame $fG.f3] $lblLocation $txtLocation -padx 10 -pady 5 -sticky "we"
	grid [::ttk::frame $fG.f4] $lblMtime $txtMtime -padx 10 -pady 5 -sticky "we"
	
	grid columnconfigure $fG 3 -weight 1
	grid rowconfigure $fG 5 -weight 1
	
	::libCrowFM::dialog_move_center $dlg 400 450
	
	set Priv(progress,flag) 1
	set Priv(fileSize) 0
	set Priv(fileCount) 0
	set cut 0
	set size 0
	foreach f $files {
		incr cut
		catch {
			::libCrowFM::file_size $f
			set errMsg ""
		} errMsg
		if {$errMsg != ""} {
			::libCrowFM::dialog_error_show $errMsg
			break
		}
		update
	}
	set Priv(progress,flag) 0
	
#	grid rowconfigure $fP 2 -weight 1	
#	grid columnconfigure $fP 4 -weight 1		
	
	
}

proc ::libCrowFM::file_properties_windows {files} {
	variable Priv

	set dlg ".dlgFileProperty"
	
	::ttk::dialog $dlg \
		-title [::msgcat::mc "Properties"] \
		-message [::msgcat::mc "File Properties."] \
		-labels [list cancel [::msgcat::mc "Ok"]] \
		-buttons {cancel} \
		-cancel {cancel} \
		-command {::libCrowFM::file_properties_cb}

	set fme [ttk::dialog::clientframe $dlg]
	set nb [ttk::notebook $fme.nb]
	set fG [ttk::frame $nb.fGeneral] 
#	set fP [ttk::frame $nb.fPermission] 
	$nb add $fG -text [::msgcat::mc "General"]
#	$nb add $fP -text [::msgcat::mc "Permission"]
	pack $nb -expand 1 -fill both
	
	if {[llength $files] == 1} {
		set f [lindex $files 0]
		set name [file tail $f]
		set path [file dirname $f]
		set mtime [clock format [file mtime $f] -format %c]
		set type [file type $f]
		set icon "__unknow__"
	} else {
		set icon "__unknow__"
		set name [::msgcat::mc "%s items" [llength $files]]
		set path [file dirname [lindex $files 0]]
		set mtime "---"
		set type "---"
	}

	set btnIcon [::ttk::button $fG.btnIcon -image $icon]
	set lblName [::ttk::label $fG.lblName -justify left -anchor w -text [::msgcat::mc "Name:"] ]
	set txtName [::ttk::entry $fG.txtName]
	$txtName insert 0 $name
	
	set lblType [::ttk::label $fG.lblType -justify left -anchor w -text [::msgcat::mc "Type:"]]
	set txtType [::ttk::entry $fG.txtType]
	$txtType insert 0 $type
	
	set lblContents [::ttk::label $fG.lblContents -justify left -anchor w -text "Contents:"]
	set txtContents [::ttk::entry $fG.txtContents -state readonly -textvariable ::libCrowFM::Priv(txtContents)]
	
	set lblLocation [::ttk::label $fG.lblLocation -justify left -anchor w -text [::msgcat::mc "Location:"]]
	set txtLocation [::ttk::entry $fG.txtLocation]
	$txtLocation insert 0 $path
	
	set lblMtime [::ttk::label $fG.lblMtime -justify left -anchor w -text [::msgcat::mc "Modified:"]]
	set txtMtime [::ttk::entry $fG.txtMtime -text $mtime]
	$txtMtime insert 0 $mtime

	set lblAttrs [::ttk::label $fG.lblAttrs -justify left -anchor w -text [::msgcat::mc "Attributes:"]]
	set chkHidden [ttk::checkbutton $fG.chkHidden \
		-variable ::libCrowFM::Priv(chkHidden) \
		-text [::msgcat::mc "Hidden"] ]
	set chkReadonly [ttk::checkbutton $fG.chkReadonly \
		-variable ::libCrowFM::Priv(chkReadonly) \
		-text [::msgcat::mc "Readonly"] ]
		
	set fApply [::ttk::frame $fG.fApply]
	set btnApply [::ttk::button $fApply.btnApply \
		-text [::msgcat::mc "Apply"] \
		-command [list ::libCrowFM::file_attribute_apply $files 0]]
	set btnApplyAll [::ttk::button $fApply.btnApplyAll \
		-text [::msgcat::mc "Apply to Enclosed Files."] \
		-command [list ::libCrowFM::file_attribute_apply $files 1]]
	pack $btnApplyAll $btnApply -side right -padx 3 -pady 3

	foreach w [list $txtName $txtType $txtLocation $txtMtime] {
		$w configure -state readonly -width 30
	}
	
	grid $btnIcon $lblName $txtName -padx 10 -pady 5 -sticky "we"
	grid [::ttk::frame $fG.f1] $lblType $txtType -padx 10 -pady 5 -sticky "we"
	grid [::ttk::frame $fG.f2] $lblContents $txtContents -padx 10 -pady 5 -sticky "we"
	grid [::ttk::frame $fG.f3] $lblLocation $txtLocation -padx 10 -pady 5 -sticky "we"
	grid [::ttk::frame $fG.f4] $lblMtime $txtMtime -padx 10 -pady 5 -sticky "we"
	grid $lblAttrs $chkHidden $chkReadonly -padx 10 -pady 5 -sticky "we"
	grid $fApply - - -padx 10 -pady 10 -sticky "we"
	
	grid columnconfigure $fG 3 -weight 1
	grid rowconfigure $fG 7 -weight 1
	
	::libCrowFM::dialog_move_center $dlg ;#400 450
	
	set Priv(progress,flag) 1
	set Priv(fileSize) 0
	set Priv(fileCount) 0
	set cut 0
	set size 0
	foreach f $files {
		incr cut
		catch {
			::libCrowFM::file_size $f
			set errMsg ""
		} errMsg
		if {$errMsg != ""} {
			::libCrowFM::dialog_error_show $errMsg
			break
		}
		update
	}
	set Priv(progress,flag) 0
}

proc ::libCrowFM::file_size {fpath} {
	variable Priv

	update
	if {$Priv(progress,flag) == 0 } {error ""}
	incr Priv(fileCount)
	set Priv(fileSize) [expr wide($Priv(fileSize))+[file size $fpath]]

	set mb [expr wide(wide($Priv(fileSize))/1048676.0*10)/10.0]
	set unit "MB"
	if {$mb > 1024} {
		set mb [expr int($mb/1024.0*100)/100.0]
		set unit "GB"
	}
	set Priv(txtContents) [::msgcat::mc "%s items, totalling %s %s" $Priv(fileCount) $mb $unit]
	
	if {[file isfile $fpath]} {return}

	foreach f [glob -nocomplain -directory $fpath *] {
		if {[file tail $f] == "." || [file tail $f] == ".."} {continue}
		if {$Priv(progress,flag) == 0 } {error ""}
		if {[file isdirectory $f]} {
			::libCrowFM::file_size $f
		} else {
			incr Priv(fileCount)
		}
		set Priv(fileSize) [expr wide($Priv(fileSize))+[file size $f]]
		set mb [expr wide(wide($Priv(fileSize))/1048676.0*10)/10.0]
		set unit "MB"
		if {$mb > 1024} {
			set mb [expr int($mb/1024.0*100)/100.0]
			set unit "GB"
		}
		set Priv(txtContents) [::msgcat::mc "%s items, totalling %s %s" $Priv(fileCount) $mb $unit]			
		update
	}
	foreach f [glob -nocomplain -directory $fpath -types {hidden} *] {
		if {[file tail $f] == "." || [file tail $f] == ".."} {continue}
		if {$Priv(progress,flag) == 0 } {error ""}
		if {[file isdirectory $f]} {
			::libCrowFM::file_size $f
		} {
			incr Priv(fileCount)
		}
		set Priv(fileSize) [expr wide($Priv(fileSize))+[file size $f]]
		set mb [expr wide(wide($Priv(fileSize))/1048676.0*10)/10.0]
		set unit "MB"
		if {$mb > 1024} {
			set mb [expr int($mb/1024.0*100)/100.0]
			set unit "GB"
		}
		set Priv(txtContents) [::msgcat::mc "%s items, totalling %s %s" $Priv(fileCount) $mb $unit]			
		update
	}
	return
}

proc ::libCrowFM::ls {dir cb} {
	variable Priv

	if {$dir == [::msgcat::mc "Volumes:"]} {
		foreach v [file volumes] {
			set type [::libCrowFM::get_volume_type $v]
			set item [::rframe::tree_item_add 0 $v tree.$type]
			eval [linsert $cb end [string toupper $type] $v]
		}
		return
	} 
	foreach d [glob -nocomplain -directory $dir -types {d} *] {
		if {[file tail $d] == "." || [file tail $d] == ".."} {continue}
		eval [linsert $cb end "DIRECTORY" $d]
	}
	if {$Priv(SHOW_HIDDEN)} {
		update
		foreach d [glob -nocomplain -directory $dir -types {d hidden} *] {
		if {[file tail $d] == "." || [file tail $d] == ".."} {continue}
			eval [linsert $cb end "HIDDEN_DIRECTORY" $d]
		}
	}

	update
	foreach f [glob -nocomplain -directory $dir -types {c b f p s} *] {
		eval [linsert $cb end "FILE" $f]
	}
	if {$Priv(SHOW_HIDDEN)} {
		update
		foreach f [glob -nocomplain -directory $dir -types {c b f p s hidden} *] {
			eval [linsert $cb end "HIDDEN_FILE" $f]
		}
	}
	return
}
