package provide xuite 1.0
package require http
package require tdom

namespace eval ::xuite {
	variable Priv
	array set Priv [list \
		timeout 15000 \
		retry 5 \
		albumUrl "photo.xuite.net" \
		debug 0 \
	]

	http::config -useragent {Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-TW; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12}
}

#ok
proc ::xuite::book_page_count {id {cb ::xuite::pic_get_cb} {p 1}}  {
	variable Priv

	set id [string tolower $id]	
	set url "http://$Priv(albumUrl)/$id"
	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3"]

	catch {
		set code 403
		set tok [http::geturl $url -headers $headers -timeout  $Priv(timeout)]
		set data [http::data $tok]
		set code [http::ncode $tok]
		http::cleanup $tok
	}

	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "Xuite現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return 0		
	}

	if {$code != 200} {return 0}

	set idx0 [string first "目前沒有相簿" $data]
	if {$idx0 != "-1"} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "無此相簿或沒有公開"]\
			-type ok \
			-icon info
		return 0		
	}

	set idx1 [string first "nav-last" $data] 

	if { $idx1 == "-1"} {
		return 1
	} else {
		set idx2 [string first "*" $data $idx1]
		set idx3 [string first "\"" $data $idx2]
		return [string range $data [expr $idx2 + 1] [expr $idx3 -1]]
	}
}

#ok
proc ::xuite::book_page_list {id page {cb ::wretch::pic_get_cb}} {
	variable Priv

	set id [string tolower $id]
	
	set url "http://$Priv(albumUrl)/$id*$page"	
	
	if {$page == 1} {
		set url "http://$Priv(albumUrl)/$id"		
	} 

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7"]
	catch {
		set code 403		
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout)]
		set data [http::data $tok]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code != 200} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "Xuite現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	
#	set idx1 [string first {<div class="list_area">} $data]
#	set idx2 [string last {<p class="album_info_date">} $data]
#	set idx3 [string first "</div>" $data $idx2]
#	set idx3 [string first "</div>" $data [expr $idx3 + 1]]
#	set data [string range $data [expr $idx1 +24] [expr $idx3 + 6]]		

	set idx1 [string first {<div class="list_area">} $data]
	set idx2 [string first {<div align="center" class="page">} $data]
	if { $idx2 == -1 } {
		set idx2 [string first {<div id="footer">} $data]
	}
	set idx3 [string last "</div>" $data $idx2]
	set idx3 [string last "</div>" $data $idx3]	
	set data [string range $data [expr $idx1 +24] [expr $idx3 + 5]]	

	set doc [dom parse -html "<div>$data</div>"]
	set root [$doc documentElement]

	set ret ""
	foreach album [$root childNodes]	{
		set tmp [[$album selectNodes {./div/a}] getAttribute href]
		set idx1 [string last "/" $tmp]
		set book [string range $tmp [expr $idx1 + 1] end]
		set title [string trim [[$album selectNodes {./div/p/a}] text]]
		set num [string range [string trim [[$album find "class" "album_info_date"] text]] 10 end]
		set thumb [[$album selectNode {./div/a/img}] getAttribute src]
		set key 0
		set new 0

		if { [[$album find "class" "album_info_title"] selectNodes {./img}] ne ""} {
			set key 1
		}
		if { [$album find "class" "new_album"] ne "" } {
			set new 1
		}
		regsub -all {\.}  $title "_" title
		lappend ret [list $id $book $title $num $thumb $new $key]
	}
	$doc delete
	return $ret
}

proc ::xuite::hot_page_list {type page {cb ::xuite::pic_get_cb}} {
	variable Priv

	set url "http://www.pixnet.net/alb/0/$type"
	set ret ""
	
	set i 1
	while { $i <= $page } {
		set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
		catch {
			set code 403	
			set tok [http::geturl "$url/$page" -headers $headers -timeout $Priv(timeout) -progress $cb]
			set data [http::data $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
		}
		if {$code == 999} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "Xuite現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
				-type ok \
				-icon info
			return ""
		}	
		if {$code != 200} {return ""}
		
		set idx1 [string first {<div class="innertext" id="album_rank">} $data]
		set idx2 [string first {<!--innertext-->} $data $idx1]
		set data [string range $data $idx1 [incr idx2 -1]]

		set doc [dom parse -html $data]
		set root [$doc documentElement]
		foreach album [$root selectNode {./div/div/div/a}]	{
			set book [$album getAttribute href]
			set id [string range $book 7 [expr [string first "." $book ] - 1]]
			set book [lindex [split $book "/"] end]
			set title [encoding convertfrom utf-8 [$album getAttribute title]]
			set thumb [[$album selectNode {./img}] getAttribute src]
			regsub -all {\.}  $title "_" title
			lappend ret [list $id $book $title "" $thumb 0 0]
		}
		
		$doc delete
		incr i
	}
	return $ret
}

