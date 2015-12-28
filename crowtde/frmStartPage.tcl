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

namespace eval ::frmStartPage {
	variable vars
	array set vars ""
	
	variable wInfo
	array set wInfo ""
}

proc ::frmStartPage::show {path} {
	variable wInfo
	variable vars
	if {[winfo exists $path]} {destroy $path}
	Dialog $path -title [::msgcat::mc "CrowTDE Start Page"] -modal local
	set frmStartPage [$path getframe]
	set lblTitle [label $frmStartPage.lblTitle -text [::msgcat::mc "Please Choose Function"] -relief groove -bd 2]
	
	# loading default
	set hlist [::crowRecently::get_recently_projects]
	set ::frmStartPage::vars(function) NEW
	set last ""
	if {$hlist ne "" && [file exists [lindex $hlist 0]]} {
		set last [lindex $hlist 0]
		set vars(function) "LAST"
	}
	set vars(lastProject) $last
	set vars(projectHistory) $hlist
	#
	
	set fmeFun [frame $frmStartPage.fmeFun]
	set rdoNewProject [radiobutton $fmeFun.rdoNewProject -value NEW -variable ::frmStartPage::vars(function)\
		-text [::msgcat::mc "Create New Project..."] -anchor w -justify left\
		-command ::frmStartPage::rdoGroup_click ]
	set rdoLastProject [radiobutton $fmeFun.rdoLastProject -value LAST  -variable ::frmStartPage::vars(function)\
		-text [::msgcat::mc "Open Last Project (%s)" $last] -anchor w -justify left\
		-command ::frmStartPage::rdoGroup_click ]
	set rdoOpenProject [radiobutton $fmeFun.rdoOpenProject -value OPEN -variable ::frmStartPage::vars(function)\
		-text [::msgcat::mc "Open Project"] -anchor w -justify left \
		-command ::frmStartPage::rdoGroup_click]
	pack $rdoNewProject -fill x
	pack $rdoLastProject -fill x
	pack $rdoOpenProject -fill x
	
	if {$hlist eq ""} {$rdoLastProject configure -state disabled}
	
	set fmeOpen [frame $frmStartPage.fmeOpen -bd 2 -relief ridge]
	set lblOpen [label $fmeOpen.lblOpen -text [::msgcat::mc "Project:"] -anchor w -justify left]
	set txtOpen [entry $fmeOpen.txtOpen -textvariable ::frmStartPage::vars(projectPath)]
	set btnOpen [button $fmeOpen.btnOpen -text [::msgcat::mc "Browse..."] -command {::frmStartPage::btnOpen_click}]
	set lstHistroy [listbox $fmeOpen.lstHistroy -listvariable ::frmStartPage::vars(projectHistory) \
		-selectmode browse]
	bind $lstHistroy <ButtonRelease-1> {
		catch {
			if {[%W cget -state] ne "disabled"} {set ::frmStartPage::vars(projectPath) [%W get [%W curselection]]}
		}
	}
	
	grid $lblOpen -row 0 -column 0 -sticky "we"
	grid $txtOpen -row 0 -column 1 -sticky "we"
	grid $btnOpen -row 0 -column 2 -sticky "we"
	grid $lstHistroy -row 1 -column 0 -columnspan 3 -sticky "news"
	grid rowconfigure $fmeOpen 1 -weight 1
	grid columnconfigure $fmeOpen 1 -weight 1
	
	set fmeBtn [frame $frmStartPage.fmeBtn]
	set btnOk [button $fmeBtn.btnOk -text [::msgcat::mc "Ok"] \
		-command {::frmStartPage::btnOk_click}]
	set btnCancel [button $fmeBtn.btnCancel -text [::msgcat::mc "Cancel"] \
		-command {::frmStartPage::btnCancel_click}]
	pack $btnOk -expand 1 -fill both -padx 2 -pady 2 -side left
	pack $btnCancel -expand 1 -fill both -padx 2 -pady 2 -side left
	
	pack $lblTitle -fill x
	pack $fmeFun -fill x
	pack $fmeOpen -fill both -expand 1
	pack $fmeBtn -fill x
	
	set wInfo(frmStartPage) $path
	set wInfo(fmeOpen) $fmeOpen
	::frmStartPage::rdoGroup_click

	wm minsize $path 400 400
	wm resizable $path 0 0
	set x [expr [winfo x .] + [winfo width .]/2 - 200]
	set y [expr [winfo y .] + [winfo height .]/2 - 200]
	after idle [list update ; wm geometry $path +$x+$y]
	$path draw
}

proc ::frmStartPage::btnCancel_click {} {
	variable wInfo
	$wInfo(frmStartPage) enddialog ""
	after idle [list destroy $wInfo(frmStartPage)]
}


proc ::frmStartPage::btnOpen_click {} {
	variable vars
	set ret [tk_chooseDirectory -title [::msgcat::mc "Open Project"] -mustexist 1]
	if {$ret eq ""} {return}
	set vars(projectPath) $ret
}

proc ::frmStartPage::btnOk_click {} {
	variable vars
	variable wInfo
	switch -exact $vars(function) {
		"NEW" {$wInfo(frmStartPage) enddialog [list "NEW" ""]}
		"LAST" {$wInfo(frmStartPage) enddialog [list "LAST" $vars(lastProject)]}
		"OPEN" {$wInfo(frmStartPage) enddialog [list "OPEN" $vars(projectPath)]}		
	}
	after idle [list destroy $wInfo(frmStartPage)]
}

proc ::frmStartPage::rdoGroup_click {} {
	variable vars
	variable wInfo
	set childs [winfo children $wInfo(fmeOpen)]
	foreach child $childs {$child configure -state "disabled"}
	if {$vars(function) eq "OPEN"} {
		foreach child $childs {$child configure -state "normal"}
	}
}
