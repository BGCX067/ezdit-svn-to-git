package provide wretch 1.0
package require http
package require tdom

namespace eval ::wretch {
	variable Priv
	array set Priv [list \
		timeout 30000 \
		retry 5 \
		albumUrl "http://www.wretch.cc/album" \
		videoUrl "http://www.wretch.cc/video" \
		debug 0 \
	]

	http::config -useragent {Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-TW; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12}
	
}

proc ::wretch::book_page_count {id {cb ::wretch::pic_get_cb} {p 1}} {
	variable Priv
	
	set id [string tolower $id]
	
	set url $Priv(albumUrl)
	append url "/" $id "&page=$p"

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
			-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return 0
	}
	if {$code != 200} {return 0}
	
	set maxPage 1
	set idx1 [string first "<body" $data]
	set idx2 $idx1
	while {$idx1 != "-1"} {
		set idx1 [string first "${id}&page=" $data $idx2]
		if {$idx1 == -1} {break}
		set idx2 [string first "\"" $data $idx1]
		lassign [split [string range $data $idx1 [incr idx2 -1]] "="] tmp page
		set idx1 $idx2
		if {$page > $maxPage} {set maxPage $page}
	}
	
	if {$maxPage > $p} {
		set tmp [::wretch::book_page_count $id $cb $maxPage]
		if {$tmp > $maxPage} {set maxPage $tmp}
	}
	
	return $maxPage
}

proc ::wretch::book_page_list {id page {cb ::wretch::pic_get_cb}} {
	variable Priv
	
	if {$id == "人氣相簿"} {return [::wretch::hot_page_list 0 0 $page $cb]}
	if {$id == "精選相簿"} {return [::wretch::hot_page_list 4 0 $page $cb]}	
	if {$id == "隨機推薦"} {return [::wretch::hot_page_list 6 0 $page $cb]}	
	
	set id [string tolower $id]
	
	set url $Priv(albumUrl)
	append url "/" $id "&page=" $page	

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7"]
	catch {
		set code 403		
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
		set data [http::data $tok]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}

	set idx1 [string first {<table id="ad_square"} $data]
	set idx2 [string first {</table>} $data [expr $idx1 + 1]]
	set data [string range $data $idx1 [expr $idx2 + 7]]

	set doc [dom parse -html $data]
	set root [$doc documentElement]
	set ret ""
	foreach {tr1 tr2} [$root selectNode {tr}] {
		foreach {td1} [$tr1 childNodes] {td2} [$tr2 childNodes] {
			set book [[$td1 selectNode {./a}] getAttribute href]
			set book [lindex [split $book "="] end]
			set thumb [[$td1 selectNode {./a/img}] getAttribute src]
			set title [[$td2 selectNode {./b/font/a}] text]
			set num [string trim [[$td2 selectNode {./b[2]/font}] text]]
			set data [$td2 asHTML]
			set key 0
			set new 0
			if {[string first "key.gif" $data] >= 0} {set key 1}
			if {[string first "new_album.gif" $data] >= 0} {set new 1}
			#set thumb [lindex [split $thumb "?"] 0]
			lappend ret [list $id $book $title $num $thumb $new $key]
			#puts [list $id $book $title $num $thumb $new $key]
		}
	}
	$doc delete
	return $ret
}

proc ::wretch::debug {msg} {
	variable Priv
	if {$Priv(debug)} {puts $msg}
}