proc ::xuite::debug {msg} {
	variable Priv
	if {$Priv(debug)} {puts $msg}
}

proc ::xuite::friend_list {id {cb ::wretch::pic_get_cb}} {
	return ""
}

#get thumb
proc ::xuite::pic_get {url fpath {cb ::xuite::pic_get_cb}} {

	set uid [lindex [split $url "/"] 7]
	set ref "http://photo.xuite.net/$uid"

	lappend headers \
		Keep-Alive 300 \
		Connection keep-alive \
		Referer $ref \
		Accept-Language "zh-tw;q=0.7,en;q=0.3" \
		Accept-Charset "utf-8;q=0.7,*;q=0.7" 

	if {[catch {
		set code 403
		set tok [http::geturl $url \
			-headers $headers \
			-binary 1 \
			-blocksize 4096 \
			-progress $cb]
		set code [http::ncode $tok]
	}]} {	return "" 	}
	

	if {$code != 200} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "Xuite現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		http::cleanup $tok
		return ""
	}		

	set fd [open $fpath w]
	fconfigure $fd -translation binary
	puts -nonewline $fd [http::data $tok]	
	close $fd

	http::cleanup $tok

	return $fpath
}

#get full pic
proc ::xuite::pic_get_full {purl fpath {cb ::xuite::pic_get_cb}} {

#get cookie

	set hdr ""
	lappend hdr \
		Accept-Language "zh-tw;q=0.7,en;q=0.3" \
		Accept-Charset "utf-8;q=0.7,*;q=0.7"
		
	if {[catch {
		set tok [http::geturl $purl -headers $hdr ]
		set data [http::data $tok]
		upvar \#0 $tok state
		set meta $state(meta)
		http::cleanup $tok
	}]} {set data "" ; return}

	set idx1 [string first {<div id="photo">} $data]
	set idx1 [string first {http://} $data $idx1]
	if {$idx1 == -1} {return ""}
	set idx2 [string first "\"" $data $idx1]
	set furl [string range $data $idx1 [expr $idx2 -1]]
	
	set cookie ""
	foreach {name value} $meta {
		if {$name eq "Set-Cookie"} {
			lappend cookie [lindex [split $value {;}] 0]
		}
	}
	set cookie [join $cookie ";"]

	lappend headers \
		Keep-Alive 300 \
		Connection keep-alive \
		Referer $purl \
		Accept-Language "zh-tw;q=0.7,en;q=0.3" \
		Accept-Charset "utf-8;q=0.7,*;q=0.7" \
		Cookie $cookie

	if {[catch {
		set code 403
		set tok [http::geturl $furl \
			-headers $headers \
			-binary 1 \
			-blocksize 4096 \
			-progress $cb]
		set code [http::ncode $tok]
	}]} {	return "" 	}
	
	if {$code != 200} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "Xuite現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		http::cleanup $tok
		return ""
	}		

	set fd [open $fpath w]
	fconfigure $fd -translation binary
	puts -nonewline $fd [http::data $tok]	
	close $fd

	http::cleanup $tok

	return $fpath
}

proc ::xuite::pic_check_login {url html passwd} {
	variable Priv

	upvar $html data
	set post [http::formatQuery text "" pwd $passwd ab_id ""]
	set purl "http://photo.xuite.net/@restrict?furl=$url"
	lappend hdr \
		Keep-Alive 300 \
		Connection keep-alive \
		Referer $url \
		Accept-Language "zh-tw;q=0.7,en;q=0.3" \
		Accept-Charset "utf-8;q=0.7,*;q=0.7" 

	set tok [http::geturl $purl -headers $hdr -query $post]
		
	upvar \#0 $tok state
	set meta $state(meta)
	set cookie ""
	foreach {name value} $meta {
		if {$name eq "Set-Cookie"} {
			lappend cookie [lindex [split $value {;}] 0]
		}
	}
	set cookie [join $cookie ";"]

	set hdr ""
	lappend hdr \
		Keep-Alive 300 \
		Connection keep-alive \
		Referer $url \
		Accept-Language "zh-tw;q=0.7,en;q=0.3" \
		Accept-Charset "utf-8;q=0.7,*;q=0.7" \
		Cookie $cookie
		
	set tok [http::geturl $url -headers $hdr]
	
	set data [http::data $tok]
	if {[string first "photo_item" $data] > 0} { 
		return}
	set data ""
}

proc ::xuite::pic_get_cb {tok total current} {
	upvar #0 $tok state
	#puts "$total $current"
	return
}
#
#
proc ::xuite::pic_page_count {id book {passwd ""} {cb ::xuite::pic_get_cb} {p 1}} {
	variable Priv
	
	set id [string tolower $id]
	
	set url "http://$Priv(albumUrl)/$id/$book"
	
	if {$passwd != ""} {
		::xuite::pic_check_login $url data $passwd
		if {$data == "" || [string first [string tolower $id] $data] <0} {return 0}
	} else {
		set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
		catch {
			set code 403
			set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
			set data [http::data $tok]
			set s [http::status $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
		}
		if {$code == 999} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "Xuite現在不允許您的連線，請稍後再試或使用代理伺服器。"] \
				-type ok \
				-icon info
			return 0
		}	
		if {$code != 200} {return 0}	
	}
	
	set idx1 [string first "nav-last" $data] 

	if { $idx1 == "-1"} {
		return 1
	} else {
		set idx2 [string first "*" $data $idx1]
		set idx3 [string first "\"" $data $idx2]
		return [string range $data [expr $idx2 + 1] [expr $idx3 -1]]
	}
}

