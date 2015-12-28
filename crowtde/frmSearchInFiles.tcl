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

namespace eval ::frmSearchInFiles {
	variable wInfo
	array set wInfo ""
	variable vars
	array set vars ""
	variable startFlag 0
	variable tabCounter 0
	variable progress 0
}

proc ::frmSearchInFiles::show {path} {
	variable wInfo
	variable vars
	if {[winfo exists $path]} {
		raise $path
		return
	}	
	set win [toplevel $path]
	wm title $path [::msgcat::mc "Search in files"]
	wm minsize $path 500 500
	wm resizable $path 1 1
	set wInfo(toplevel) $path
	set vars(keyword) ""
	set vars(filter) "*.tcl"
	set vars(dir) [::fmeProjectManager::get_project_path]
	set vars(case) 0
	set vars(regexp) 0
	set vars(hidden) 0
		
	set lblKeyword [label $path.lblKeyword -text [::msgcat::mc "Keyword:"] -anchor w -justify left]
	set txtKeyword [entry $path.txtKeyword -textvariable ::frmSearchInFiles::vars(keyword) -takefocus 1]
	set btnStart [button $path.btnStart -text [::msgcat::mc "Start"] -command {::frmSearchInFiles::start} -default active]
	set btnStop [button $path.btnStop -text [::msgcat::mc "Stop"] -command {set ::frmSearchInFiles::startFlag 0}]
	set lblFilter [label $path.lblFilter -text [::msgcat::mc "Filter:"] -anchor w -justify left]
	set txtFilter [entry $path.txtFilter -textvariable ::frmSearchInFiles::vars(filter) -takefocus 1]
	set lblDir [label $path.lblDir -text [::msgcat::mc "Directory"] -anchor w -justify left]
	set txtDir [entry $path.txtDir -textvariable ::frmSearchInFiles::vars(dir) -takefocus 1]
	set btnDir [button $path.btnDir -text [::msgcat::mc "Browse..."] -command {::frmSearchInFiles::btnDir_click}]
	
	set fmeOptions [frame $path.fmeOptions -bd 2 -relief groove]
	set chkCase [checkbutton $fmeOptions.chkCase -text [::msgcat::mc "Case Sensitive"] \
		-onvalue 1 -offvalue 0 -variable ::frmSearchInFiles::vars(case)]
	set chkRegexp [checkbutton $fmeOptions.chkRegexp -text [::msgcat::mc "Regular Expression"] \
		-onvalue 1 -offvalue 0 -variable ::frmSearchInFiles::vars(regexp)]
	set chkHidden [checkbutton $fmeOptions.chkHidden -text [::msgcat::mc "Search hidden files & folders"]\
		-onvalue 1 -offvalue 0 -variable ::frmSearchInFiles::vars(hidden)]
	pack $chkCase $chkHidden $chkRegexp -side left
	
	set sw [ScrolledWindow $path.sw -relief groove -bd 2]
	set txtResult [text $sw.txtResult -bd 2 -relief groove -state disabled \
		-spacing3 2 -spacing1 2 -bd 1 -relief flat -height 8 -width 8 -wrap none]
	$sw setwidget $txtResult
	
	set lblCurr [label $path.lblCurr -textvariable ::frmSearchInFiles::vars(current) -width 40 -anchor w -justify left]
	set pbr [ProgressBar $path.pbr -type nonincremental_infinite -variable ::frmSearchInFiles::progress \
		-maximum 20 -bd 2 -relief ridge -troughcolor [$lblCurr cget -bg] -fg "#808080"]
	
	set wInfo(txtResult) $txtResult
	set wInfo(txtKeyword) $txtKeyword
	set wInfo(txtFilter) $txtFilter
	set wInfo(txtDir) $txtDir
	set wInfo(btnDir) $btnDir
	set wInfo(chkCase) $chkCase
	set wInfo(chkRegexp) $chkRegexp
	set wInfo(chkHidden) $chkHidden
	
	grid $lblKeyword $txtKeyword $btnStart -sticky "we" -padx 2 -pady 2
	grid $lblFilter $txtFilter $btnStop -sticky "we" -padx 2 -pady 2
	grid $lblDir $txtDir $btnDir -sticky "we" -padx 2 -pady 2
	grid $fmeOptions - - -sticky "we" -padx 2 -pady 2
	grid $sw - - -sticky "news" -padx 2
	grid $lblCurr - $pbr -sticky "we" -padx 2
	
	bind $txtKeyword <KeyRelease-Return> {::frmSearchInFiles::start}
	bind $txtKeyword <Visibility> {focus %W}
	
	grid rowconfigure $path 4 -weight 1
	grid columnconfigure $path 1 -weight 1
	set ::frmSearchInFiles::progress 0
	set vars(lblCurr) ""
	wm protocol $path WM_DELETE_WINDOW {::frmSearchInFiles::bye}
	tkwait window $path
	return
}

#######################################################
#                                                     #
#                 Private Operations                  #
#                                                     #
#######################################################

