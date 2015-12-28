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

namespace eval ::fmeTask {
	variable wInfo
	variable dbPath ""
	# eInfo -> event info.
	variable eInfo
	variable images
	
	variable hideCompletedTasks 0
	
	variable vars
	
	array set eInfo ""
	array set wInfo ""
	array set images ""
	array set vars ""
	
	variable rc
}

proc ::fmeTask::ch_state {item} {
	variable wInfo
	variable dbPath
	variable hideCompletedTasks

	set tree $wInfo(tree)
	set state [$tree item state forcolumn $item 0]
	set dtime [$tree item element cget $item colDate txtTime -text]
	set id [regsub -all {[\-\:\s]} $dtime {}]
	if {$state eq "NOT_STARTED"} {
		$tree item state forcolumn $item 0 [list !NOT_STARTED IN_PROGRESS !FINISHED]
		set todo [file join $dbPath "N$id.todo"]
		if {[file exists $todo]} {file rename $todo [file join $dbPath "I$id.todo"]}
		return "IN_PROGRESS"
	} elseif {$state eq "IN_PROGRESS"} {
		$tree item state forcolumn $item 0 [list !NOT_STARTED !IN_PROGRESS FINISHED]
		set todo [file join $dbPath "I$id.todo"]
		if {[file exists $todo]} {file rename $todo [file join $dbPath "F$id.todo"]}
		return "FINISHED"
	} else {
		$tree item state forcolumn $item 0 [list NOT_STARTED !IN_PROGRESS !FINISHED]
		set todo [file join $dbPath "F$id.todo"]
		if {[file exists $todo]} {file rename $todo [file join $dbPath "N$id.todo"]}	
		return "NOT_STARTED"
	}
}

proc ::fmeTask::compare_state {T C item1 item2} {
	set s1 [$T item state forcolumn $item1 $C]
	set s2 [$T item state forcolumn $item2 $C]
	if {$s1 eq $s2} {return 0}
	if {$s1 eq "FINISHED"} {return 1}
	if {$s2 eq "FINISHED"} {return -1}
	if {$s1 eq "IN_PROGRESS"} {return 1}
	return -1
}

