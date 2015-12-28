namespace eval ::dApp {
	
	variable Priv
	array set Priv [list \
		appPath "" \
		ibox "" \
		title "" \
		version 1.0 \
		rcPath [file join $::env(HOME) ".dApp" "CrowFM"] \
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
	
	# check in starkit
	if {[namespace exists ::starkit]} {
		set appPath [file dirname $::starkit::topdir]
	}	
	
	#<!-- Setup ::auto_path
	lappend ::auto_path [file join $appPath "lib"]
	set platformLib [file join $appPath "lib_$::tcl_platform(platform)"]
	set ::auto_path [linsert $::auto_path 0 [file join $appPath "lib"]]
	if {[file exists $platformLib]} {lappend ::auto_path $platformLib}
	#-->

	switch $::tcl_platform(platform) {
		"windows" {
			package require twapi
		}
		"unix" {

		}
	}

	if {[file exists [file join $appPath "locale"]]} {
		::msgcat::mcload [file join $appPath "locale"]
	}
	# Create Resource Directory

	if {![file exists $Priv(rcPath)]} {file mkdir $Priv(rcPath)}

	package require msgcat
	package require libCrowFM
	package require toolbar
	package require imgBox
	package require img::png
	package require treectrl
	package require BWidget
	package require tile
	
	set ibox [::imgBox::create]
	set imagePath [file join $appPath images]
	set fd [open [file join $imagePath default.theme] r]
	while {![eof $fd]} {
		gets $fd buf
		set data [split $buf "="]
		if {[llength $data] != 2} {continue}
		foreach {key val} $data {break}
		$ibox add [string trim $key] [subst [string trim $val]]
	}
	close $fd

	set Priv(ibox) $ibox

	ttk::style theme use "clam"
	
	source [file join $appPath mbar.tcl]
	source [file join $appPath tbar.tcl]
	source [file join $appPath lframe.tcl]
	source [file join $appPath rframe.tcl]
	source [file join $appPath sbar.tcl]
	
	set body [::ttk::frame .body]
	set lrframe [::ttk::paned $body.lrframe -orient "horizontal"]
	$lrframe add [::lframe::init $lrframe.l] 
	$lrframe add [::rframe::init $lrframe.r] -weight 1	
	pack $lrframe -expand 1 -fill both -padx 2 -pady 2
	
	. configure -menu [::mbar::init .mbar]
	pack [::tbar::init .tbar] -expand 0 -fill x -padx 2
	pack $body -expand 1 -fill both 
	pack [::sbar::init .sbar] -expand 0 -fill x

	wm protocol . WM_DELETE_WINDOW ::dApp::destroy
#	update
	wm geometry . 600x400
}

proc ::dApp::destroy {} {
	exit
}

::dApp::init
