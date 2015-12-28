package require ttdialog
package require http
namespace eval ::about {
	variable Priv
	array set Priv [list]
}

proc ::about::check {txt} {
	
	$txt delete 1.0 end
	$txt insert end [::msgcat::mc "檢查可用的更新..."]
	$txt insert end "\n\n"
	update
	
	set code 403
	set ver 0
	set changes [::msgcat::mc "目前沒有可用的更新"]

	catch {
			set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7"]
			set tok [http::geturl $::dApp::Priv(versionPage) -timeout 5000 -type "text/plain" -headers $headers]
			set data [encoding convertfrom utf-8 [string trim [http::data $tok]]]
			#set data  [string trim [http::data $tok]]
			set s [http::status $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
	}
	
	
	if {$code != 200} {
		$txt insert end [::msgcat::mc "連接更新伺服器失敗"]
		return
	}

	set doc [dom parse $data]
	set root [$doc documentElement ]
	set infoNode [$root selectNodes "/wget/info" ]
	set ver [$infoNode getAttribute version]
	set url [$infoNode getAttribute url]
	if {$ver > $::dApp::Priv(version)} {
		set changesNode [$root selectNodes "/wget/changes" ]
		set changes [::msgcat::mc "版本 %s 修改事項 :" $ver]
		append changes "\n\n"
		foreach  node [$changesNode childNodes] {append changes "   -" [$node text] "\n\n"}
	}
	
	
	if {$ver <= $::dApp::Priv(version)} {
		$txt insert end [::msgcat::mc "目前沒有可用的更新"]
		return
	}
	
	$txt insert end [::msgcat::mc "已經有較新版本的%s可以使用" $::dApp::Priv(title)]
	$txt insert end "\n\n"
	
	$txt insert end $changes 
	$txt insert end "\n"
	$txt insert end [::msgcat::mc "下載最後版本的%s" $::dApp::Priv(title)] download	

	$txt tag configure download -foreground blue -underline 1
	$txt tag bind download <ButtonPress> [list ::dApp::openurl $url]
	$txt tag bind download <Enter> [list $txt configure -cursor "hand2"]
	$txt tag bind download <Leave> [list $txt configure -cursor ""]	
	
	return
	
}

proc ::about::check_update {} {
	variable Priv

	set win ._dapp_update
	if {[winfo exists $win]} {
		raise $win
		return
	}	
	set win [::ttdialog::dialog $win \
		-title [::msgcat::mc "%s 更新" $::dApp::Priv(title)] \
		-default "" \
		-buttons "" \
	]	
	set fme [::ttdialog::clientframe $win]
	$fme configure -padding 3	
	set lbl [::ttk::label $fme.lbl -text [::msgcat::mc "訊息:"]]
	set txt [text $fme.txt -bd 1 -relief groove -highlightthickness 0 -takefocus 0 -width 60 -height 15]
	set vs [ttk::scrollbar $fme.vs -command [list $txt yview] -orient vertical]
	$txt configure -yscrollcommand [list $vs set]
	::autoscroll::autoscroll $vs
	set fmeBtn [::ttk::frame $fme.fmeBtn]

	set btnCheck [::ttk::button $fmeBtn.btnCheck -text [::msgcat::mc "檢查"] -command [list ::about::check $txt]]
	set btnClose [::ttk::button $fmeBtn.btnClose -text [::msgcat::mc "關閉"] -command [list destroy $win]]

	pack $btnClose $btnCheck -side right -padx 5 -pady 3

	grid $lbl - -sticky "news" -pady 3 
	grid $txt $vs -sticky "news"  -pady 3 
	grid $fmeBtn -  -sticky "news" -pady 3 
	grid rowconfigure $fme 1 -weight 1
	grid columnconfigure $fme 0 -weight 1	
	after idle [list $btnCheck invoke]
	::ttdialog::dialog_wait $win
	catch {destroy $win}
}

proc ::about::show {} {
	variable Priv
	set ibox $::dApp::Priv(ibox)
	set win ._dapp_about
	if {[winfo exists $win]} {
		raise $win
		return
	}
	set win [::ttdialog::dialog $win \
		-title [::msgcat::mc "關於 %s" $::dApp::Priv(title)] \
		-default "" \
		-buttons "" \
	]
	
	set fontVersion [font create  -weight bold]
	set fontDate [font create ]
	set fontTitle [font create  ]
	set fontName [font create ]
	set fontEmail [font create ]
	
	set fme [::ttdialog::clientframe $win]
	set fmeLeft [ttk::frame $fme.fmeLeft]
	set fmeRight [ttk::frame $fme.fmeRight -padding 20]
	pack $fmeLeft  -side left -expand 0 -fill both
	pack $fmeRight -side left -expand 1 -fill both
	set lblIcon [ttk::label $fmeLeft.lblIcon -compound "left" -image [$ibox get logo] -anchor "center" -anchor s]
	set lblVer [ttk::label $fmeLeft.lblVer -text "$::dApp::Priv(title) v$::dApp::Priv(version)" -anchor "center" -font $fontVersion]
	set lblDate [ttk::label $fmeLeft.lblDate -text "$::dApp::Priv(date)" -anchor "center" -font $fontDate]
	set btnHome [ttk::button $fmeLeft.btnHome \
		-text [::msgcat::mc "參觀網站"] \
		-command {::dApp::openurl $::dApp::Priv(homePage)}]
	set btnClose [ttk::button $fmeLeft.btnClose -text [::msgcat::mc "關閉"] -command [list destroy $win]]
	pack $lblIcon -expand 1 -fill both -side top -padx 30 -pady 10
	pack $lblVer -fill x -side top -pady 6
	pack $lblDate -fill x -side top -pady 1
	pack $btnHome -side top -pady 6 -fill x -padx 15
	pack $btnClose -side top -pady 6 -fill x -padx 15
	
	set txt [text $fmeRight.txt -bd 1 -relief groove -highlightthickness 0 -takefocus 0 -width 45 -height 15]
	set lblCp [ttk::label $fmeRight.lblCp \
		-text [::msgcat::mc "Copyright (C) 2009 Yuan-Liang ,Tai"] \
		-anchor "center" \
		-font $fontDate]
	set vs [ttk::scrollbar $fmeRight.vs -command [list $txt yview] -orient vertical]
	::autoscroll::autoscroll $vs
	$txt configure -yscrollcommand [list $vs set]	
	
	grid $txt $vs -sticky "news"
	grid $lblCp -  -sticky "news"
	grid rowconfigure $fmeRight 0 -weight 1
	grid columnconfigure $fmeRight 0 -weight 1
	
	$txt insert end "作者：dai\n" title
	$txt insert end "我的網站：$::dApp::Priv(homePage)\n" title
	$txt insert end "電子郵件：adai1115@yahoo.com.tw\n" title
	$txt insert end "* wretch或pchome的錯誤請回報給我\n\n" title
	
	$txt insert end "作者：laby\n" title
	$txt insert end "電子郵件：laby0916@gmail.com\n" title
	$txt insert end "* xuite或pixnet的錯誤請回報給我\n\n" title
	
	$txt insert end "軟體授權：在非商業行為的前題下您可以自由的使用本程式。\n"  title

	
	set fd [open [file join $dApp::Priv(appPath) version.txt] r]
	chan configure $fd -encoding utf-8
	$txt insert end [read $fd] name
	close $fd

	
	$txt tag configure title -font $fontTitle -foreground blue
	$txt tag configure name -font $fontName
	$txt tag configure mail -font $fontEmail -foreground blue
	#$txt configure -state disabled
	
	::ttdialog::dialog_wait $win
	foreach f [list $fontVersion $fontDate $fontTitle $fontName $fontEmail] {
		font delete $f
	}

}
