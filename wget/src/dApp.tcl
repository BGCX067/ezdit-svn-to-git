#!/bin/sh
#\
exec wish "$0" ${1+"$@"}

# WGet - Wretch album backup tools. 
# 
# Copyright (C) 2008-2009 Tai, Yuan-Liang

package require msgcat

namespace eval ::dApp {
	variable Priv
	
	array set Priv [list \
		auth "Yuan-Liang ,Tai" \
		appPath "" \
		email "adai1115@yahoo.com.tw" \
		ibox "" \
		title "WGet" \
		date "2009/12/08" \
		version "2.7.6" \
		versionPage "http://got7.org/wget/wget-info.xml" \
		rcPath [file join $::env(HOME) ".wget"] \
		os "" \
		homePage "http://got7.org" \
		versionInfo "" \
		locale [::msgcat::mclocale] \
		workspace "c:/album" \
		license  [::msgcat::mc "在非商業行為的前題下您可以自由的使用本程式。下載相片的同時也請尊重相片的肖相權。"]  \
		defaultAlbum [::msgcat::mc "人氣相簿"] \
		policy "SKIP" \
		videoList 1 \
		includeRaw 1 \
		includeMp3 1 \
		includeVideo 1 \
		downloadUrl "" \
		hotPageMax 5 \
		historyMax 10 \
		delay 0 \
		naming "ID+TITLE" \
		thumbCacheSize 30 \
		cmdNs "wretch" \
	]

	set Priv(msg) $Priv(license)

}

proc ::dApp::init {path} {
	variable Priv

	#<!-- PWD
	set appPath [file normalize [info script]]
	if {[file type $appPath] eq "link"} {set appPath [file readlink $appPath]}
	#-->
	
	# check in starkit
	if {[namespace exists ::vfs]} {

	} 	

	set appPath [file dirname $appPath]
	set Priv(appPath) $appPath	
	
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
	

	set fd [open [file join $appPath version.txt] r]
	set Priv(versionInfo) [read -nonewline $fd]
	close $fd
	
	# Create Resource Directory
	if {![file exists $Priv(rcPath)]} {file mkdir $Priv(rcPath)}

	package require img::png
	package require img::jpeg
	package require img::gif

	package require tooltip
	package require toolbar
	package require ttimgr
	package require ttrc
	
	package require wretch
	package require pchome
	package require pixnet
	package require xuite	

	if {[namespace exists ::vfs]} {
		set pdir [file join [file dirname $appPath] plugins]
		foreach {f} [list wretch pchome pixnet xuite] {
			if {[file exists [file join $pdir $f.tcl]]} {source -encoding utf-8 [file join $pdir $f.tcl]}
		}
	}


	if {[file exists [file join $appPath images]]} {
		set ibox [::ttimgr::create]
		foreach {f} [glob -nocomplain -directory [file join $appPath images] -- *.gif *.png *.jpg] {
			if {[string index [file tail $f] 0] == "."} {continue}
			set name [file rootname [file tail $f]]
			$ibox add $name $f
		}
		set Priv(ibox) $ibox
	}

	switch $os {
		"win32" {
			package require optcl
			set Priv(workspace) "c:/album"
			event add <<MenuPopup>> <ButtonRelease-3>
			set Priv(downloadUrl) "http://got7.org/wget/WGet-win.zip"
		}
		"linux" {
			set Priv(workspace) [file join $::env(HOME) "album"]
			event add <<MenuPopup>> <ButtonRelease-3>
			set Priv(downloadUrl) "http://got7.org/wget/WGet-linux.zip"
		}
		"darwin" {
			event add <<MenuPopup>> <ButtonRelease-2>
			ttk::style configure TNotebook -tabposition nw -padding {1 1}
			set Priv(workspace) [file join $::env(HOME) "album"]
			set Priv(downloadUrl) "http://got7.org/wget/WGet-mac.zip"
		}
	}

	#-->
	
	if {[file exists [file join $appPath mbar.tcl]]} {
		source -encoding utf-8  [file join $appPath mbar.tcl]
		. configure -menu [::mbar::init .mbar]
	}	
	
	if {[file exists [file join $appPath tbar.tcl]]} {
		source -encoding utf-8  [file join $appPath tbar.tcl]
		pack [::tbar::init .tbar] -expand 0 -fill x
	}
	
	source -encoding utf-8  [file join $appPath body.tcl]
	pack [::body::init .body] -expand 1 -fill both


#	source [file join $appPath output.tcl]
#	pack [::output::init .output] -expand 1 -fill x		

	if {[file exists [file join $appPath sbar.tcl]]} {
		source -encoding utf-8  [file join $appPath sbar.tcl]
		pack [::sbar::init .sbar] -expand 0 -fill x -padx 2 -pady 2
	}
	
	source -encoding utf-8  [file join $appPath about.tcl]

	set plugins [glob -nocomplain -directory  [file join $Priv(appPath) plugins] *.tcl]
	foreach p $plugins {source -encoding utf-8  $p}

	wm title . [::msgcat::mc "WGet-%s (網路相簿下載程式)" $Priv(version)]
	wm protocol . WM_DELETE_WINDOW ::dApp::quit

	::sbar::cmd_put $Priv(license) 15000

	::dApp::check_update
	::dApp::rc_load
	::mbar::proxy_load
}

