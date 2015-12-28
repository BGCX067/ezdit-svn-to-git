package provide pchome 1.0
package require http
package require tdom

namespace eval ::pchome {
	variable Priv
	array set Priv [list \
		timeout 30000 \
		retry 5 \
		albumUrl "http://photo.pchome.com.tw" \
		videoUrl "http://video.pchome.com.tw" \
		debug 0 \
	]

	http::config -useragent {Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-TW; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12}
	
}

proc ::pchome::book_page_count {id {cb ::pchome::pic_get_cb} {p 1}} {
	variable Priv
	
	set id [string tolower $id]
	
	set url $Priv(albumUrl)
	append url "/" $id "*$p"

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7"]
	
	catch {
		set code 403
		set tok [http::geturl $url -headers $headers -timeout  $Priv(timeout) -progress $cb]
		set data [http::data $tok]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "Pchome現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return 0
	}
	if {$code != 200} {return 0}
	
	set maxPage 1
	set idx1 [string first "<body" $data]
	set idx2 $idx1

	while {$idx1 != "-1"} {
		set idx1 [string first "/${id}*" $data $idx2]
		if {$idx1 == -1} {break}
		set idx2 [string first "\"" $data $idx1]
		lassign [split [string range $data $idx1 [expr $idx2-1]] "*"] tmp page
		set idx1 $idx2
		if {$page > $maxPage} {set maxPage $page}
	}
	
	if {$maxPage > $p} {
		set tmp [::pchome::book_page_count $id $cb $maxPage]
		if {$tmp > $maxPage} {set maxPage $tmp}
	}
	
	return $maxPage
}