proc ::wretch::friend_list {id {cb ::wretch::pic_get_cb}} {
	variable Priv
	
	set id [string tolower $id]

	set url "$Priv(albumUrl)/$id"

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
	catch {
		set code 403	
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
		set data [http::data $tok]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}

	set idx1 [string first {<select id="friendlist"} $data]
	set idx2 [string first {</select>} $data $idx1 ]
	set data [string range $data $idx1 [expr $idx2 + 8] ]

	set doc [dom parse -html $data]
	set root [$doc documentElement]
	
	set cut 0
	set ret ""
	foreach {opt}  [$root selectNode {//optgroup/option}] {
		if {$cut == 0} {	incr cut ;	continue	}
		set id [$opt getAttribute value]
		set title [$opt text]
		set group [[$opt parentNode] getAttribute label]
		lappend ret [list $group $id $title]
	}
	
	$doc delete
	return $ret
}

proc ::wretch::hot_page_list {hid classid page {cb ::wretch::pic_get_cb}} {
	variable Priv

	set url "$Priv(albumUrl)/?func=hot&hid=$hid&class_id=$classid&page=$page"

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
	catch {
		set code 403	
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
		set data [http::data $tok]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}

	set idx1 [string first {<ul class="album_list"} $data] 
	set idx2 [string first {</ul>} $data $idx1]
	set data [string range $data $idx1 [expr $idx2 +4]]

	set ret ""
	set doc [dom parse -html $data]
	set root [$doc documentElement]
	foreach {li} [$root selectNode {./li}] {
		lassign [$li childNodes] div1 div2
		set url [[$div1 selectNode {./a}] getAttribute href]
		set url [lindex [split $url "?"] end]
		lassign [split $url "&"] id book
		set id [lindex [split $id "="] end]
		set book [lindex [split $book "="] end]
		set thumb [[$div1 selectNode {./a/img}] getAttribute src]
		set title [[$div1 selectNode {./a/img}] getAttribute alt]
		lappend ret  [list $id $book $id $title $thumb 0 0]
		::wretch::debug [list $id $book $id $title $thumb 0 0]
	}
	$doc delete
	
	return $ret
}

proc ::wretch::mkurl {type args} {
	switch $type {
		home {
			lassign $args id
			return "http://www.wretch.cc/mypage/$id"
		}
		album {
			lassign $args id
			return "http://www.wretch.cc/album/$id"
		}
		blog {
			lassign $args id
			return "http://www.wretch.cc/blog/$id"
		}
		video {
			lassign $args id
			return "http://www.wretch.cc/video/$id"
		}
		book {
			lassign $args id book
			return "http://www.wretch.cc/album/album.php?id=$id&book=$book"
		}				
	}
}

proc ::wretch::media_find {i b f p {passwd ""} {cb ::wretch::pic_get_cb}} {
	variable Priv
	
	set i [string tolower $i]

	set url "$Priv(albumUrl)/show.php?i=$i&b=$b&f=$f&p=$p"

	set sn $f
	if {$passwd != ""} {
		set data ""
		::wretch::pic_check_login $url data $passwd
		if {$data == "" || [string first [string tolower $sn] $data] <0} {return ""}
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
				-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
				-type ok \
				-icon info
			return ""
		}
		if {$code != 200} {return ""}
	}


	set idx1 [string first "file=http" $data]
	if {$idx1 <0} {return ""}
	set idx2 [string first ".flv" $data $idx1]
	set ret [string range $data [expr $idx1+5] [expr $idx2+3]]
	return $ret
}

