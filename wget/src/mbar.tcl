package require http

namespace eval ::mbar {
	variable Priv
	array set Priv [list \
	]
}

proc ::mbar::init {wpath} {
	variable Priv
	set mbar [menu $wpath -type menubar]
	
	$mbar add cascade  -label [::msgcat::mc "檔案"] -menu [::mbar::menu_file_init $mbar.file]
	$mbar add cascade  -label [::msgcat::mc "選項"] -menu [::mbar::menu_option_init $mbar.option]
	$mbar add cascade  -label [::msgcat::mc "說明"] -menu [::mbar::menu_help_init $mbar.about]
	
	return $wpath
}

proc ::mbar::menu_file_init {wpath} {
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set m $wpath
	menu $m -tearoff 0 -postcommand ::mbar::menu_file_post
	
	set  m2 [menu $m.fsub -tearoff 0]
	$m2 add command \
		-compound left 	\
		-image [$ibox get empty] \
		-label  [::msgcat::mc "首頁"] \
		-command [list ::dApp::openurl "http://www.wretch.cc"]
		
	$m2 add command \
		-compound left 	\
		-image [$ibox get empty] \
		-label  [::msgcat::mc "精選網誌"] \
		-command [list ::dApp::openurl "http://www.wretch.cc/blog/?tab=hot"]
		
	$m2 add command \
		-compound left 	\
		-image [$ibox get empty] \
		-label  [::msgcat::mc "精選相簿"] \
		-command [list ::dApp::openurl "http://www.wretch.cc/album/?func=hot&hid=4"]
		
	$m2 add command \
		-compound left 	\
		-image [$ibox get empty] \
		-label  [::msgcat::mc "精選影音"] \
		-command [list ::dApp::openurl "http://www.wretch.cc/video/index.php?func=hot&hid=2"]
		
	$m add cascade \
		-label [::msgcat::mc "參觀無名小站"] \
		-compound left 	\
		-image [$ibox get empty] \
		-menu $m2
	
	
	set  m2 [menu $m.pchomesub -tearoff 0]
	
	$m add cascade \
		-label [::msgcat::mc "參觀PChome"] \
		-compound left 	\
		-image [$ibox get empty] \
		-menu $m2
		
	$m2 add command \
		-compound left 	\
		-image [$ibox get empty] \
		-label  [::msgcat::mc "首頁"] \
		-command [list ::dApp::openurl "http://photo.pchome.com.tw/"]
		
	$m2 add command \
		-compound left 	\
		-image [$ibox get empty] \
		-label  [::msgcat::mc "人氣相簿"] \
		-command [list ::dApp::openurl "http://photo.pchome.com.tw/album_pv.html"]		
	
#	$m add separator			
	
	$m add command \
		-label [::msgcat::mc "代理伺服器設定..."] \
		-compound left \
		-image [$ibox get empty] \
		-command {::mbar::proxy_conf}	
	
	$m add separator	
	
	$m add command \
		-label [::msgcat::mc "離開"] \
		-compound left \
		-image [$ibox get emtpy] \
		-command {exit}	
	
	set Priv(file) $m
	
}

proc ::mbar::menu_file_post {} {
	variable Priv
	set m $Priv(file)	
}

proc ::mbar::menu_help_init { wpath} {	
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set m $wpath
	menu $m -tearoff 0 -postcommand ::mbar::menu_help_post
	set Priv(help) $m
	
	$m add command \
		-label [::msgcat::mc "參觀網站..." $::dApp::Priv(title)] \
		-compound left \
		-image [$ibox get empty] \
		-command [list ::dApp::openurl $::dApp::Priv(homePage)]	
	
	$m add command \
		-label [::msgcat::mc "檢查更新項目..."] \
		-compound left \
		-image [$ibox get empty] \
		-command {::about::check_update}	
	$m add separator	
	$m add command \
		-label [::msgcat::mc "關於..."] \
		-compound left \
		-image [$ibox get empty] \
		-command {::about::show}
	return $m
}

proc ::mbar::menu_help_post {} {	
	variable Priv
	set m $Priv(help)

}