proc ::pchome::book_page_list {id page {cb ::pchome::pic_get_cb}} {
	variable Priv
	
	if {$id == "人氣相簿"} {
		set url "http://photo.pchome.com.tw/album_pv.html"
		return [::pchome::hot_page_list $url $page]
	}
	if {$id == "精選相簿"} {
		set url "http://photo.pchome.com.tw/recommend.html"
		return [::pchome::hot_page_list $url $page]
	}	
	if {$id == "隨機推薦"} {
		set url "http://photo.pchome.com.tw/album_new.html"
		return [::pchome::hot_page_list $url $page]
	}	
	
	set id [string tolower $id]
	
	set url $Priv(albumUrl)
	append url "/" $id "*$page"

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "big5;q=0.7,*;q=0.7"]
	catch {
		set code 403		
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
		set data [encoding convertfrom big5 [http::data $tok]]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "PChome現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}

	set idx1 [string first "<body " $data]
	set idx2 [string last "</body>" $data]
	set data [string range $data $idx1 [incr idx2 6]]
	

	set doc [dom parse -html $data]
	set root [$doc documentElement]
	set ret ""
	foreach {alb} [$root selectNode {//div[@id="alb"]}] {
		set book [[$alb selectNode {./a}] getAttribute href]
		set book [lindex [split $book "/"] end-1]
		set title ""
		if {[catch {set title [[$alb selectNode {./a/div/span}] text]}]} {
			catch {set title [[$alb selectNode {./a/div}] text]}
		}
		set descript [$alb text]
		set thumb $Priv(albumUrl)
		set turl [string range [[$alb selectNode {./a/span/span}] getAttribute id] 4 end-1]
		set parts [file split $turl]
		lassign $parts r h f1 f2 
		if {$f1 != [string index $id 0] && $f2 != [string index $id 1]} {
			set parts [linsert $parts 2 [string index $id 0] [string index $id 1]]
			append thumb "/" [join [lrange $parts 1 end] "/"]
		} else {
			append thumb $turl
		}
		set new 0
		set key 0
		if {[$alb selectNode {.//img[@src="/img/icon_new.gif"]}] != ""} {set new 1}
		if {[$alb selectNode {.//img[@src="/img/h_code.gif"]}] != ""} {set key 1}
		::pchome::debug [list $id $book $title $descript $thumb $new $key]
		lappend ret [list $id $book $title $descript $thumb $new $key]
	}
	$doc delete
	return $ret
}

proc ::pchome::debug {msg} {
	variable Priv
	if {$Priv(debug)} {puts $msg}
}

proc ::pchome::friend_list {id {cb ::pchome::pic_get_cb}} {
	set i 1
	set data [::pchome::friend_page_list $id $i]
	set ret [list]
	while {$data != ""} {
		foreach item $data {lappend ret $item}
		set data [::pchome::friend_page_list $id [incr i]]
	}
	return $ret
}


proc ::pchome::friend_page_list {id page {cb ::pchome::pic_get_cb}} {
	variable Priv
	
	set id [string tolower $id]

	set url "http://photo.pchome.com.tw/friend_list.html?page=$page&cond=&nickname=$id"

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "big5;q=0.7,*;q=0.7" ]
	catch {
		set code 403	
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
		set data [encoding convertfrom big5 [http::data $tok]]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "PChome現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}

	set doc [dom parse -html $data]
	set root [$doc documentElement]
	set ret ""
	foreach {div} [$root selectNode {//div[@id="fa"]}] {
		set id [file tail [[$div selectNode {./a}] getAttribute href]]
		set title [[$div selectNode {./div[1]/div[1]/a}] text]
		set group ""
		lappend ret  [list $group $id $title]
	}
	$doc delete
	return $ret
}

proc ::pchome::hot_page_list {url page {cb ::pchome::pic_get_cb}} {
	variable Priv

	set url "$url?page=$page"

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "big5;q=0.7,*;q=0.7" ]
	catch {
		set code 403	
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
		set data [encoding convertfrom big5 [http::data $tok]]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "PChome現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}


	set ret ""
	set doc [dom parse -html $data]
	set root [$doc documentElement]
	foreach {div} [$root selectNode {//div[@id="src_pt"]/div[@class="p"]}] {
		set alb [$div selectNode {./div[1]}]
		set tit [$div selectNode {./div[2]}]

		set href [[$tit selectNode {./a} ] getAttribute href]
		lassign [file split $href] tmp id book		
		
		set thumb $Priv(albumUrl)
		set turl [string range [[$alb selectNode {./a/span}] getAttribute id] 4 end-1]
		set parts [file split $turl]
		lassign $parts r h f1 f2 
		if {$f1 != [string index $id 0] && $f2 != [string index $id 1]} {
			set parts [linsert $parts 2 [string index $id 0] [string index $id 1]]
			append thumb "/" [join [lrange $parts 1 end] "/"]
		} else {
			append thumb $turl
		}

		set title [[$tit selectNode {./a} ] text]	
		lappend ret  [list $id $book $id $title $thumb 0 0]
		::pchome::debug [list $id $book $id $title $thumb 0 0]
	}
	$doc delete
	
	return $ret
}

proc ::pchome::mkurl {type args} {
	switch $type {
		home {
			lassign $args id
			return "http://photo.pchome.com.tw/$id"
		}
		album {
			lassign $args id
			return "http://photo.pchome.com.tw/$id"
		}
		blog {
			lassign $args id
			return "http://photo.pchome.com.tw/$id"
		}
		video {
			lassign $args id
			return "http://photo.pchome.com.tw/$id"
		}
		book {
			lassign $args id book
			return "http://photo.pchome.com.tw/$id/$book"
		}				
	}
}

proc ::pchome::pic_get {url fpath {cb ::pchome::pic_get_cb}} {
	variable Priv
	set url [string tolower $url]
	
	set ref [file rootname [file rootname [file rootname $url]]]
	set headers [list Pragms no-cache Cache-Control no-cache ]
	lappend headers Referer $ref

	if {[catch {
		set code 403
		set tok [http::geturl $url \
			-headers $headers \
			-binary 1 \
			-blocksize 4096 \
			-timeout $Priv(timeout) \
			-progress $cb]
		set code [http::ncode $tok]
	}]} {	return "" 	}
	
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "PChome現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}		
	if {$code != 200} { 	http::cleanup $tok ;	return "" 	}	
	set ret 0

	set fd [open $fpath w]
	fconfigure $fd -translation binary
	puts -nonewline $fd [http::data $tok]	
	close $fd

	http::cleanup $tok

	return $fpath
}

proc ::pchome::pic_check_login {url html passwd} {
	variable Priv

	set loginRetry $Priv(retry)
	upvar $html data

	for {set i 0} {$i<$loginRetry} {incr i} {

		set hdr ""
		lappend hdr \
			Accept-Language "zh-tw;q=0.7,en;q=0.3" \
			Accept-Charset "big5;q=0.7,*;q=0.7" \
			Referer $url
			
		if {[catch {
			set tok [http::geturl $url -headers $hdr ]
			set data [encoding convertfrom big5 [http::data $tok]]
			upvar \#0 $tok state
			set meta $state(meta)
			http::cleanup $tok
		}]} {set data "" ; return}
		
		set post [http::formatQuery pwd $passwd]
		
		set cookies ""
		foreach {name value} $meta {
			if {$name=="lang" && $value == "deleted"} {continue}
			if {$name eq "Set-Cookie"} {lappend cookies [lindex [split $value {;}] 0]}
		}
		
		set hdr ""
		lappend hdr \
			Keep-Alive 300 \
			Connection keep-alive \
			Referer $url \
			Accept-Language "zh-tw;q=0.7,en;q=0.3" \
			Accept-Charset "big5;q=0.7,*;q=0.7" \
			Cookie [join $cookies {;}]

		if {[catch {
			set tok [http::geturl $url -headers $hdr -query $post]
			set data [encoding convertfrom big5 [http::data $tok]]
			upvar \#0 $tok state
			set meta $state(meta)	
			http::cleanup $tok
		}]} {set data "" ; return}
		
		if {[string first {name="pwd"} $data] < 0} {return}
	}
	set data ""
	return
}

proc ::pchome::pic_get_cb {tok total current {cb ::pchome::pic_get_cb}} {
	upvar #0 $tok state
	#puts "$total $current"
	return
}


proc ::pchome::pic_page_count {id book {passwd ""} {cb ::pchome::pic_get_cb} {p 1}} {
	variable Priv
	
	set id [string tolower $id]
	set url $Priv(albumUrl)
	append url "/$id/$book*$p"

	if {$passwd != ""} {
		set data ""
		::pchome::pic_check_login $url data $passwd
		if {$data == "" || [string first [string tolower $id] $data] <0} {return 0}
	} else {
		set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "big5;q=0.7,*;q=0.7" ]
		catch {
			set code 403
			set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
			set data [encoding convertfrom big5 [http::data $tok]]
			set s [http::status $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
		}
		if {$code == 999} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "PChome現在不允許您的連線，請稍後再試或使用代理伺服器。"] \
				-type ok \
				-icon info
			return 0
		}	
		if {$code != 200} {return 0}	
	}
	
	set maxPage 1
	set idx1 [string first "<body" $data]
	set idx2 $idx1
	while {$idx1 != "-1"} {
		set idx1 [string first "/$id/$book*" $data $idx2]
		if {$idx1 == -1} {break}
		set idx2 [string first "\"" $data $idx1]
		lassign [split [string range $data $idx1 [expr $idx2-1]] "*"] tmp page
		set idx1 $idx2
		if {$page > $maxPage} {set maxPage $page}
	}
	
	if {$maxPage > $p} {
		set tmp [::pchome::pic_page_count $id $book $passwd $cb $maxPage]
		if {$tmp > $maxPage} {set maxPage $tmp}
	}	
	::pchome::debug $maxPage
	return $maxPage	

}

proc ::pchome::pic_page_list {id book page {passwd ""} {cb ::pchome::pic_get_cb}} {
	variable Priv
	variable policy
	
	set id [string tolower $id]
	
	set url "$Priv(albumUrl)/$id/$book*$page"

	if {$passwd != ""} {
		set data ""
		::pchome::pic_check_login $url data $passwd
		if {$data == "" || [string first [string tolower $id] $data] <0} {return ""}
	} else {
		set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "big5;q=0.7,*;q=0.7" ]
		catch {
			set code 403	
			set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
			set data [encoding convertfrom big5 [http::data $tok]]
			set code [http::ncode $tok]
			http::cleanup $tok
		}
		if {$code == 999} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "PChome現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
				-type ok \
				-icon info
			return ""
		}	
		if {$code != 200} {return ""}	
	}
	
	set idx1 [string first "<body onload" $data]
	set idx2 [string last "</body>" $data]
	set data [string range $data $idx1 [expr $idx2 +6]]


	set doc [dom parse -html $data]
	set root [$doc documentElement]
	set ret ""
	foreach {div} [$root selectNode {//div[@id="pic"]}] {
		set f [[$div selectNode {./a}] getAttribute href]
		set f [file tail $f]
		set title [[$div selectNode {./a/div/span}] text]

		set turl [string range [[$div selectNode {./a/span}] getAttribute id] 4 end-1]
		set parts [file split $turl]
		lassign $parts r h f1 f2 
		if {$f1 != [string index $id 0] && $f2 != [string index $id 1]} {
			set parts [linsert $parts 2 [string index $id 0] [string index $id 1]]
			set thumb "/" [join [lrange $parts 1 end] "/"]
		} else {
			set thumb $turl
		}		
		set ext [file extension $thumb]
		set url [file join [file dirname $thumb] "p$f$ext"]
		set url "$Priv(albumUrl)$url"
		set thumb "$Priv(albumUrl)$thumb"
		::pchome::debug [list $f $title $thumb $url]
		lappend ret [list $f $title $thumb $url]
	}
	$doc delete	
	return $ret
}

proc ::pchome::vfriend_list {id {cb ::pchome::pic_get_cb}} {
	variable Priv
	return ""
}

proc ::pchome::video_check_login {url html passwd} {
	variable Priv
	upvar $html data
	set data ""
	return
}

proc ::pchome::video_get {url fpath {passwd ""} {cb ::pchome::pic_get_cb}} {
	variable Priv
	return ""
}

proc ::pchome::video_page_count {id {cb ::pchome::pic_get_cb} {p 1} } {
	variable Priv
	return 0
}	

proc ::pchome::video_page_list {id page {cb ::pchome::pic_get_cb}} {
	variable Priv
	return ""
}	

#puts ==[::pchome::book_page_list only_love_aiko 1]

#::pchome::hot_page_list 1 
#set data ""
#
#::pchome::pic_check_login http://photo.pchome.com.tw/adai1115/01/ data 123

#::pchome::friend_list tiandi19

#::pchome::book_page_list tiandi19 1

#puts ==[::pchome::pic_page_count only_love_aiko 081]

#puts ==[::pchome::pic_page_list aka0524 070 1]
#::pchome::vfriend_list good771108
#exit
#puts [::pchome::video_page_count howard260]
#exit

#foreach item [::pchome::video_page_list anne106112 1] {
#	lassign $item date title url thumb key
#	::pchome::video_get $url ~/tmp/a.flv ""
#	break
#}
#exit