proc ::wretch::pic_get {url fpath {cb ::wretch::pic_get_cb}} {
	variable Priv
	
	set idx [string first "?" $url]
	if {$idx > 0} {
		set host [string tolower [string range $url 0 $idx]]
		set qs [string range $url [incr idx] end]
		set url [append host $qs]
	} else {
		set url [string tolower $url]
	}
	
	set ref [file rootname [file rootname [file rootname $url]]]
	set headers [list Pragms no-cache Cache-Control no-cache ]
	if {[file extension $fpath] == ".jpg" || [file extension $fpath] == ".gif"} {
		lappend headers Referer $ref
	}


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
			-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
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

proc ::wretch::pic_check_login {url html passwd} {
	variable Priv
	
	set loginRetry $Priv(retry)
	upvar $html data

	set hdr ""
	lappend hdr \
		Accept-Language "zh-tw;q=0.7,en;q=0.3" \
		Accept-Charset "utf-8;q=0.7,*;q=0.7"
	if {[catch {
		set tok [http::geturl $url -headers $hdr ]
		set data [http::data $tok]
		upvar \#0 $tok state
		set meta $state(meta)
		http::cleanup $tok
	}]} {set data "" ; return}

	for {set i 0} {$i<$loginRetry} {incr i} {
		set idx1 [string first {<form method} $data]
		if {$idx1 == -1} {break}
		set idx2 [string first {</form>} $data $idx1]	
		set data [string range $data $idx1 [expr $idx2+6]]

		set data "<html><body>$data</body></html>"
		
		set doc [dom parse -html $data]

		set root [$doc documentElement]
		set form [$root selectNode {/html/body/form}]
		set c [[$form selectNode {input[1]}] getAttribute value]
		set t [[$form selectNode {input[2]}] getAttribute value]
		set b [[$form selectNode {input[4]}] getAttribute value]
		$doc delete
		
		set post [http::formatQuery .c $c .t $t passwd $passwd submit $b]

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
			Accept-Charset "utf-8;q=0.7,*;q=0.7" \
			Cookie [join $cookies {;}]
		if {[catch {
			set tok [http::geturl $url -headers $hdr -query $post]
			set data [http::data $tok]
			upvar \#0 $tok state
			set meta $state(meta)	
			http::cleanup $tok
		}]} {set data "" ; return}
		
		if {[string first "show.php?" $data] > 0} {return}
	}
	set data ""
	return
}

proc ::wretch::pic_get_cb {tok total current {cb ::wretch::pic_get_cb}} {
	upvar #0 $tok state
	#puts "$total $current"
	return
}


proc ::wretch::pic_page_count {id book {passwd ""} {cb ::wretch::pic_get_cb} {p 1}} {
	variable Priv
	
	set id [string tolower $id]
	
	set url "$Priv(albumUrl)/album.php?id=$id&book=$book&page=$p"

	if {$passwd != ""} {
		set data ""
		::wretch::pic_check_login $url data $passwd
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
				-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"] \
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
		set idx1 [string first "book=$book&page=" $data $idx2]
		if {$idx1 == -1} {break}
		set idx2 [string first "\"" $data $idx1]
		lassign [split [string range $data $idx1 [incr idx2 -1]] "="] tmp tmp page
		set idx1 $idx2
		if {$page > $maxPage} {set maxPage $page}
	}
	
	if {$maxPage > $p} {
		set tmp [::wretch::pic_page_count $id $book $passwd $cb $maxPage]
		if {$tmp > $maxPage} {set maxPage $tmp}
	}	
	::wretch::debug $maxPage
	return $maxPage	

}

proc ::wretch::pic_page_list {id book page {passwd ""} {cb ::wretch::pic_get_cb}} {
	variable Priv
	variable policy
	
	set id [string tolower $id]
	
	set url "$Priv(albumUrl)/album.php?id=$id&book=$book&page=$page"

	if {$passwd != ""} {
		set data ""
		::wretch::pic_check_login $url data $passwd
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
		if {$code == 999} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
				-type ok \
				-icon info
			return ""
		}	
		if {$code != 200} {return ""}	
	}
	
	set data $data
	set idx1 [string first "<link rel" $data]
	set idx1 [string first "<link rel" $data [expr $idx1+1]]
	set idx1 [string first "http://" $data [expr $idx1+1]]
	set idx2 [string first "/" $data [expr $idx1 +7]]
	set host [string range $data $idx1 [incr idx2 -1]]

	set idx1 [string first {<table id="ad_square"} $data]
	set idx2 [string first {</table>} $data $idx1]
	set data [string range $data $idx1 [expr $idx2 + 7]]	
	
	set items "<items>\n"
	set idx2 0
	while {1} { 
		set idx1 [string first "href=\"./show.php?i=$id&b=$book&f=" $data $idx2]
		if {$idx1 == -1} {break}
		set idx2 [string first "</a>" $data $idx1]
		set item [string range $data $idx1 [incr idx2 3]]
		append items "<a $item\n"
		
	}
	append items "</items>"
	
	set fList [list]
	array set arr [list]
	set doc [dom parse -html $items]
	set root [$doc documentElement]	
	foreach a [$root selectNode {./a}] {

		set href [$a getAttribute href]

		set idx1 [string first "f=" $href]
		set idx2 [string first "&" $href [incr idx1 2]]
		set f [string range $href $idx1 [incr idx2 -1]]

		if {[lsearch -exact $fList $f] == -1} {
			lappend fList $f
			set arr($f,url) "$host/$id/$book/$f"
			set arr($f,thumb) ""
			set arr($f,title) ""			
		}
		
		if {[$a selectNode {./img}] != ""} {
			set arr($f,thumb) [[$a selectNode {./img}] getAttribute src]
			append arr($f,url) "?" [lindex [split $arr($f,thumb) "?"] 1]
		} else {
			set arr($f,title) [$a text]
		}
		
		
		
	}
	$doc delete
	
	set ret ""
	set i 0
	foreach f $fList {
		::wretch::debug [list $f $arr($f,title) $arr($f,thumb) $arr($f,url)]

		lappend ret [list $f $arr($f,title) $arr($f,thumb) $arr($f,url) [expr ($page-1)*20+$i]]
		incr i
	}
	
	return $ret
	
}

