package require tile

namespace eval ::tbar {
	variable Priv
	array set Priv [list \
	rcPath [file join $::dApp::Priv(rcPath) last.txt]
	]
}

proc ::tbar::book_list {{id ""}} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	set imgFind [$ibox get find_start]
	
	set curr [$Priv(btnFind) cget -image]
	
	if {$curr == $imgFind} {
		if {$id != ""} {$Priv(cmbFind) set $id}
		set id [string tolower [$Priv(cmbFind) get]]
		if {$id == ""} {return}
		wm title . [::msgcat::mc "%s - (%s-%s 網路相簿下載程式)" $id $::dApp::Priv(title) $::dApp::Priv(version)]
		
		$Priv(btnFind) configure -image [$ibox get find_stop]
		focus $::abrowser::Priv(tree)
#		update
		switch -exact -- $id {
			"隨機推薦" -
			"人氣相簿" -
			"精選相簿" {
				::abrowser::book_list_start $id
			}
			default {
				set values [list $id]
				foreach item [$Priv(cmbFind) cget -values] {
					if {$item == $id || $item == ""} {continue}
					if {$item == "隨機推薦" || $item == "人氣相簿" || $item == "精選相簿"} {continue}
					lappend values $item
				}
				set values [lrange $values 0 [expr $::dApp::Priv(historyMax) - 1]]
				set fd [open $Priv(rcPath) w]
				puts -nonewline $fd $values
				close $fd
				#$Priv(cmbFind) configure -values [linsert $values end "人氣相簿" "精選相簿" "隨機推薦"]
				$Priv(cmbFind) configure -values $values
				if {[::abrowser::book_list_start $id]} {
					
					#if {$::dApp::Priv(cmdNs) == "wretch" && $::dApp::Priv(videoList) == 1} {::vbrowser::video_list_start $id}
					
				}	
			}		
		}

		$Priv(btnFind) configure -image [$ibox get find_start]
	} else {
		$Priv(btnFind) configure -image [$ibox get find_start]
		::abrowser::book_list_stop
	}
}

proc ::tbar::history_clear {} {
	variable Priv
	file delete $Priv(rcPath)
	$Priv(cmbFind) configure -values "" ;#[list "人氣相簿" "精選相簿" "隨機推薦"]
}

proc ::tbar::init {wpath} {
	variable Priv

	set ibox $::dApp::Priv(ibox)
	
	set tbar [::toolbar::toolbar $wpath -relief groove]	
	$tbar add space -width 5
	set Priv(btnHome) [$tbar add button \
		-tooltip [::msgcat::mc "首頁相簿"] \
		-image [$ibox get home] \
		-command {
			lassign [::abrowser::home_get] type id
			set ::dApp::Priv(cmdNs) $type
			if {$id != ""} {::tbar::book_list $id}
		}]

	set Priv(lblId) [$tbar add label \
		-text [::msgcat::mc "帳號:"] \
		-tooltip [::msgcat::mc "帳號"] \
		]	
		
	set Priv(cmbFind) [$tbar add combobox -width 17 -tooltip [::msgcat::mc "輸入帳號"]]	
	bind $Priv(cmbFind) <Return> {after idle [list ::tbar::book_list]}
	bind $Priv(cmbFind) <<ComboboxSelected>> {after idle [list ::tbar::book_list]}
	
	
	set values [list]
	if {[file exists $Priv(rcPath)]} {
		set fd [open $Priv(rcPath) r]
		foreach item [string trim [read -nonewline $fd]] {
			lappend values $item
		}
		close $fd	
	}
	$Priv(cmbFind) configure -values $values ;#[linsert $values end "人氣相簿" "精選相簿" "隨機推薦"]
		
	set Priv(btnFind) [$tbar add button \
		-tooltip [::msgcat::mc "查看相簿"] \
		-image [$ibox get find_start] \
		-command {::tbar::book_list}]
		
#	set Priv(chkPolicy) [$tbar add checkbutton \
#		-variable ::dApp::Priv(policy) \
#		-onvalue "all" -offvalue "photo" \
#		-text [::msgcat::mc "包含影音"] \
#		-tooltip [::msgcat::mc "包含影音"] \
#		]
		
		#$tbar add space -width 100
		
	set Priv(lblPwd) [$tbar add label \
		-text [::msgcat::mc "儲存位置："] \
		]
	
	set rc [file join $::dApp::Priv(rcPath) pwd.txt]
	if {[file exists $rc]} {
		set fd [open $rc r]
		set data [string trim [read -nonewline $fd]]
		if {[file exists $data]} {set ::dApp::Priv(workspace) $data}
		close $fd
	}
	
	
	set Priv(txtPwd) [$tbar add entry \
		-textvariable ::dApp::Priv(workspace) \
		-tooltip [::msgcat::mc "儲存位置"] \
		]
	
	set Priv(btnPwd) [$tbar add button \
		-tooltip [::msgcat::mc "選擇位置"] \
		-image [$ibox get open] \
		-command {
			set ret [tk_chooseDirectory  -mustexist 1 -title [::msgcat::mc "儲存位置"]]
			if {$ret != ""} {
				set ::dApp::Priv(workspace) $ret
				set rc [file join $::dApp::Priv(rcPath) pwd.txt]
				set fd [open $rc w]
				puts -nonewline $fd $ret
				close $fd
			}
		}]		
		
		pack forget $Priv(lblPwd) $Priv(txtPwd) $Priv(btnPwd)
		pack $Priv(btnPwd) -side right -padx 5
		pack $Priv(txtPwd) -side right -padx 5 -expand 1 -fill x
		pack $Priv(lblPwd) -side right -padx 5
		
	return $wpath
}
