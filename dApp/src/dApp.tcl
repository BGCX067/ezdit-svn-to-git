#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

package require msgcat

#conf_start , do not modify this line
namespace eval ::dApp {
	variable Priv
	# appName -> the filename of this application.  ex. ezdit , crowtde ...
	array set Priv [list \
		appName "dApp" \
		appPath "" \
		locale "en_us" \
		os "" \
		title [::msgcat::mc "The title of this application."] \
		useTk 1 \
		version 0.1 \
	]
}
#conf_end  , do not modify this line

proc ::dApp::boot {} {
	variable Priv

	set appPath [file normalize [info script]]
	if {[file type $appPath] == "link"} {set appPath [file readlink $appPath]}

	while {![file exists [file join $appPath "dApp.tcl"]]} {
		set appPath [file dirname $appPath]
	}

	set lib [file join $appPath "lib" "common"]
	if {[file exists $lib]} {	
		set ::auto_path [linsert $::auto_path 0 $lib]
		::tcl::tm::path add $lib
	}

	set os [string map [list " " "_"] [string tolower $::tcl_platform(os)]]

	set lib [file join $appPath "lib" $os]
	if {[file exists $lib]} {
		set ::auto_path [linsert $::auto_path 0 $lib]
		::tcl::tm::path add $lib
	}

	set Priv(appPath) $appPath
	set Priv(os) $os

	::dApp::locale_init

	append cmd {set Priv(title) } {[} {::msgcat} {::mc $Priv(title)} {]}
	eval $cmd

	if {$Priv(useTk)} {
		package require Tk
		if {$::tcl_version < 8.6} {package require img::png}
		
		foreach img [glob -directory [file join $appPath image] -types {f} *.png] {
			image create photo [file tail $img] -file $img
		}

		if {[lsearch -exact [image names] dApp.png] >= 0} {wm iconphoto . "dApp.png"}

		wm title . $Priv(title)
		wm protocol . WM_DELETE_WINDOW ::dApp::quit
	}

	::dApp::env_${os}_init

	::dApp::main
}

proc ::dApp::dock_cb {evt} {
	variable Priv

	if {$evt == "WM_MOUSEMOVE"} {
		winico taskbar modify $Priv(dock) -text $Priv(title)
	}

	if {$evt != "WM_LBUTTONDOWN"} {return}
	::dApp::dock_toggle

}

proc ::dApp::dock_toggle {} {
	variable Priv

	if {[wm state .] == "withdrawn"} {
		wm state . normal
	} else {
		wm state . withdrawn
	}
}

proc ::dApp::env_darwin_init {} {
	variable Priv
	
	set style [file join $Priv(appPath) style darwin.tcl]
	if {[file exists $style]} {source $style}
	
}

proc ::dApp::env_linux_init {} {
	variable Priv

	if {$Priv(useTk) && ![catch {package require tktray}] && [lsearch -exact [image names] "dApp.png"] >= 0} {
		set Priv(dock) .dApp_dock

		tktray::icon $Priv(dock) -image dApp.png
		
		bind $Priv(dock) <Enter> [list $Priv(dock) balloon $Priv(title) 1]
		bind $Priv(dock) <Button-1> [list ::dApp::dock_toggle]
		bind . <Unmap> {after idle [list if {[wm state .] == "iconic"} {wm withdraw .}]}
	}
	
	set style [file join $Priv(appPath) style linux.tcl]
	if {[file exists $style]} {source $style}
}

proc ::dApp::env_windows_nt_init {} {
	variable Priv

	set icon [file join $Priv(appPath) "image" "dApp.ico"]
	if {$Priv(useTk) && [catch {package require Winico}] == 0 && [file exists $icon]} {
		set Priv(dock) [winico createfrom $icon]
		winico taskbar add $Priv(dock) \
			-callback [list ::dApp::dock_cb %m] \
			-text $Priv(title)
		bind . <Unmap> {after idle [list if {[wm state .] == "iconic"} {wm withdraw .}]}
	}
	
	if {![catch {package require twapi}]} {
		set dsp [::twapi::get_os_description]
		set ver "xp"
		#Windows Professional 6.1 (Build 7600)
		if {[string first "6.1" $dsp] >= 0} {set ver 7}
		
		if {[string first "Windows Vista" $dsp] >= 0} {set ver vista}
		set style [file join $Priv(appPath) style windows_${ver}.tcl]

		if {[file exists $style]} {source $style}
		package forget twapi
	}
	
}

proc ::dApp::locale_init {} {
	variable Priv

	::msgcat::mclocale $Priv(locale)
	::msgcat::mcload [file join $Priv(appPath) locale]
}

# The main function of your application
proc ::dApp::main {} {
	variable Priv


	button .btn -text [::msgcat::mc "Exit"] -command {::dApp::quit}
	pack .btn 

}

# The quit function of your application
proc ::dApp::quit {} {
	variable Priv

	if {[info exists Priv(dock)]} {catch {winico taskbar delete $Priv(dock)}}

	exit
}

::dApp::boot