proc ::fmeTask::init {path} {
	variable wInfo
	variable rc
	variable vars
	variable hideCompletedTasks
	
	set rc [file join $::env(HOME) ".CrowTDE" "FmeTask.rc"]
	set hideCompletedTasks [::crowRC::param_get $rc HideCompletedTasks]
	if {$hideCompletedTasks eq ""} {set hideCompletedTasks 0}
	
	set fmeMain [frame $path]

	set vars(cmbState) [::msgcat::mc "All"]
	set fmeSearch [frame $path.fmeSearch -bd 1 -relief groove]
	set lblSearch [label $fmeSearch.lblSearch -text [::msgcat::mc "Search:"] -anchor w -justify left ]
	set cmbState [ComboBox $fmeSearch.cmbState -editable false \
		-textvariable ::fmeTask::vars(cmbState) \
		-highlightthickness 0 -relief groove \
		-entrybg white \
		-width 10 \
		-values [list [::msgcat::mc "All"] [::msgcat::mc "Not Started"] [::msgcat::mc "In Progress"] [::msgcat::mc "Finished"] ]]
	set txtKeyword [entry $fmeSearch.txtKeyword -textvariable ::fmeTask::vars(txtKeyword) -width 20 ]
	set btnSearch [button $fmeSearch.btnSearch -bd 1 -image [::crowImg::get_image find] -command ::fmeTask::item_search]
	set btnReset [button $fmeSearch.btnReset -bd 1 -image [::crowImg::get_image refresh] -command ::fmeTask::refresh]
	bind $txtKeyword <Key-Return> {::fmeTask::item_search}
	bind $btnSearch <Enter> [list puts sbar msg [::msgcat::mc "Find"]]
	bind $btnReset <Enter> [list puts sbar msg [::msgcat::mc "Reset"]]
	DynamicHelp::add $btnSearch -text [::msgcat::mc "Find"]
	DynamicHelp::add $btnReset -text [::msgcat::mc "Reset"]

	pack $lblSearch $cmbState $txtKeyword $btnSearch $btnReset -padx 2 -pady 1 -side left
	
	set fmeBody [ScrolledWindow $fmeMain.fmeBody -auto horizontal]
	set tree [treectrl $fmeBody.list \
		-font [::crowFont::get_font smaller] \
		-height 100 \
		-showroot no \
		-showline no \
		-selectmod extended \
		-showrootbutton no \
		-showbuttons no \
		-showheader yes \
		-scrollmargin 16 \
		-highlightthickness 0 \
		-relief groove \
		-bg white \
		-xscrolldelay "500 50" \
		-yscrolldelay "500 50"]
	$tree state define MOUSEOVER 
	$tree state define NOT_STARTED
	$tree state define IN_PROGRESS
	$tree state define FINISHED
		
	#Not Started In Progress Finished

	$tree column create -tag colState -font [::crowFont::get_font smaller] \
		-itembackground {#e0e8f0 {}} -expand no -text [::msgcat::mc "State"]
	$tree column create -tag colDate -font [::crowFont::get_font smaller] \
		-itembackground {#e0e8f0 {}} -expand no -text [::msgcat::mc "Time"]
	$tree column create -tag colTitle -font [::crowFont::get_font smaller] \
		-itembackground {#e0e8f0 {}} -expand yes -text [::msgcat::mc "Description"] 

	$tree element create rectSel rect \
		-open nw -outline gray -outlinewidth 1 -showfocus 0

	$tree element create rect rect -open news -showfocus yes -fill [list #a5c4c4 {selected}] 
	
	$tree element create imgCheck image \
		-image [list [::crowImg::get_image task_not_started] NOT_STARTED \
					 [::crowImg::get_image task_in_progress] IN_PROGRESS\
					 [::crowImg::get_image task_finished] FINISHED]
	$tree style create styCheck 
	$tree style elements styCheck [list rect rectSel imgCheck]
	$tree style layout styCheck imgCheck -padx {0 4} -expand news
	$tree style layout styCheck rectSel -detach yes -iexpand es
	$tree style layout styCheck rect -union {imgCheck} -iexpand news -ipadx 2
	
	$tree element create txtTime text -datatype time -format "%d/%m/%y %I:%M:%p" -lines 1
	$tree style create styTime 
	$tree style elements styTime [list rect rectSel txtTime]
	$tree style layout styTime txtTime -padx {0 4} -squeeze x -expand ns
	$tree style layout styTime rectSel -detach yes -iexpand es
	$tree style layout styTime rect -union {txtTime} -iexpand news -ipadx 2
	
	set fontUnderline [font create \
		-family [font configure [::crowFont::get_font smaller] -family] \
		-size [font configure [::crowFont::get_font smaller] -size] \
		-underline 1]
	$tree element create txtTitle text -lines 1 -fill [list blue {MOUSEOVER}] -font [list $fontUnderline {MOUSEOVER}]
	$tree style create styTitle 
	$tree style elements styTitle [list rect rectSel txtTitle]
	$tree style layout styTitle txtTitle -padx {0 4} -squeeze x -expand ns
	$tree style layout styTitle rectSel -detach yes -iexpand es
	$tree style layout styTitle rect -union {txtTitle} -iexpand news -ipadx 2

	set ::fmeTask::eInfo(linkColumn) 2
	set ::fmeTask::eInfo(currItem) ""
	
	$tree notify install <Edit-begin>
	$tree notify install <Edit-accept>
	$tree notify install <Edit-end>
	$tree notify install <Header-invoke>
	
	TreeCtrl::SetEditable $tree {{colTitle styTitle txtTitle}}
	TreeCtrl::SetSensitive $tree {{colTitle styTitle rectSel txtTitle}}
	TreeCtrl::SetDragImage $tree {}	

	bindtags $tree [list $tree TreeCtrlFileList TreeCtrl]
	set ::TreeCtrl::Priv(DirCnt,$tree) 1
	
	$tree notify bind $tree <Edit-begin> {
		%T item element configure %I %C %E -draw no + %E -draw no
		%T see %I
		update
	}
	$tree notify bind $tree <Edit-accept> {
		set t1 [%T item element cget %I %C %E -text]
		set t2 %t
		if {$t1 ne $t2} {
			%T item element configure %I %C %E -text $t2
			set dtime [%T item element cget %I colDate txtTime -text]
			set id [regsub -all {[\-\:\s]} $dtime {}]
			set todo [file join $::fmeTask::dbPath "N$id.todo"]
			if {![file exists $todo]} {set todo [file join $::fmeTask::dbPath "I$id.todo"]}
			if {![file exists $todo]} {set todo [file join $::fmeTask::dbPath "F$id.todo"]}
			if {[file exists $todo]} {
				set fd [open $todo w]
				puts -nonewline $fd  $t2
				close $fd
			}
		}
	}
	$tree notify bind $tree <Edit-end> {
		if {[%T item id %I] ne ""} {
			%T item element configure %I %C %E -draw yes + %E -draw yes
		}
		set t1 [%T item element cget %I %C %E -text]
		if {[string trim $t1] eq ""} {after idle [list ::fmeTask::task_del %I]}
	}
	
	bind $tree <ButtonRelease-1> {
		set id [%W identify %x %y]
		if {[llength $id] != 6} {
			%W selection clear
		} else {
			foreach {what itemId where columnId type name} $id {}
			if { $what eq "item" && $where eq "column"} {
				if {$columnId <=1} {
					%W selection clear
					%W selection add $itemId	
				}
				set tag [%W column cget $columnId -tag]
				if {$tag eq "colState"} {
					set state [::fmeTask::ch_state $itemId]
					if {$::fmeTask::hideCompletedTasks && $state eq "FINISHED"} {
						puts sbar msg [::msgcat::mc "Task already hidden!"]
						after idle [list %W item delete $itemId]
					}
				}
			}
		}
	}
	
	bind $tree <ButtonRelease-3> {
		set id [%W identify %x %y]
		if {$id eq ""} {
			%W selection clear
			::fmeTask::popup_widget_menu %W %X %Y	
		} else {
			if {[llength $id] == 6} {
				foreach {what itemId where columnId type name} $id {}
				if {$what eq "item" && $where eq "column"} {
					#%W selection modify $itemId all
					set state [%W item state forcolumn $itemId 0]
					::fmeTask::popup_item_menu %W %X %Y $itemId
					
				}
			}
		}
	}

	bind $tree <F2> {
		set item [lindex [%W selection get] 0]
		if {$item ne ""} {
			%W selection clear
			%W selection add $item
			::TreeCtrl::FileListEdit %W $item colTitle txtTitle
		}
	}
	
	bind $tree <Delete> {
		set items [%W selection get]
		if {$items ne ""} {
			set cut [llength $items]
			set ans [tk_messageBox -type yesno -title [::msgcat::mc "Task Delete"] \
				-message [::msgcat::mc "Are you sure you want to delete %%d tasks?" $cut]]
			if {$ans eq "yes"} {
				foreach item $items {
					%W item element configure $item colTitle txtTitle -text ""
					::fmeTask::task_del $item
				}
			}
		}
	}
	bind $tree <Insert> {
		%W selection clear
		::fmeTask::task_add
	}
	
	$tree notify bind $tree <Header-invoke> {
		if {[%T column cget %C -arrow] eq "down"} {
			set order -increasing
			set arrow up
		} else {
			set order -decreasing
			set arrow down
		}
		foreach col [%T column list] {
			%T column configure $col -arrow none
		}
		%T column configure %C -arrow $arrow
		switch [%T column cget %C -tag] {
			bounce -
			colState {
				%T item sort root $order -column %C -command [list ::fmeTask::compare_state %T %C] }
			colDate {
				%T item sort root $order -column %C -dictionary
			}
			colTitle {
				%T item sort root $order -column %C -dictionary
			}
		}
	}	
	
	$fmeBody setwidget $tree
	set wInfo(fmeBody) $fmeBody
	set wInfo(tree) $tree
	pack $fmeSearch -fill x
	pack $fmeBody -expand 1 -fill both
	return $path
}

proc ::fmeTask::item_add {id title state} {
	variable dbPath
	variable wInfo
	set tree $wInfo(tree)	
	set item [$tree item create -button no]
	set dtime $id
	$tree item lastchild 0 $item
	$tree item style set $item 0 styCheck 1 styTime 2 styTitle
	$tree item text $item 1 $dtime 2 $title

	$tree item state forcolumn $item 0 $state

	return $item
}

proc ::fmeTask::item_del {item} {
	variable wInfo
	$wInfo(tree) item delete $item
}

proc ::fmeTask::item_search {} {
	variable wInfo
	variable dbPath
	variable vars
	if {$vars(cmbState) eq [::msgcat::mc "Not Started"]} {
		set pat "N*"
	} elseif {$vars(cmbState) eq [::msgcat::mc "In Progress"]} {
		set pat "I*"
	} elseif {$vars(cmbState) eq [::msgcat::mc "Finished"]} {
		set pat "F*"
	} else {
		set pat "*"
	}
	::fmeTask::item_del all
	set todos [glob -nocomplain -directory $dbPath -types {f} $pat]
	
	foreach todo $todos {
		set id [file rootname [file tail $todo]]
		set state "NOT_STARTED"
		if {[string index $id 0] eq "I"} {
			set state "IN_PROGRESS"
		} elseif {[string index $id 0] eq "F"} {
			set state "FINISHED"
		}
		set id [string range $id 1 end]
		set dtime [string range $id 0 3]-[string range $id 4 5]-[string range $id 6 7]
		append dtime " "
		append dtime [string range $id 8 9]:[string range $id 10 11]:[string range $id 12 13]
		set fd [open $todo "r"]
		set title [read $fd]
		close $fd
		if {[string match -nocase "*$vars(txtKeyword)*" $title]} {
			::fmeTask::item_add $dtime $title $state
		}
	}
	::fmeTask::item_sort
	return	
}

proc ::fmeTask::item_sort {} {
	variable wInfo
	set tree $wInfo(tree)
	
	set column ""
	foreach col [$tree column list] {
		set arrow [$tree column cget $col -arrow]
		if {$arrow ne "none"} {
			set column $col
			break
		}
	}
	if {$arrow eq "none"} {return ""}

	if {$arrow eq "down"} {
		set order -decreasing
	} else {
		set order -increasing
	}
	
#	foreach col [$tree column list] {
#		$tree column configure $col -arrow "none"
#	}
	$tree column configure $column -arrow $arrow
	switch [$tree column cget $column -tag] {
		bounce -
		colState {
			$tree item sort root $order -column $column -command [list ::fmeTask::::compare_state $tree $column] }
		colDate {
			$tree item sort root $order -column $column -dictionary
		}
		colTitle {
			$tree item sort root $order -column $column -dictionary
		}
	}
}

proc ::fmeTask::popup_item_menu {widget X Y item} {
	variable wInfo
	if {$::fmeTask::dbPath eq ""} {return} 
	if {[winfo exists $widget.taskMenu]} {
		destroy $widget.taskMenu
	}
#	set state [$widget item state forcolumn $item 0]
	set mMain [menu $widget.taskMenu -tearoff 0]
	$mMain add command -compound left -label [::msgcat::mc "Add Task"] \
		-accelerator "Insert" \
		-command {::fmeTask::task_add}
	$mMain add separator	
	$mMain add command -compound left -label [::msgcat::mc "Edit"] \
		-accelerator "F2" \
		-command [list ::TreeCtrl::FileListEdit $wInfo(tree) $item colTitle txtTitle]
	$mMain add command -compound left -label [::msgcat::mc "Change State"] \
		-command [list ::fmeTask::ch_state $item]
	$mMain add command -compound left -label [::msgcat::mc "Delete"] \
		-image [::crowImg::get_image del] \
		-accelerator "Del"\
		-command [list event generate $widget <Delete>]
		#[list ::fmeTask::task_del $item]
	$mMain add separator
	$mMain add command -compound left -label [::msgcat::mc "Delete Completed Tasks"] \
		-command {::fmeTask::task_del_completed}
	$mMain add checkbutton -label [::msgcat::mc "Hide Completed Tasks"] \
		-variable ::fmeTask::hideCompletedTasks -onvalue 1 -offvalue 0 \
		-command {
			::fmeTask::refresh
			::crowRC::param_set $::fmeTask::rc HideCompletedTasks $::fmeTask::hideCompletedTasks
		}		
	$mMain add separator
	$mMain add command -compound left -label [::msgcat::mc "Refresh"] \
		-image [::crowImg::get_image refresh_task] \
		-command {::fmeTask::refresh} 
	
	tk_popup $mMain $X $Y
}

proc ::fmeTask::popup_widget_menu {widget X Y} {
	variable hideCompletedTasks
	if {$::fmeTask::dbPath eq ""} {return} 
	if {[winfo exists $widget.taskMenu]} {destroy $widget.taskMenu}

	set mMain [menu $widget.taskMenu -tearoff 0]
	$mMain add command -compound left -label [::msgcat::mc "Add Task"] \
		-accelerator "Insert" \
		-command {::fmeTask::task_add}
	$mMain add separator
	$mMain add checkbutton -label [::msgcat::mc "Hide Completed Tasks"] \
		-variable ::fmeTask::hideCompletedTasks -onvalue 1 -offvalue 0 \
		-command {
			::fmeTask::refresh
			::crowRC::param_set $::fmeTask::rc HideCompletedTasks $::fmeTask::hideCompletedTasks
		}
	$mMain add command -compound left -label [::msgcat::mc "Delete Completed Tasks"] \
		-command {::fmeTask::task_del_completed}
	$mMain add separator
	$mMain add command -compound left -label [::msgcat::mc "Refresh"] \
		-image [::crowImg::get_image refresh_task] \
		-command {::fmeTask::refresh} 

	tk_popup $mMain $X $Y
}

proc ::fmeTask::refresh {} {
	variable wInfo
	variable dbPath
	variable hideCompletedTasks
	
	if {$dbPath eq ""} {return} 
	$wInfo(tree) item delete all
	
	set todos [glob -nocomplain -directory $dbPath -types {f} *.todo]
	
	foreach todo $todos {
		set id [file rootname [file tail $todo]]

		if {[string index $id 0] eq "N"} {
			set state "NOT_STARTED"
		} elseif {[string index $id 0] eq "I"} {	
			set state "IN_PROGRESS"
		} elseif {[string index $id 0] eq "F"} {
			set state "FINISHED"
			if {$hideCompletedTasks} {continue}
		} else {
			set state "NOT_STARTED"
			if {[string index $id 0] eq "_"} {
				set id F$id
				file rename $todo [file join $dbPath $id.todo]
			} else {
				set id N$id
				file rename $todo [file join $dbPath $id.todo]
			}
			set todo [file join $dbPath $id.todo]
		}
		set id [string range $id 1 end]
		set dtime [string range $id 0 3]-[string range $id 4 5]-[string range $id 6 7]
		append dtime " "
		append dtime [string range $id 8 9]:[string range $id 10 11]:[string range $id 12 13]
		set fd [open $todo "r"]
		set title [read $fd]
		close $fd
		::fmeTask::item_add $dtime $title $state
	}
	::fmeTask::item_sort
	return
}

proc ::fmeTask::set_db {dbPath} {
	set ::fmeTask::dbPath $dbPath
	if {![file exists $dbPath]} {file mkdir $dbPath}
	::fmeTask::refresh
	return
}



proc ::fmeTask::task_add {} {
	variable dbPath
	variable wInfo
	set tree $wInfo(tree)
	::fmeTaskMgr::raise 0
	set id [clock format [clock scan now] -format "%Y%m%d%H%M%S"]
	set todo [file join $dbPath "N$id.todo"]
	close [open $todo "w"]
	set dtime [string range $id 0 3]-[string range $id 4 5]-[string range $id 6 7]
	append dtime " "
	append dtime [string range $id 8 9]:[string range $id 10 11]:[string range $id 12 13]		
	set item [::fmeTask::item_add $dtime "" "NOT_STARTED"]
	$tree selection clear
	$tree selection add $item
	$tree see $item
	update
	::TreeCtrl::FileListEdit $wInfo(tree) $item colTitle txtTitle
	return	
}

proc ::fmeTask::task_del_completed {} {
	variable dbPath
	variable wInfo
	::fmeTaskMgr::raise "Tasks"
	set tree $wInfo(tree)
	set ret [tk_messageBox -title [::msgcat::mc "Delete Completed Tasks"] -type yesno \
			-icon info -message [::msgcat::mc "Do you want to delete completed task ?"]]
	if {$ret eq "no"} {return}
	if {$dbPath eq ""} {return} 
	set items [$tree item children root]
	
	foreach item $items {
		set state [$tree item state forcolumn $item 0]
		if {$state eq "FINISHED"} {
			set dtime [$tree item element cget $item colDate txtTime -text]
			::fmeTask::item_del $item
			set id [regsub -all {[\-\:\s]} $dtime {}]
			set todo [file join $dbPath "F$id.todo"]
			if {[file exists $todo]} {file delete $todo}						
		}
	}
}

proc ::fmeTask::task_del {item} {
	variable dbPath
	variable wInfo
	
	set tree $wInfo(tree)
	set txt [$tree item element cget $item colTitle txtTitle -text]
	if {[string trim $txt] eq ""} {
		set ret "yes"
	} else {
		set ret [tk_messageBox -title [::msgcat::mc "Delete Task"] -type yesno \
			-icon info -message [::msgcat::mc "Do you want to delete task ?"]]
	}
	if {$ret eq "no"} {return}
	if {$dbPath eq ""} {return} 
	set dtime [$tree item element cget $item colDate txtTime -text]
	::fmeTask::item_del $item
	set id [regsub -all {[\-\:\s]} $dtime {}]
	foreach fname [list "N$id.todo" "I$id.todo" "F$id.todo"] {
		set todo [file join $dbPath $fname]
		if {[file exists $todo]} {file delete $todo}
	}	
	return
}

proc ::fmeTask::unset_db {} {
	variable wInfo
	set ::fmeTask::dbPath ""
	$wInfo(tree) item delete all
	return
}