proc ::wretch::vfriend_list {id {cb ::wretch::pic_get_cb}} {
	variable Priv
	
	set url "$Priv(videoUrl)/$id"
	set id [string tolower $id]
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
			-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"] \
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}
	
	set idx1 [string first {<select name="friend_video">} $data]
	if {$idx1 == -1} {return ""}
	set idx2 [string first {</select>} $data $idx1]
	set data [string range $data $idx1 [expr $idx2+8]]

	set ret [list]
	set doc [dom parse -html $data]
	set root [$doc documentElement]
	foreach item [$root selectNodes {//optgroup/option}] {
		set fid [$item getAttribute value]
		set title [string trim [$item text]]
		set group [[$item parentNode] getAttribute label]
		lappend ret [list $group $fid $title]
	}
	
	$doc delete
	return $ret
}

proc ::wretch::video_check_login {url html passwd} {
	variable Priv
	
	set loginRetry $Priv(retry)
	upvar $html data

	set cookies ""
	set hdr ""
	lappend hdr \
		Accept-Language "zh-tw;q=0.7,en;q=0.3" \
		Accept-Charset "utf-8;q=0.7,*;q=0.7"			
				
	for {set i 0} {$i<$loginRetry} {incr i} {
		if {[catch {
			set tok [http::geturl $url -headers $hdr ]
			set data [http::data $tok]
			upvar \#0 $tok state
			set meta $state(meta)
			http::cleanup $tok
		}]} {set data "" ; return}		
		
		if {[string first ".flv" $data] > 0} {return}
		
		set idx1 [string first {<form method} $data]
		set idx2 [string first {</form>} $data $idx1]	
		set data [string range $data $idx1 [expr $idx2+6]]

		set data "<html><body>$data</body></html>"
		
		set doc [dom parse -html $data]

		set root [$doc documentElement]
		set form [$root selectNode {/html/body/form}]
		set c [[$form selectNode {input[1]}] getAttribute value]
		set t [[$form selectNode {input[2]}] getAttribute value]
		set vurl [[$form selectNode {input[4]}] getAttribute value]
		set vid [[$form selectNode {input[5]}] getAttribute value]
		set vowner [[$form selectNode {input[6]}] getAttribute value]
		set vpwd [[$form selectNode {input[7]}] getAttribute value]
		$doc delete

		set post [http::formatQuery \
			.c $c \
			.t $t \
			video_passwd $passwd \
			url $vurl \
			video_id $vid \
			owner_id $vowner \
			pwd $vpwd]

		set cookies "VideoClass=17"
		foreach {name value} $meta {
			if {$name == "Set-Cookie"} {
				if {[lindex [split $value {;}] 0] == "lang=deleted"} {continue}
				lappend cookies [lindex [split $value {;}] 0]
			}
		}

		set hdr ""
		lappend hdr \
			Host "www.wretch.cc" \
			Keep-Alive 300 \
			Connection keep-alive \
			Referer $url \
			Accept-Language "zh-tw;q=0.7,en;q=0.3" \
			Accept-Charset "utf-8;q=0.7,*;q=0.7" \
			Cookie [join $cookies {;}]
		
		if {[catch {
			set tok [http::geturl "$Priv(videoUrl)/single_passed.php" -headers $hdr -query $post]
			set data [http::data $tok]
			upvar \#0 $tok state
			set meta $state(meta)	
			http::cleanup $tok
		}]} {set data "" ; return}
	}
	set data ""
	return
}

proc ::wretch::video_get {url fpath {passwd ""} {cb ::wretch::pic_get_cb}} {
	variable Priv

	if {$passwd != ""} {
		set data ""
		::wretch::video_check_login $url data $passwd
		if {$data == ""} {return ""}		
	} else {
		set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
		catch {
			set code 403
			set tok [http::geturl $url -headers $headers ]
			set data [http::data $tok]
			set s [http::status $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
		}
		if {$code == 999} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"] \
				-type ok \
				-icon info
			return ""
		}
		if {$code != 200 && $code != 302} {return ""}
	}

	set idx1 [string first ".flv" $data]
	if {$idx1 < 0} {return ""}
	set idx2 [string last "http://" $data $idx1]
	set url [string range $data $idx2 [expr $idx1 + 3]]

	return [::wretch::pic_get $url $fpath $cb]

	return $fpath
}

proc ::wretch::video_page_count {id {cb ::wretch::pic_get_cb} {p 1} } {
	variable Priv
	
	set id [string tolower $id]
	
	set url $Priv(videoUrl)
	append url "/" $id "&page=$p"

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
			-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return 0
	}
	if {$code != 200} {return 0}
	
	set maxPage 1
	set idx1 [string first "<body" $data]
	set idx2 $idx1
	while {$idx1 != "-1"} {
		set idx1 [string first "&page=" $data $idx2]
		if {$idx1 == -1} {break}
		set idx2 [string first "\"" $data $idx1]
		lassign [split [string range $data $idx1 [incr idx2 -1]] "="] tmp page
		set idx1 $idx2
		if {$page > $maxPage} {set maxPage $page}
	}
	
	if {$maxPage > $p} {
		set tmp [::wretch::video_page_count $id $cb $maxPage]
		if {$tmp > $maxPage} {set maxPage $tmp}
	}
	
	return $maxPage
}	

