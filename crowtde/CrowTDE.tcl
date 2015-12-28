#!/bin/sh
#\
exec wish "$0" ${1+"$@"}

# CrowTDE - A Tcl/Tk Development Environment  
#   
# CrowTDE.tcl - This is the startfile for CrowTDE
#
# Copyright (C) 2006-2007 Tai, Yuan-Liang
#
# This program is free software; you can redistribute it and/or modify  
# it under the terms of the GNU General Public License as published by  
# the Free Software Foundation; either version 2 of the License, or  
# (at your option) any later version.  
#
# This program is distributed in the hope that it will be useful,  
# but WITHOUT ANY WARRANTY; without even the implied warranty of  
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
# GNU General Public License for more details.  
#
# You should have received a copy of the GNU General Public License  
# along with this program; if not, write to the Free Software  
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA 
#         

namespace eval ::crowTde {
	variable appPath ""
	
	variable wInfo
	array set wInfo ""
	
	variable showToolbar 1
	
	variable locale "en_us"
	
	variable inVFS 0
	
	variable version 0.5
}

proc ::crowTde::init {path} {
	variable wInfo
	variable showToolbar
	variable locale
	variable appPath
	variable inVFS
	
	#<!-- CrowTDE PWD
	set appPath [file normalize [info script]]
	if {[file type $appPath] eq "link"} {set appPath [file readlink $appPath]}
	set appPath [file dirname $appPath]
	#-->
	# check in starkit
	if {[namespace exists ::starkit]} {
		set inVFS 1
		set appPath [file dirname $::starkit::topdir]
	}	
	
	#<!-- Setup ::auto_path
	# pkgNames : save system package names for crowSyntax 
	set pkgNames [lsort -dictionary -increasing [package names]]
	lappend ::auto_path [file join $::crowTde::appPath "lib"]
	set platformLib [file join $::crowTde::appPath "lib_$::tcl_platform(platform)"]
	if {[file exists $platformLib]} {lappend ::auto_path $platformLib}
	#-->

	# Create Resource Directory
	set rcDir [file join $::env(HOME) ".CrowTDE"]
	if {![file exists $rcDir]} {file mkdir $rcDir}


	# check version
	set ver [file join $rcDir version]
	if {![file exists $ver]} {
		set fd [open $ver w]
		puts -nonewline $fd 0.0
		close $fd
	}
	
	set fd [open $ver r]
	set oVersion [string trim [read -nonewline $fd]]
	close $fd
	
	if {$oVersion != $::crowTde::version} {
		foreach f [list lib tools tclkit.bin tclkit.exe sdx.kit tclkit-8.4.13.bin tclkit-8.4.13.exe] {
			catch {
				file delete -force [file join $rcDir $f]
			}
		}		
		set fd [open [file join $rcDir version] w]
		puts -nonewline $fd $::crowTde::version
		close $fd
	}
	
	set sdx [file join $appPath tools sdx.kit]
	switch $::tcl_platform(platform) {
		"windows" {
		        package require Tkprint
		        package require dde
		        package require twapi
		        set tclkit [file join $appPath tools tclkit.exe]
		}
		"unix" {
		        set tclkit [file join $appPath tools tclkit.bin]
		}
	}
	
	package require msgcat
	catch {package require snack}
	package require BWidget        
	#package require img::png
	package require tkpng
	package require treectrl
	package require tdom
	package require Tclparser

	package require crowFileProperties
	package require inputDlg
	package require crowImg
	package require crowGetDir
	package require crowFont
	package require crowRC
	package require crowRecently
	package require crowIO
	package require crowExec
	package require crowMacro
	package require crowTemplate
	
	package require crowFileRelation
	package require crowNoteBook
	package require crowPanedWindow
	package require crowSyntax
	package require crowEditor
	package require crowSdx
	package require crowDebugger
	encoding system utf-8

	
	::crowImg::init [file join $::crowTde::appPath "images"]
	::crowTemplate::init [file join $::crowTde::appPath "templates"]
	::crowSyntax::init
	::crowSdx::init $tclkit $sdx
	
	wm withdraw .
	set rc [file join $rcDir "CrowTDE.rc"]
	if {![file exists $rc]} {
		source [file join $::crowTde::appPath frmFirst.tcl]
		::frmFirst::show .crowFrmFirst
		namespace delete ::frmFirst
	}
	
	#<!- Loading Default Parameters
	set x [expr [winfo screenwidth .]/2 - 800/2]
	set y [expr [winfo screenheight .]/2 - 600/2]                
	array set params ""
	::crowRC::param_get_all $rc params
	if {![info exists params(locale)]} {set params(locale) $locale}
	if {![info exists params(CrowTDE.Geometry)]} {set params(CrowTDE.Geometry) "800x600+$x+$y"}
	if {![info exists params(LRFrame.SashPos)]} {set params(LRFrame.SashPos) 200}
	if {![info exists params(MainFrame.SashPos)]} {set params(MainFrame.SashPos) 400}
	if {![info exists params(CrowTDE.StartPage)]} {set params(CrowTDE.StartPage) "DEFAULT"}
	if {![info exists params(Toolbar.Show)]} {set params(Toolbar.Show) $showToolbar}
	if {![info exists params(TextArea.SashPos)]} {set params(TextArea.SashPos) "0 100"}
	
	set showToolbar $params(Toolbar.Show)
	::msgcat::mclocale $params(locale)
	::msgcat::mcload [file join $::crowTde::appPath "locale"]
	set locale $params(locale)
	#-->
	
	# Show Welcome Window
	source [file join $::crowTde::appPath frmWelcome.tcl]
	::frmWelcome::show ".frmWelcome"

	source         [file join $::crowTde::appPath fmeProjectManager.tcl]
	source         [file join $::crowTde::appPath fmeProcManager.tcl]        
	source         [file join $::crowTde::appPath fmeTabMgr.tcl]
	source         [file join $::crowTde::appPath fmeTabEditor.tcl]
	source         [file join $::crowTde::appPath fmeMenuBar.tcl]
	source         [file join $::crowTde::appPath fmeToolbar.tcl]
	source         [file join $::crowTde::appPath fmeTaskMgr.tcl]
	source         [file join $::crowTde::appPath fmeStatusBar.tcl]
	source         [file join $::crowTde::appPath frmSetting.tcl]
	source         [file join $::crowTde::appPath frmNewProject.tcl]
	source         [file join $::crowTde::appPath frmStartPage.tcl]
	source         [file join $::crowTde::appPath frmProjectProperty.tcl]
	source         [file join $::crowTde::appPath fmePlayer.tcl]
	source         [file join $::crowTde::appPath fmeGenericSetting.tcl]
	source         [file join $::crowTde::appPath frmAbout.tcl]
	source         [file join $::crowTde::appPath frmSearchInFiles.tcl]
	source         [file join $::crowTde::appPath frmSearchFiles.tcl]
	source         [file join $::crowTde::appPath fmeDocView.tcl]
	source         [file join $::crowTde::appPath fmeDebugger.tcl]
	encoding system utf-8
#        
	::frmWelcome::incr_progress
	::crowIO::init
	::frmWelcome::incr_progress
	::crowMacro::init [file join $::crowTde::appPath "macro"]
	::frmWelcome::incr_progress
	
	::crowEditor::init [file join $::crowTde::appPath lib Tclparser.tcl] [file join $platformLib crowSyntax.tcl]

	#<!-- set windows default options
	option add *Entry.Font [::crowFont::get_font medium]
	option add *Label.Font [::crowFont::get_font smaller]
	option add *Button.Font [::crowFont::get_font smaller]
	option add *Checkbutton.Font [::crowFont::get_font smaller]
	option add *Menu.Font [::crowFont::get_font smaller]
	option add *Text.Font [::crowFont::get_font text]
	option add *Listbox.Font [::crowFont::get_font medium]
	option add *Radiobutton.Font [::crowFont::get_font smaller]
	option add *TreeCtrl*Font [::crowFont::get_font medium]
	option add *Menu.Font [::crowFont::get_font menu]
	option add *Menu.TearOff 0
	option add *fmeStatusBar*Font [::crowFont::get_font smaller]
	option add *Button.BorderWidth 1
	option add *Menu.BorderWidth 1
	option add *Text.Background white
	option add *Entry.Background white
	option add *Entry.Relief groove
	option add *Combox.Relief groove
	#option add *TreeCtrl.Relief groove
	::frmWelcome::incr_progress
	#-->
	
	set mbar [::fmeMenuBar::init $path.fmeMenuBar $::crowTde::appPath]
	. configure -menu $mbar
	::frmWelcome::incr_progress
	
	# Make Gui
	#   +--------------+
	#   |     mbar     |
	#   +--------------+
	#   |     tbar     |
	#   +--------------+
	#   |              |
	#   |  mainFrame   |
	#   |              |
	#   +--------------+
	#   | fmeStatusBar |
	#   +--------------+
	#
	
	#<!-- Init Toolbar
	set tbar [::fmeToolbar::init $path.tbar $::crowTde::appPath]
	set wInfo(tbar) $tbar
	#-->
	
	#<!-- Init Main Frame
	#     |<-        lrFrame          -|
	#     +------------+---------------+  --
	#     |            |               |   
	#     |  fmeTabMgr |  fmeTabEditor |
	#     |            |               |  mainFrame
	#     +------------+---------------+
	#     |           fmeTaskMgr       |
	#     +----------------------------+  --
	#
	set mainFrame [::crowPanedWindow::crowPanedWindow $path.mainFrame v]
	set wInfo(mainFrame) $mainFrame
	# lrFrame
	set lrFrame [crowPanedWindow::crowPanedWindow $mainFrame.lrFrame h]
	set wInfo(lrFrame) $lrFrame        
	set fmeTabMgr [::fmeTabMgr::init $lrFrame.fmeTabMgr]
	::frmWelcome::incr_progress
	
	set fmeTextArea [panedwindow $lrFrame.fmeTextArea -orient vertical \
		-showhandle 0 -sashrelief groove -sashwidth 2 ]
	set fmeDocArea [frame $fmeTextArea.fmeDocArea]
	set fmeDocView [::fmeDocView::doc_init $fmeDocArea.body [file join $::crowTde::appPath "./docs/index.htm"]]
	set wInfo(fmeDocView) $fmeDocView
	::fmeDocView::btnCol_show $fmeDocView
	pack $fmeDocView -expand 1 -fill both
	
	set fmeEditor [::fmeTabEditor::init $fmeTextArea.fmeTabEditor]
	$fmeTextArea add $fmeDocArea $fmeEditor
	::crowPanedWindow::set_widget $lrFrame $fmeTabMgr $fmeTextArea
	set wInfo(fmeTextArea) $fmeTextArea
	::frmWelcome::incr_progress
	
	# fmeTaskMgr
	set fmeTaskMgr [::fmeTaskMgr::init $mainFrame.fmeTaskMgr]
	::crowPanedWindow::set_widget $mainFrame $fmeTaskMgr $lrFrame
	#-->
	
	#<!-- Init Statusbar
	set fmeStatusBar [::fmeStatusBar::init $path.fmeStatusBar $::crowTde::appPath]
	set wInfo(fmeStatusBar) $fmeStatusBar
	::frmWelcome::incr_progress
	#-->
	
	#<!-- Show/Hide Toolbar
	if {$showToolbar} {
		::crowTde::toolbar_expand
	} else {
		::crowTde::toolbar_collapse
	}
	grid rowconfigure [winfo parent $tbar] 1 -weight 1
	grid columnconfigure [winfo parent $tbar] 0 -weight 1
	::frmWelcome::incr_progress
	#-->
	
	#<!-- loading plugins
	set plugins [glob -nocomplain -directory [file join $appPath "plugins"] -type {d} *]
	foreach dir $plugins {
		set fd [open [file join $dir init.xml] r]
		set data [read $fd]
		close $fd
		set doc [dom parse $data]
		set root [$doc documentElement]
		
		array set arrInfo [list pluginPath $dir name "" version "" auth "" namespace	""	init "" description ""  configure "" ]
		set nodeTemplate [$root selectNodes "/Plugin"]
		set arrInfo(name) [$nodeTemplate getAttribute "name"]
		set arrInfo(version) [$nodeTemplate getAttribute "version"]
		set arrInfo(auth) [$nodeTemplate getAttribute "auth"]
		
		set arrInfo(namespace) [[$nodeTemplate selectNodes "Namespace"] text]
		set arrInfo(init) [[$nodeTemplate selectNodes "Init"] text]
		set arrInfo(configure) [[$nodeTemplate selectNodes "Configure"] text]
		set arrInfo(description) [[$nodeTemplate selectNodes "Description"] text]
		
		set init [file join $dir "init.tcl"]
#		puts -nonewline [::msgcat::mc "Loading plugin '%s' ..." $arrInfo(name)]		
		if {[catch {
			if {[file exists $init]} {source $init}
			$arrInfo(init) $appPath $dir
		}]} {
#			puts "fail!"
		} else {
#			puts "ok!"
		}
#		update
		array unset arrInfo
		$doc delete			
	}
	::frmWelcome::incr_progress
	#-->		
	
	#<!-- Destroy welcome window
	::frmWelcome::bye
	namespace delete ::frmWelcome
	#-->
	
	
	#<!-- Show . windows & Welcom Message
	wm deiconify .
	wm geometry . $params(CrowTDE.Geometry)
	update
	

	puts [::msgcat::mc "CrowTDE Start success, thanks for use ^o^"]
	::crowPanedWindow::set_sash_pos $mainFrame $params(MainFrame.SashPos)
	::crowPanedWindow::set_sash_pos $lrFrame $params(LRFrame.SashPos)
	#-->
	
	#<!-- Show Start Page &
	set last [lindex [::crowRecently::get_recently_projects] 0]
	if {![file exists $last]} {set params(CrowTDE.StartPage) "DEFAULT"}
	switch -exact $params(CrowTDE.StartPage) {
		"NEW" {set ret [list "NEW" ""]}
		"DEFAULT" {
		        set ret [::frmStartPage::show ".frmStartPage"]
		        namespace delete ::frmStartPage
		}
		"LAST" {
		        if {$last eq ""} {
		                set ret ""
		        } else {
		                set ret [list "LAST" $last]
		        }
		}
		default {set ret ""}
	}

	update
	switch -exact -- [lindex $ret 0] {
		"NEW" {::fmeProjectManager::project_new}
		"LAST" {
		        if {[file exists [lindex $ret 1]]} {
		                ::fmeProjectManager::project_open [lindex $ret 1]
		        }
		}
		"OPEN" {::fmeProjectManager::project_open [lindex $ret 1]}
	}
	#-->
	
	set ::crowSyntax::argValues(require) $pkgNames
	::fmeProcManager::refresh
    ::fmeDebugger::breakpoint_load	
    ::fmeDebugger::watchpoint_load
	set mode [::crowRC::param_get $rc CrowTDE.DebugMode]
	if {$mode ne ""} {
		set ::crowDebugger::sysInfo(mode) $mode
	}

	foreach {x y} $params(TextArea.SashPos) {}
	$fmeTextArea sash place 0 $x $y
	wm protocol . WM_DELETE_WINDOW ::crowTde::destroy
	
}

