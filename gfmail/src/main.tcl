#!/bin/sh
#\
exec wish "$0" ${1+"$@"}

# GFMail - GFMail is File Manager.
# 
# Copyright (C) 2008 Tai, Yuan-Liang
namespace eval ::dApp {
	
	package require msgcat
	
	variable Priv
	array set Priv [list \
		appPath "" \
		ibox "" \
		title "GFMail" \
		version "1.4 beta" \
		date "2009-04-23" \
		authors "dai" \
		email "adai1115@yahoo.com.tw" \
		host "http://got7.org" \
		rcPath [file join $::env(HOME) "gfs"] \
		homePage "http://got7.org" \
		gDisk "" \
		os "" \
	]

}

proc ::dApp::init {} {
	variable Priv

	#<!-- PWD
	set appPath [file normalize [info script]]
	if {[file type $appPath] eq "link"} {set appPath [file readlink $appPath]}
	set appPath [file dirname $appPath]
	set Priv(appPath) $appPath
	#-->
	
	
	#<!-- Setup ::auto_path

	set os [string tolower $::tcl_platform(os)]
	if {[string first "darwin" $os] >= 0 } {
		set os "darwin"
	} elseif {[string first "windows" $os] >= 0} {
		set os "win32"
	} else {
		set os "linux"
	}
	set Priv(os) $os

	set platformLib [file join $appPath lib_$os]
	set ::auto_path [linsert $::auto_path 0 [file join $appPath "lib"]]
	if {[file exists $platformLib]} {set ::auto_path [linsert $::auto_path 0 $platformLib]}
	#-->
	


	# check in starkit
	if {[namespace exists ::vfs]} {
		
		set Priv(rcPath) [file join [file dirname $appPath] "gfs"]
		if {![file exists $Priv(rcPath)]} {
			if {[catch {file mkdir $Priv(rcPath)}]} {
				set ans [tk_messageBox -icon "error" \
					-default "ok" \
					-title [::msgcat::mc "Error"] \
					-message [::msgcat::mc "Can't make filesystem folder."] \
					-type ok]				
				exit
			}
		}
				
		if {![file exists $Priv(rcPath)]} {file mkdir $Priv(rcPath)}
		set tlsDir [file join $Priv(rcPath) tls]
		if {![file exists $tlsDir]} {
			file mkdir $tlsDir
			file copy -force [file join $platformLib tls1.6] $tlsDir
		}
		set ::auto_path [linsert $::auto_path 0 $tlsDir]
		
	} else {
		set Priv(rcPath) [file join $appPath "gfs"]
		if {![file exists $Priv(rcPath)]} {
			if {[catch {file mkdir $Priv(rcPath)}]} {
				set ans [tk_messageBox -icon "error" \
					-default "ok" \
					-title [::msgcat::mc "Error"] \
					-message [::msgcat::mc "Can't make filesystem folder."] \
					-type ok]				
				exit
			}
		}
	}
	#::msgcat::mclocale zh_tw
	if {[file exists [file join $appPath "locales"]]} {
		::msgcat::mcload [file join $appPath "locales"]
	}
	::msgcat::mclocale zh_tw
	# Create Resource Directory

	if {![file exists $Priv(rcPath)]} {file mkdir $Priv(rcPath)}

	#package require Tk
	#package require tile
	package require img::png
	package require img::jpeg
	package require img::gif
	package require tooltip
	package require toolbar
	package require ttimgr
	package require gvfs
	package require BWidget
	package require treectrl
	package require ttdialog

	switch $os {
		"win32" {
			set Priv(Desktop) [file join $::env(HOME) [::msgcat::mc "Desktop"]]
		}
		"linux" -
		"darwin" {
			set Priv(Desktop) [file join $::env(HOME) "Desktop"]
		}
	}

	if {[file exists [file join $appPath images]]} {
		set ibox [::ttimgr::create]
		foreach {f} [glob -nocomplain -directory [file join $appPath images] *.gif *.jpg *.png] {
			set name [file rootname [file tail $f]]
			$ibox add $name $f
		}
		set Priv(ibox) $ibox
	}
	
	::gvfs::connect
	source [file join $appPath about.tcl]
	source [file join $appPath body.tcl]
	pack [::body::init .body] -expand 1 -fill both
	
	if {[file exists [file join $appPath sbar.tcl]]} {
		source [file join $appPath sbar.tcl]
		pack [::sbar::init .sbar] -expand 0 -fill x
	}
	
	wm title . [::msgcat::mc "GFMail - GFMail is File Manager"]

	::gvfs::queue_reset_all
	::body::queue_refresh
	::body::siteMgr_refresh
	::body::queue_trace_state	

	wm protocol . WM_DELETE_WINDOW ::dApp::destroy
}

proc ::dApp::destroy {} {
	variable Priv
	::gvfs::disconnect
	exit
}

proc ::dApp::openurl {url} {
	variable Priv
	
	if {$url == ""} {return}
	
	switch -exact -- $Priv(os) {
		"win32" {
				if {[file exists "C:/Program Files/Mozilla Firefox/firefox.exe"]} {
					exec "C:/Program Files/Mozilla Firefox/firefox.exe" $url &
					return
				}			
				if {[file exists "C:/Program Files/Internet Explorer/iexplore.exe"]} {
					exec "C:/Program Files/Internet Explorer/iexplore.exe" $url &				
				}
		}
		"linux" {
			exec firefox $url &
		}
		"darwin" {
				if {[file exists /applications/Firefox.app]} {
					exec open -a Firefox $url &
					return
				} 
				exec open -a Safari $url &
		}
	}
}	

::dApp::init


	