proc ::xuite::pic_page_list {id book page {passwd ""} {cb ::xuite::pic_get_cb}} {
	variable Priv
	variable policy
	
	set id [string tolower $id]
	set url "http://$Priv(albumUrl)/$id/$book*$page"
	
	if {$page == 1} {
		set url "http://$Priv(albumUrl)/$id/$book"		
	} 
	
	if {$passwd != ""} {
		::xuite::pic_check_login $url data $passwd
		if {$data == "" || [string first [string tolower $id] $data] <0} {return ""}
	} else {
		set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
		catch {
			set code 403	
			set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
			set data [http::data $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
		}
		if {$code != 200} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "Xuite現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
				-type ok \
				-icon info
			return ""
		}	
	}

	set idx1 [string first {<div class="list_area">} $data]
	set idx2 [string last {<p class="photo_info_title">} $data]
	set idx3 [string first "</div>" $data $idx2]
	set idx3 [string first "</div>" $data [expr $idx3 + 1]]
	set data [string range $data [expr $idx1 +24] [expr $idx3 + 6]]		
	set doc [dom parse -html "<div>$data</div>"]
	set root [$doc documentElement]
	set ret ""
	
	foreach photo [$root childNodes]	{
		set thumb [[$photo selectNode {./a/img}] getAttribute src]
		set idx1 [string last "/" $thumb]
		set pid [string range $thumb [expr $idx1 + 1] end]
		set title   [string trim [[$photo selectNodes {./div/p/a}] text]]
		set idx1 [string last "_" $thumb]
		set furl [string replace $thumb [expr $idx1 + 1] [expr $idx1 + 1] "l"]
		set purl "[[$photo selectNodes {./a} ] getAttribute href]/sizes/o/"
		lappend ret [list $pid $title $thumb $furl $purl]
	}
	
	$doc delete
	
	return $ret
	
}

proc ::xuite::vfriend_list {id {cb ::wretch::pic_get_cb}} {
	return ""
}

proc ::xuite::video_page_count {id {cb ::wretch::pic_get_cb} {p 1} } {
	variable Priv
	return 0
}	

proc ::xuite::video_page_list {id page {cb ::wretch::pic_get_cb}} {
	return ""
}

proc ::xuite::mkurl {type args} {
	switch $type {
		home {
			lassign $args id
			return "http://$id.pixnet.net/profile"
		}
		album {
			lassign $args id
			return "http://$id.pixnet.net/album"
		}
		blog {
			lassign $args id
			return "http://$id.pixnet.net/blog"
		}
		video {
			lassign $args id
			return "http://$id.pixnet.net/album"
		}
		book {
			lassign $args id book
			return "http://$id.pixnet.net/guestbook"
		}				
	}
}

#puts ==[::xuite::pic_page_list fang0912570770 3379136 1]