# ::crowTde::destroy
#   - Trigger by cancel button & Menubar/Exit.
#
proc ::crowTde::destroy {} {
	variable wInfo
	variable locale
	#<!-- Save Layout
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	::crowRC::param_set $rc locale $locale
	::crowRC::param_set $rc CrowTDE.Geometry "[winfo width .]x[winfo height .]+[winfo x .]+[winfo y .]"
	::crowRC::param_set $rc LRFrame.SashPos "[::crowPanedWindow::get_sash_pos $wInfo(lrFrame)]"
	::crowRC::param_set $rc MainFrame.SashPos "[::crowPanedWindow::get_sash_pos $wInfo(mainFrame)]"
	::crowRC::param_set $rc TextArea.SashPos "[$wInfo(fmeTextArea) sash coord 0]" 
	#-->
	
	#<-- Check modified files. Save , NO , Cancel?
	source         [file join $::crowTde::appPath frmCheckSave.tcl]
	set ret [::frmCheckSave::show ".frmCheckSave"]
	#-->
	if {$ret == 1} {exit}
}

# ::crowTde::get_toolbar_state
#   1 - normal
#   0 - collapse
proc ::crowTde::get_toolbar_state {} {
	variable showToolbar
	return $showToolbar
}

# ::crowTde::toolbar_collapse
#   collapse toolbar
proc ::crowTde::toolbar_collapse {} {
	variable wInfo
	variable showToolbar
	set showToolbar 0
	#<!-- create smaller toolbar
	set parent [winfo parent $wInfo(tbar)]
	if {$parent eq "."} {set parent ""}        
	set tbar2 [frame $parent.tbar2 -bd 2 -height 10 -relief groove]
	set sep [label $tbar2.sep0 -bd 2 -relief groove]
	place $sep -x 0 -y 0 -width 30 -height 6
	bind $sep <ButtonRelease-1> {::crowTde::toolbar_expand}
	bind $sep <Enter> {%W configure -bg #808080}
	bind $sep <Leave> {%W configure -bg [. cget -bg]}
	#-->
	
	grid forget $wInfo(tbar)
	grid $tbar2 -row 0 -column 0 -sticky "we"
	grid $wInfo(mainFrame) -row 1 -column 0 -sticky "news"
	grid $wInfo(fmeStatusBar) -row 2 -column 0 -sticky "we"
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	::crowRC::param_set $rc Toolbar.Show 0

}

# ::crowTde::toolbar_expand
#   expand toolbar
proc ::crowTde::toolbar_expand {} {
	variable wInfo
	variable showToolbar
	set showToolbar 1
	#<!-- destroy smaller toolbar when exists.
	set parent [winfo parent $wInfo(tbar)]
	if {$parent eq "."} {set parent ""}
	if {[winfo exists $parent.tbar2]} {
		grid forget $parent.tbar2
		::destroy $parent.tbar2
	}
	#-->
	
	grid $wInfo(tbar) -row 0 -column 0 -sticky "we"
	grid $wInfo(mainFrame) -row 1 -column 0 -sticky "news"
	grid $wInfo(fmeStatusBar) -row 2 -column 0 -sticky "we"
	set rc [file join $::env(HOME) ".CrowTDE" CrowTDE.rc]
	::crowRC::param_set $rc Toolbar.Show 1        
}


::crowTde::init ""

