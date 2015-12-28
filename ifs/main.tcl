#!/bin/sh
#\
exec wish "$0" ${1+"$@"}
 
package require msgcat
package require TclOO

encoding system utf-8

namespace eval ::dApp {
	variable Obj
	array set Obj [list]
	
	variable Env
	
	array set Env [list \
		os ""	\
		appPath "" \
		date "2009/10/26" \
		imgPath "" \
		locale [::msgcat::mclocale] \
		rcPath [file join $::env(HOME) ".ifs"] \
		title "ifs" \
		version "0.1" \
	]
}

oo::class create ::dApp::main {
	
	constructor {args} {
		my Env_Init
		my DB_Init
		my Ui_Init
		my Module_Init
		
		$::dApp::Obj(uimgr) tab_last
	}
	
	destructor {

	}
	
	method quit {} {	
		my Rc_Save

		exit
	}
	
	method DB_Init {} {
		set appPath $::dApp::Env(appPath)
		source -encoding utf-8 [file join $appPath db_adjuster.tcl]
		set ::dApp::Obj(db) [::dApp:dbAdjuster new]
	}
	
	method Env_Init {} {

		set appPath [file normalize [info script]]
		if {[file type $appPath] == "link"} {set appPath [file readlink $appPath]}		
		
		set appPath [file dirname $appPath]
		
		set ::auto_path [linsert $::auto_path 0 [file join $appPath "lib"]]
		set os [string tolower $::tcl_platform(os)]

		if {[string first "windows" $os] >= 0} {set os "windows"}

		set lib [file join $appPath lib_$os]
		if {[file exists $lib]} {lappend ::auto_path $lib}		
		
		if {$::tcl_version < 8.6} {
			package require img::png
		}
		
		package require twidget::ibox
		package require twidget::dialog
		package require ::ddb::dbInfo
		package require ::ddb::sqlite
		package require ::ddb::tableview
		package require ::ddb::validator

		if {![file exists $::dApp::Env(rcPath)]} {file mkdir $::dApp::Env(rcPath)}
		
		set ::dApp::Env(os) $os		
		set ::dApp::Env(appPath) $appPath		
		set ::dApp::Env(imgPath) [file join $appPath images]		
		set ::dApp::Obj(ibox)	[::twidget::ibox new]
		
		# <-- load images
		if {[file exists $::dApp::Env(imgPath)]} {
			foreach {f} [glob -nocomplain -directory [file join $appPath images] -- *.png] {
				if {[string index [file tail $f] 0] == "."} {continue}
				$::dApp::Obj(ibox) add $f
			}
		}
		#-->
		
		source -encoding utf-8 [file join $appPath themes common.tcl]
		source -encoding utf-8 [file join $appPath themes $os.tcl]

		event add <<ButtonM-Click>> <Button-2>
		event add <<ButtonL-DClick>> <Double-Button-1>
		
		event add <<Copy>> <Control-c> <Control-C>
		event add <<Paste>> <Control-v> <Control-V>
		event add <<Cut>> <Control-x> <Control-X>

		bind Text <<Copy>> [list tk_textCopy %W]
		bind Text <<Paste>> [list tk_textPaste %W]
		bind Text <<Cut>> [list tk_textCut %W]

		my Env_[string totitle $os]_Init
		
		my Locale_Init
	}
	
	method Env_Darwin_Init {} {}
	method Env_Windows_Init {} {}
	method Env_Linux_Init {} {}
	
	method Locale_Init {} {
		set appPath $::dApp::Env(appPath)
		::msgcat::mclocale $::dApp::Env(locale)
		::msgcat::mcload [file join $appPath locales]	
	}
	
	method Module_Init {} {
		
		set appPath $::dApp::Env(appPath)
		set mdudir [file join $appPath modules]
		source [file join $mdudir module.tcl]

		set dlist [glob -nocomplain -directory $mdudir -types {d} -- *]
		set cut 0
		foreach {d} $dlist {
			set init [file join $d init.tcl]
			if {![file isfile $init]} {continue}
			set MODULE [::dApp::module new $d]
			source -encoding utf-8 $init
			$MODULE init
		}
	}
	
	method Rc_Load {} {}
	
	method Rc_Save {} {
	}

	
	method Ui_Init {} {
		set ibox $::dApp::Obj(ibox)
		set appPath $::dApp::Env(appPath)
		
		source -encoding utf-8 [file join $appPath ui_manager.tcl]
		
		set ::dApp::Obj(uimgr) [::dApp:uiManager new]

		wm title . "$::dApp::Env(title) v$::dApp::Env(version)"
		wm protocol . WM_DELETE_WINDOW [list [self object] quit]
	}

}

::dApp::main new