proc ::dApp::check_update {} {
	variable Priv
		
	set code 403
	set ver 0

	catch {
			set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7"]
			set tok [http::geturl $::dApp::Priv(versionPage) -timeout 5000 -type "text/plain" -headers $headers]
			#set data [string trim [http::data $tok]]
			set data [encoding convertfrom utf-8 [string trim [http::data $tok]]]
			set s [http::status $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
	}
	
	
	if {$code != 200} {return}

	set doc [dom parse $data]
	set root [$doc documentElement ]
	set infoNode [$root selectNodes "/wget/info" ]
	set ver [$infoNode getAttribute version]
	set url [$infoNode getAttribute url]
	if {$ver > $::dApp::Priv(version)} {
		set changesNode [$root selectNodes "/wget/changes" ]
		set changes [::msgcat::mc "版本 %s 修改事項 :" $ver]
		append changes "\n"
		foreach  node [$changesNode childNodes] {append changes "   -" [$node text] "\n"}
	}
	
	
	if {$ver <= $::dApp::Priv(version)} {return}
	
	::output::put_msg [::msgcat::mc "☆ 已經有較新版本的%s可以使用" $::dApp::Priv(title)] "\n\n"
	::output::put_msg $changes 
	
	return
}

proc ::dApp::download {} {
	variable Priv
	
	set dir [tk_chooseDirectory -title [::msgcat::mc "請選擇儲存位置" ] -mustexist 1 ]
	if {$dir == "" || ![file exists $dir]} {return}
	
	set url $Priv(downloadUrl)
	set fname [file tail $url]
	
	::output::put_msg [::msgcat::mc "正在下載 -> %s ..." $fname] ""
	
	set tok [http::geturl $Priv(downloadUrl) \
		-binary 1 \
		-blocksize 4096 \
		-progress {::dApp::download_cb}]

	set ret 0
	foreach {pocl code state} [string tolower [http::code $tok]] {}
	
	if {$code == 200 && $state == "ok"} {
		set fd [open [file join $dir $fname] w]
		fconfigure $fd -translation binary
		puts $fd [http::data $tok]	
		close $fd
		set ret 1
		::output::put_msg [::msgcat::mc "完成!!"]
	} else {
		::output::put_msg [::msgcat::mc "失敗!!"]
	}
	http::cleanup $tok	
}

proc ::dApp::download_cb {tok max val} {
	upvar #0 $tok state
	::sbar::cmd_pbar_set $max $val
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

proc ::dApp::quit {} {
	foreach fd [chan names] {
		catch {chan close $fd}
	}
	exit
}

proc ::dApp::rc_load {} {
	variable Priv
	set rcfile [file join $Priv(rcPath) "wget.xml"]
	if {![file exists $rcfile]} {return}
	
	set tok [::ttrc::openrc $rcfile]
	set sess [$tok session_select "settings"]
	foreach key [list cmdNs naming delay videoList policy includeRaw includeMp3 includeVideo hotPageMax historyMax thumbCacheSize] {
		set val [$tok attr_get $sess $key]
		if {$val != ""} {set Priv($key) $val}
	}
	$tok close	
	
}

proc ::dApp::rc_save {} {
	variable Priv
	set rcfile [file join $Priv(rcPath) "wget.xml"]
	
	set tok [::ttrc::openrc $rcfile]
	set sess [$tok session_add "settings"]
	foreach key [list cmdNs naming delay videoList policy includeRaw includeMp3 includeVideo hotPageMax historyMax thumbCacheSize] {
		$tok attr_set $sess $key $Priv($key)
	}	
	$tok close
}


::dApp::init ""

