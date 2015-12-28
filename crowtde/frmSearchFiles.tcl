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

namespace eval ::frmSearchFiles {
	variable wInfo
	array set wInfo ""
	variable vars
	array set vars ""
	variable startFlag 0
	variable tabCounter 0
	variable progress 0
}

proc ::frmSearchFiles::show {path} {
	variable wInfo
	variable vars
	if {[winfo exists $path]} {
		raise $path
		return
	}	
	set win [toplevel $path]
	wm title $path [::msgcat::mc "Search files"]
	wm minsize $path 500 500
	wm resizable $path 1 1
	set wInfo(toplevel) $path


	set vars(keyword) ""
	set vars(dir) [::fmeProjectManager::get_project_path]
	set vars(hidden) 0
	if {$vars(keyword) eq ""} {set vars(keyword) "*.tcl *.tm"}
	set lblKeyword [label $path.lblKeyword -text [::msgcat::mc "File name:"] -anchor w -justify left]
	set txtKeyword [entry $path.txtKeyword -textvariable ::frmSearchFiles::vars(keyword) -takefocus 1]
	set btnStart [button $path.btnStart -text [::msgcat::mc "Start"] -command {::frmSearchFiles::start} -default active]
	set btnStop [button $path.btnStop -text [::msgcat::mc "Stop"] -command {set ::frmSearchFiles::startFlag 0}]
	set lblDir [label $path.lblDir -text [::msgcat::mc "Directory:"] -anchor w -justify left]
	set txtDir [entry $path.txtDir -textvariable ::frmSearchFiles::vars(dir) -takefocus 1]
	set btnDir [button $path.btnDir -text [::msgcat::mc "Browse..."] -command {::frmSearchFiles::btnDir_click}]
	
	set fmeOptions [frame $path.fmeOptions -bd 2 -relief groove]
	set chkHidden [checkbutton $fmeOptions.chkHidden -text [::msgcat::mc "Search hidden files & folders"]\
		-onvalue 1 -offvalue 0 -variable ::frmSearchFiles::vars(hidden)]
	pack $chkHidden -side left
	
	set sw [ScrolledWindow $path.sw -relief groove -bd 2]
	set txtResult [text $sw.txtResult -bd 2 -relief groove -state disabled \
		-spacing3 2 -spacing1 2 -bd 1 -relief flat -height 8 -width 8 -wrap none]
	$sw setwidget $txtResult
	
	set lblCurr [label $path.lblCurr -textvariable ::frmSearchFiles::vars(current) -width 40 -anchor w -justify left]
	set pbr [ProgressBar $path.pbr -type nonincremental_infinite -variable ::frmSearchFiles::progress \
		-maximum 20 -bd 2 -relief ridge -troughcolor [$lblCurr cget -bg] -fg "#808080"]
	
	set wInfo(txtResult) $txtResult
	set wInfo(txtKeyword) $txtKeyword
	set wInfo(txtDir) $txtDir
	set wInfo(btnDir) $btnDir
	set wInfo(chkHidden) $chkHidden
	
	grid $lblKeyword $txtKeyword $btnStart -sticky "we" -padx 2 -pady 2
	grid $lblDir $txtDir $btnDir -sticky "we" -padx 2 -pady 2
	grid $btnStop -row 2 -column 2 -sticky "we" -padx 2 -pady 2
	grid $fmeOptions - - -sticky "we" -padx 2 -pady 2
	grid $sw - - -sticky "news" -padx 2
	grid $lblCurr - $pbr -sticky "we" -padx 2
	
	bind $txtKeyword <KeyRelease-Return> {::frmSearchFiles::start}
	bind $txtKeyword <Visibility> {focus %W}
	
	grid rowconfigure $path 4 -weight 1
	grid columnconfigure $path 1 -weight 1
	set ::frmSearchFiles::progress 0
	set vars(lblCurr) ""
	wm protocol $path WM_DELETE_WINDOW {::frmSearchFiles::bye}
	tkwait window $path
	return
}

#######################################################
#                                                     #
#                 Private Operations                  #
#                                                     #
#######################################################