proc ::frmSearchInFiles::add_found {fpath line pos} {
	variable wInfo
	variable tagCounter
	incr tagCounter
	set txt $wInfo(txtResult)
	$txt configure -state normal
	$txt insert end $fpath
	set idx [$txt index end]
	$txt tag add tag$tagCounter "$idx -1 line linestart" "$idx -1 line lineend"
	$txt insert end "\n"
	$txt tag bind tag$tagCounter <ButtonPress-1> [list ::frmSearchInFiles::goto $fpath $line $pos]
	$txt tag bind tag$tagCounter <Enter> "$txt configure -cursor hand2 ; $txt tag configure tag$tagCounter -underline 1 -foreground blue"
	$txt tag bind tag$tagCounter <Leave> "$txt configure -cursor arrow ; $txt tag configure tag$tagCounter -underline 0 -foreground black"
	$txt configure -state disabled
	update
}

proc ::frmSearchInFiles::btnDir_click {} {
	variable vars
	variable wInfo
	set ret [tk_chooseDirectory -title [::msgcat::mc "Choose Directory"] -mustexist 1]
	raise $wInfo(toplevel)
	if {$ret eq "" || $ret eq "-1"} {return}
	set vars(dir) $ret
}

proc ::frmSearchInFiles::bye {} {
	variable startFlag
	variable wInfo
	set startFlag 0
	after 250 [list destroy $wInfo(toplevel)]
}

proc ::frmSearchInFiles::goto {fpath line pos} {
	::fmeProjectManager::file_open $fpath
	::fmeTabEditor::file_raise $fpath
	set editor [::fmeTabEditor::get_curr_editor]
	if {![winfo exists $editor]} {return}
	::crowEditor::goto_pos $editor $line.$pos
	focus [::crowEditor::get_text_widget $editor]
}

proc ::frmSearchInFiles::incr_progress {} {
	variable progress
	incr progress
	after 100 ::frmSearchInFiles::incr_progress
	update
}

proc ::frmSearchInFiles::scan {dpath} {
	variable vars
	variable startFlag
	variable progress
	set filter [string trim $vars(filter)] 
	if {$filter eq ""} {set filter *}
	set flist [glob -directory $dpath -nocomplain -types {f r} $filter]

	if {$vars(hidden)} {
		set flist [concat $flist [glob -directory $dpath -nocomplain -types {f r hidden} $filter]]
	}

	set flist [lsort -dictionary $flist]

	foreach f $flist {
		set vars(current) $f
		update
		if {$startFlag == 0} {break}
		if {[file type $f] ne "file" || ![file readable $f]} {continue}
		set fd [open $f r]
		set lineNum 0
		set keyword $vars(keyword)
		while {[set num [gets $fd data]] >= 0} {
			update
			if {$startFlag == 0} {break}
			incr lineNum
			if {$vars(regexp)} {
				if {$vars(case)} {
					set idx [regexp -indices -inline -- "$keyword" $data]
				} else {
					set idx [regexp -nocase -indices -inline -- "$keyword" $data]
				}
				if {$idx ne ""} {
					::frmSearchInFiles::add_found $f $lineNum [lindex $idx 0 0]
					break
				}
			} else {
				if {$vars(case)} {
					set idx [string first $keyword $data]
				} else {
					set keyword [string tolower $keyword]
					set idx [string first $keyword [string tolower $data]]					
				}
				if {$idx >= 0} {
					::frmSearchInFiles::add_found $f $lineNum $idx
					break
				}				
			}
		}
		close $fd
	}
	set dlist [glob -directory $dpath -nocomplain -types {d r} *]

	if {$vars(hidden)} {
		set dlist [concat $dlist [glob -directory $dpath -nocomplain -types {d r hidden} *]]
	}

	set dlist [lsort -dictionary $dlist]

	foreach d $dlist {
		set vars(current) $d
		update
		if {$startFlag == 0} {break}
		::frmSearchInFiles::scan $d
		
	}
}

proc ::frmSearchInFiles::start {} {
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
	$wInfo(txtFilter) configure -state disabled
	$wInfo(txtDir) configure -state disabled
	$wInfo(btnDir) configure -state disabled
	$wInfo(chkCase) configure -state disabled
	$wInfo(chkRegexp) configure -state disabled
	$wInfo(chkHidden) configure -state disabled
	set startFlag 1
	set tagCounter 0
	set progress 0
	set vars(current) ""
	$wInfo(txtResult) configure -state normal
	$wInfo(txtResult) delete 1.0 end
	$wInfo(txtResult) configure -state disabled
	after 100 ::frmSearchInFiles::incr_progress
	::frmSearchInFiles::scan $vars(dir)
	after cancel ::frmSearchInFiles::incr_progress
	set startFlag 0
	set progress 0
	set vars(current) "Finish $tagCounter items found."
	$wInfo(txtKeyword) configure -state normal
	$wInfo(txtFilter) configure -state normal
	$wInfo(txtDir) configure -state normal
	$wInfo(btnDir) configure -state normal
	$wInfo(chkCase) configure -state normal
	$wInfo(chkRegexp) configure -state normal
	$wInfo(chkHidden) configure -state normal
}