proc ::mbar::menu_option_init { wpath} {	
	variable Priv
	
	set ibox $::dApp::Priv(ibox)
	
	set m $wpath
	menu $m -tearoff 0 -postcommand ::mbar::menu_option_post
	set Priv(option) $m
	set Priv(option,mDownload) [menu $m.mDownload -tearoff 0]
	set Priv(option,mHotMax) [menu $m.mHotMax -tearoff 0]
	set Priv(option,mHistoryMax) [menu $m.mHistoryMax -tearoff 0]
	set Priv(option,mCacheSize) [menu $m.mCacheSize -tearoff 0]
	set Priv(option,mDelay) [menu $m.mDelay -tearoff 0]
	set Priv(option,mNaming) [menu $m.mNaming -tearoff 0]
	set Priv(option,mService) [menu $m.mService -tearoff 0]
	
	$m add cascade \
	-label [::msgcat::mc "相簿類型"] \
	-compound left \
	-image [$ibox get empty] \
	-menu $Priv(option,mService)

	$Priv(option,mService) add radiobutton \
		-label [::msgcat::mc "Wretch 相簿"] \
		-value "wretch" \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(cmdNs) \
		-command {::dApp::rc_save}
	$Priv(option,mService) add radiobutton \
		-label [::msgcat::mc "PChome 相簿"] \
		-value "pchome" \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(cmdNs) \
		-command {::dApp::rc_save}	
	$Priv(option,mService) add radiobutton \
		-label [::msgcat::mc "Pixnet 相簿"] \
		-value "pixnet" \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(cmdNs) \
		-command {::dApp::rc_save}
	$Priv(option,mService) add radiobutton \
		-label [::msgcat::mc "Xuite 相簿"] \
		-value "xuite" \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(cmdNs) \
		-command {::dApp::rc_save}			
	$m add separator	
		

	
	$m add cascade \
		-menu $Priv(option,mDownload) \
		-label [::msgcat::mc "下載相簿"] \
		-compound left \
		-image [$ibox get empty] \
		-command {::dApp::rc_save}
		
	$Priv(option,mDownload) add checkbutton \
		-label [::msgcat::mc "原圖優先"] \
		-onvalue 1 \
		-offvalue 0 \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(includeRaw) \
		-command {::dApp::rc_save}
#	$Priv(option,mDownload) add checkbutton \
#		-label [::msgcat::mc "包含MP3"] \
#		-onvalue 1 \
#		-offvalue 0 \
#		-compound left \
#		-image [$ibox get empty2] \
#		-variable ::dApp::Priv(includeMp3) \
#		-command {::dApp::rc_save}
#	$Priv(option,mDownload) add checkbutton \
#		-label [::msgcat::mc "包含影音"] \
#		-onvalue 1 \
#		-offvalue 0 \
#		-compound left \
#		-image [$ibox get empty2] \
#		-variable ::dApp::Priv(includeVideo) \
#		-command {::dApp::rc_save}
		
		$m add cascade \
		-label [::msgcat::mc "預設相簿搜尋"] \
		-compound left \
		-image [$ibox get empty] \
		-menu $Priv(option,mHotMax)
		
		foreach p [list 3 5 10 20] {
			$Priv(option,mHotMax) add radiobutton \
				-label [::msgcat::mc "%s 頁" $p] \
				-value $p \
				-compound left \
				-image [$ibox get empty2] \
				-variable ::dApp::Priv(hotPageMax) \
				-command {::dApp::rc_save}
		}
	
		$m add cascade \
		-label [::msgcat::mc "歷史清單"] \
		-compound left \
		-image [$ibox get empty] \
		-menu $Priv(option,mHistoryMax)
		foreach p [list 5 10 15 20 30 50] {
			$Priv(option,mHistoryMax) add radiobutton \
				-label [::msgcat::mc "%s 筆" $p] \
				-value $p \
				-compound left \
				-image [$ibox get empty2] \
				-variable ::dApp::Priv(historyMax) \
				-command {::dApp::rc_save}
		}
		$Priv(option,mHistoryMax) add separator
		$Priv(option,mHistoryMax) add command \
			-compound left \
			-image [$ibox get empty] \
			-label [::msgcat::mc "清除"] \
			-command {
				::tbar::history_clear
				tk_messageBox -title [::msgcat::mc "訊息"] \
					-message  [::msgcat::mc "清理完成"] \
					-type ok \
					-icon info					
			}
		
		$m add cascade \
			-label [::msgcat::mc "封面快取"] \
			-image [$ibox get empty] \
			-compound left \
			-menu $Priv(option,mCacheSize)
		foreach p [list 10 30 50 100 300 500 1000] {
			$Priv(option,mCacheSize) add radiobutton \
				-label [::msgcat::mc "%s 個帳號" $p] \
				-value $p \
				-compound left \
				-image [$ibox get empty2] \
				-variable ::dApp::Priv(thumbCacheSize) \
				-command {::dApp::rc_save}
		}
		$Priv(option,mCacheSize) add separator
		$Priv(option,mCacheSize) add command \
			-compound left \
			-image [$ibox get empty] \
			-label [::msgcat::mc "清除"] \
			-command {
				if {$::abrowser::Priv(runStart)} {
					tk_messageBox -title [::msgcat::mc "錯誤"] \
						-message  [::msgcat::mc "其它的下載工作正在執行，請先停止它們"] \
						-type ok \
						-icon error
				} else {
					set cacheDir $::abrowser::Priv(cacheDir)
					foreach dir [glob -nocomplain -directory $cacheDir -types {d} *] {
						file delete -force $dir
					}
					tk_messageBox -title [::msgcat::mc "訊息"] \
						-message  [::msgcat::mc "清理完成"] \
						-type ok \
						-icon info	
				}
			}
			
		$m add cascade \
			-label [::msgcat::mc "抓取間隔"] \
			-image [$ibox get empty] \
			-compound left \
			-menu $Priv(option,mDelay)
		foreach t [list 0 1 2 3 4 5 10] {
			$Priv(option,mDelay) add radiobutton \
				-label [::msgcat::mc "%s 秒" $t] \
				-value [expr $t*1000] \
				-compound left \
				-image [$ibox get empty2] \
				-variable ::dApp::Priv(delay) \
				-command {::dApp::rc_save}
		}			
	
	$m add separator	
		
	$m add cascade \
	-label [::msgcat::mc "命名規則"] \
	-compound left \
	-image [$ibox get empty] \
	-menu $Priv(option,mNaming)
	
	$Priv(option,mNaming) add radiobutton \
		-label [::msgcat::mc "項目ID"] \
		-value "ID" \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(naming) \
		-command {::dApp::rc_save}
	$Priv(option,mNaming) add radiobutton \
		-label [::msgcat::mc "項目ID + 標題"] \
		-value "ID+TITLE" \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(naming) \
		-command {::dApp::rc_save}					
		
	$m add checkbutton \
		-label [::msgcat::mc "跳過已下載的項目"] \
		-onvalue "SKIP" \
		-offvalue "REPLACE" \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(policy) \
		-command {::dApp::rc_save}

	$m add checkbutton \
		-label [::msgcat::mc "找出影音清單"] \
		-onvalue "1" \
		-offvalue "0" \
		-compound left \
		-image [$ibox get empty2] \
		-variable ::dApp::Priv(videoList) \
		-command {::dApp::rc_save}			
	
	return $m
}