proc ::wretch::video_page_list {id page {cb ::wretch::pic_get_cb}} {
	variable Priv
	
	set url "$Priv(videoUrl)/$id&page=$page"

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
			-message  [::msgcat::mc "無名小站現在不允許您的連線，請稍後再試或使用代理伺服器。"] \
			-type ok \
			-icon info
	}	
	if {$code != 200} {return ""}

	set idx1 [string first "videoPosts" $data]
	set idx1 [string first "<ol>" $data $idx1]
	if {$idx1 == -1} {return ""}
	set idx2 [string first "</ol>" $data $idx1]
	set data [string range $data $idx1 [expr $idx2 + 4]]


	set ret [list]
	set doc [dom parse -html $data]
	set root [$doc documentElement]

	foreach {item} [$root selectNode {/ol/li}] {
		lassign [$item childNodes] div1 div2
		set thumb [[$div1 selectNode {./span/a/img}] getAttribute src]
		set url $Priv(videoUrl)
		append url "/" [[$div1 selectNode {./span/a}] getAttribute href]
		set title [[$div2 selectNode {./p[1]/a}] text]
		#set date [[$div2 selectNode {./p[4]}] text]
		set date ""
		set key 0
		if {[string first "key.gif" [$div2 asHTML]] >=0} {set key 1}
		lappend ret [list $date $title $url $thumb $key]
		#puts [list $date $title $url $thumb $key]
	}
	$doc delete

	return $ret
}	

#::wretch::vfriend_list good771108
#exit
#puts [::wretch::video_page_count howard260]
#exit

#foreach item [::wretch::video_page_list anne106112 1] {
#	lassign $item date title url thumb key
#	::wretch::video_get $url ~/tmp/a.flv ""
#	break
#}
#exit