proc ::frmSearchFiles::add_found {fpath} {
	variable wInfo
	variable tagCounter
	incr tagCounter
	set txt $wInfo(txtResult)
	$txt configure -state normal
	$txt insert end $fpath
	set idx [$txt index end]
	$txt tag add tag$tagCounter "$idx -1 line linestart" "$idx -1 line lineend"
	$txt insert end "\n"
	$txt tag bind tag$tagCounter <ButtonPress-1> [list ::frmSearchFiles::goto $fpath]
	$txt tag bind tag$tagCounter <Enter> "$txt configure -cursor hand2 ; $txt tag configure tag$tagCounter -underline 1 -foreground blue"
	$txt tag bind tag$tagCounter <Leave> "$txt configure -cursor arrow ; $txt tag configure tag$tagCounter -underline 0 -foreground black"
	$txt configure -state disabled
	update
}

proc ::frmSearchFiles::btnDir_click {} {
	variable vars
	variable wInfo
	set ret [tk_chooseDirectory -title [::msgcat::mc "Choose Directory"] -mustexist 1]
	raise $wInfo(toplevel)
	if {$ret eq "" || $ret eq "-1"} {return}
	set vars(dir) $ret
}

proc ::frmSearchFiles::bye {} {
	variable startFlag
	variable wInfo
	set startFlag 0
	after 250 [list destroy $wInfo(toplevel)]
}

proc ::frmSearchFiles::goto {fpath} {
	::fmeProjectManager::file_open $fpath
}

proc ::frmSearchFiles::incr_progress {} {
	variable progress
	incr progress
	after 100 ::frmSearchFiles::incr_progress
	update
}

proc ::frmSearchFiles::scan {dpath} {
	variable vars
	variable startFlag
	variable progress
	set flist [eval "glob -directory {$dpath} -nocomplain -types {f r} $vars(keyword)"]
	update
	if {$vars(hidden)} {
		set flist [concat $flist [eval "glob -directory {$dpath} -nocomplain -types {f r hidden} $vars(keyword)"]]
	}
	update
	set flist [lsort -dictionary $flist]
	update
	foreach f $flist {
		set vars(current) $f
		update
		if {$startFlag == 0} {break}
		if {[file type $f] ne "file"} {continue}
		::frmSearchFiles::add_found $f
		
	}
	set dlist [glob -directory $dpath -nocomplain -types {d r} *]
	update
	if {$vars(hidden)} {
		set dlist [concat $dlist [glob -directory $dpath -nocomplain -types {d r hidden} *]]
	}
	update
	set dlist [lsort -dictionary $dlist]
	update
	foreach d $dlist {
		set vars(current) $d
		update
		if {$startFlag == 0} {break}
		::frmSearchFiles::scan $d
	}
}

proc ::frmSearchFiles::start {} {
	variable vars
	variable startFlag
	variable tagCounter
	variable progress
	variable wInfo
	if {![file exists $vars(dir)] || [file type $vars(dir)] ne "directory"} {
		tk_messageBox -type ok -title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "Search directory not valid!"]
		raise $wInfo(toplevel)
		return
	}
	if {[string trim $vars(keyword)] eq ""} {
		tk_messageBox -type ok -title [::msgcat::mc "Error"] \
			-message [::msgcat::mc "Keyword can't empty!"]
		raise $wInfo(toplevel)
		return		
	}
	$wInfo(txtKeyword) configure -state disabled
	$wInfo(txtDir) configure -state disabled
	$wInfo(btnDir) configure -state disabled
	$wInfo(chkHidden) configure -state disabled	
	set startFlag 1
	set tagCounter 0
	set progress 0
	set vars(current) ""
	$wInfo(txtResult) configure -state normal
	$wInfo(txtResult) delete 1.0 end
	$wInfo(txtResult) configure -state disabled
	after 100 ::frmSearchFiles::incr_progress
	::frmSearchFiles::scan $vars(dir)
	after cancel ::frmSearchFiles::incr_progress
	set startFlag 0
	set progress 0
	set vars(current) [::msgcat::mc "Finish %s items found." $tagCounter] 
	$wInfo(txtKeyword) configure -state normal
	$wInfo(txtDir) configure -state normal
	$wInfo(btnDir) configure -state normal
	$wInfo(chkHidden) configure -state normal		
}