proc ::mbar::menu_option_post {} {	
	variable Priv
	set m $Priv(help)

}


proc ::mbar::proxy_conf {} {
	set win ._dialog_2
	catch {destroy $win}
	set win [::ttdialog::dialog $win \
		-title [::msgcat::mc "代理伺服器設定"] \
		-buttons [list  "儲存設定" "save" "忘記設定" "disable"  "離開" "cancel"] \
	]
	set fme [::ttdialog::clientframe $win]
	
	set rc [file join $::dApp::Priv(rcPath) "proxy.txt"]
	set ::mbar::proxyHost ""
	set ::mbar::proxyPort 3128
	if {[file exists $rc]} {
		set fd [open $rc r]
		set data [string trim [read -nonewline $fd]]
		close $fd
		lassign [split $data ":"] ::mbar::proxyHost ::mbar::proxyPort
	}
	
	set lblHost [ttk::label $fme.lblHost -text [::msgcat::mc "Proxy主機: "] -anchor w -justify left]
	set txtHost [ttk::entry $fme.txtHost -textvariable ::mbar::proxyHost -width 16]
	set lblPort [ttk::label $fme.lblPort -text [::msgcat::mc "通訊埠 : "] -anchor w -justify left]
	set txtPort [ttk::entry $fme.txtPort -textvariable ::mbar::proxyPort -width 6]
	pack $lblHost $txtHost $lblPort $txtPort -side left -expand 1 -fill both -padx 2 -pady 3
	
	set ret [::ttdialog::dialog_wait $win]
	if {$ret == "save"} {
		set fd [open $rc w]
		puts -nonewline $fd $::mbar::proxyHost
		puts -nonewline $fd ":"
		puts -nonewline $fd $::mbar::proxyPort
		close $fd
		http::config -proxyhost $::mbar::proxyHost -proxyport $::mbar::proxyPort
	}
	if {$ret == "disable"} {
		if {[file exists $rc]} {file delete $rc}
		http::config -proxyhost "" -proxyport ""
	}								
}

proc ::mbar::proxy_load {} {
	set rc [file join $::dApp::Priv(rcPath) "proxy.txt"]
	set ::mbar::proxyHost ""
	set ::mbar::proxyPort 3128
	
	if {[file exists $rc]} {
		set fd [open $rc r]
		set data [string trim [read -nonewline $fd]]
		close $fd
		lassign [split $data ":"] proxyHost proxyPort
		catch {::http::config -proxyhost $proxyHost -proxyport $proxyPort}
	}		
}

