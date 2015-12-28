package provide yam 1.0
package require http
package require tdom

namespace eval ::yam {
	variable Priv
	array set Priv [list \
		timeout 15000 \
		retry 5 \
		albumUrl "http://album.blog.yam.com" \
		videoUrl "http://www.wretch.cc/video" \
		debug 0 \
	]

	http::config -useragent {Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-TW; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12}
	
}

proc ::yam::book_page_count {id {cb ::yam::pic_get_cb} {p 1}} {
	variable Priv
	
	set id [string tolower $id]
	
	set url $Priv(albumUrl)
	append url "/" $id

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
			-message  [::msgcat::mc "天空相簿現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return 0
	}
	if {$code != 200} {return 0}
	
	set maxPage 1
	set str "album.php?userid=${id}&page="
	set len [string length $str]
	set idx1 [string first {<div class="pageCtrl"} $data]
	
	set idx2 $idx1
	while {$idx1 != "-1"} {
		set idx1 [string first $str $data $idx1]
		
		if {$idx1 == -1} {break}
		
		set idx2 [string first {&} $data [expr $idx1 + $len]]
		
		set page [lindex [split [string range $data $idx1 [incr idx2 -1]] "="] end ]
		set idx1 $idx2
		if {$page > $maxPage} {set maxPage $page}
	}
	
	
	return $maxPage
}

proc ::yam::book_page_list {id page {cb ::yam::pic_get_cb}} {
	variable Priv
	
	if {$id == "人氣相簿"} {return [::yam::hot_page_list $page $cb]}
	if {$id == "精選相簿"} {return [::yam::hot_page_list hot $page $cb]}	
	if {$id == "隨機推薦"} {return [::yam::hot_page_list lastest $page $cb]}	
	
	set id [string tolower $id]
	
	set url $Priv(albumUrl)
	append url "/" $id "&page=" $page	

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7"]
	catch {
		set code 403		
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
		set data [encoding convertfrom utf-8 [http::data $tok]]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "天空相簿現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}
	

	set data2 "<html><body>"
	set idx1 [string first {<div id="albumList">} $data]
	set ret ""
	set flag "old"
	if {$idx1 >=0 } {
		set idx2 [string first {<div class="pageCtrl">} $data $idx1]
		append data2 [string range $data $idx1 [expr $idx2 -1]] "</div></body></html>"
		set flag "new"
	} else {
		set idx1 [string first {<table class="albumList"} $data]
		set idx2 [string first {</table>} $data $idx1]
		append data2 [string range $data $idx1 [expr $idx2 +7]] "</body></html>"	
	}
	regsub -all {\/alt} $data2 {alt} data2
	regsub -all {\/>} $data2 {>} data2

	set doc [dom parse -html $data2]
	set root [$doc documentElement]
	
	if {$flag == "new"} {
		foreach {div} [$root selectNode {//div[@class="album"]}] {
			set book [[$div selectNode {./table/tr/td/a}] getAttribute href]
			set book [lindex [split $book "="] end]
			set img [$div selectNode {./table/tr/td/a/img}]
			set title [$img getAttribute title]
			set thumb [$img getAttribute src]
			
			set tmp [[$div selectNode {./div[@class='albumList_title']}] asHTML]
			set new 0
			set key 0
			if {[string first {new_album.gif} $tmp] >=0} {set new 1}
			if {[string first {password.png} $tmp] >=0} {set key 1}
			
			set tmp [[$div selectNode {./div[@class='albumList_info']/a}] text]
			set tmp [lindex [split $tmp " "] 1]
			set num [string range $tmp 1 end-1]
			
			lappend ret [list $id $book $title $num $thumb $new $key]
		}
	} else {
		foreach {tr1 tr2} [$root selectNode {//table/tr}] {
			if {$tr2 == ""} {continue}
			foreach {td1} [$tr1 childNodes] {td2} [$tr2 childNodes] {
				set book [[$td1 selectNode {./a}] getAttribute href]
				set book [lindex [split $book "="] end]
				set img [$td1 selectNode {./a/img}]
				set title [$img getAttribute title]
				set thumb [$img getAttribute src]	
				
				set tmp [$td2 asHTML]
				set new 0
				set key 0
				if {[string first {new_album.gif} $tmp] >=0} {set new 1}
				if {[string first {password.png} $tmp] >=0} {set key 1}
				
				set tmp [[$td2 selectNode {./div[@class='info']/a}] text]
				set tmp [lindex [split $tmp " "] 1]
				set num [string range $tmp 1 end-1]

				lappend ret [list $id $book $title $num $thumb $new $key]
			}
			set tr2 ""
		}		
	}
	
	$doc delete
	return $ret
}

proc ::yam::debug {msg} {
	variable Priv
	if {$Priv(debug)} {puts $msg}
}

proc ::yam::friend_list {id {cb ::yam::pic_get_cb}} {
	variable Priv
	
	set id [string tolower $id]

	set url "http://blog.yam.com/${id}&act=friend"

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
	catch {
		set code 403	
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
		set data [encoding convertfrom utf-8 [http::data $tok]]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code != 200} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "天空相簿現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	

	set data2 "<html><body>"
	set idx1 [string first {<div id="articleBlock">} $data]
	set idx2 [string first {<div id="MainSide">} $data $idx1]
	append data2 [string range $data $idx1 [expr $idx2 -1]] "</body></html>"

	set doc [dom parse -html $data2]
	set root [$doc documentElement]
	
	set cut 0
	set ret ""
	foreach {a}  [$root selectNode {//div[@class="friendlist"]/div[2]/a}] {
		set title [$a text]
		set url [$a getAttribute href]
		set id [file tail [lindex [split $url "&"] 0]]
		if {$title == ""} {set title $id}
		lappend ret [list "friend" $id $title]
	}
	
	$doc delete
	return $ret
}



proc ::yam::hot_page_list {page {cb ::yam::pic_get_cb}} {
	variable Priv

	set url "http://blog.yam.com/index.php?op=album&b=0&sort=dayhot&from=0&page=${page}&limit=24"

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
			-message  [::msgcat::mc "天空相簿現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	


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
		::yam::debug [list $id $book $id $title $thumb 0 0]
	}
	$doc delete
	
	return $ret
}

proc ::yam::mkurl {type args} {
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

proc ::yam::media_find {i b f p {passwd ""} {cb ::yam::pic_get_cb}} {
	variable Priv
	
	set i [string tolower $i]

	set url "$Priv(albumUrl)/show.php?i=$i&b=$b&f=$f&p=$p"

	set sn $f
	if {$passwd != ""} {
		set data ""
		::yam::pic_check_login $url data $passwd
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

proc ::yam::pic_get {url fpath {cb ::yam::pic_get_cb}} {
	
	set url [string tolower $url]
	
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
			-progress $cb]
		set code [http::ncode $tok]
	}]} {	return "" 	}
	
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "天空相簿現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
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

proc ::yam::pic_check_login {url html passwd} {
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

proc ::yam::pic_get_cb {tok total current {cb ::yam::pic_get_cb}} {
	upvar #0 $tok state
	#puts "$total $current"
	return
}


proc ::yam::pic_page_count {id book {passwd ""} {cb ::yam::pic_get_cb} {p 1}} {
	variable Priv
	
	set id [string tolower $id]
	
	set url "$Priv(albumUrl)/${id}&folder=$book"

	if {$passwd != ""} {
		set data ""
		::yam::pic_check_login $url data $passwd
		if {$data == "" || [string first [string tolower $id] $data] <0} {return 0}
	} else {
		set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
		catch {
			set code 403
			set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
			set data [encoding convertfrom utf-8 [http::data $tok]]
			set s [http::status $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
		}
		if {$code == 999} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "天空相簿現在不允許您的連線，請稍後再試或使用代理伺服器。"] \
				-type ok \
				-icon info
			return 0
		}	
		if {$code != 200} {return 0}	
	}
	
	set maxPage 1
	set maxPage 1
	set str "/${id}&folder=${book}&page=" 
	set len [string length $str]
	set idx1 [string first {<div class="pageCtrl"} $data]
	
	set idx2 $idx1
	while {$idx1 != "-1"} {
		set idx1 [string first $str $data $idx1]
		
		if {$idx1 == -1} {break}
		
		set idx2 [string first {&} $data [expr $idx1 + $len]]
		
		set page [lindex [split [string range $data $idx1 [incr idx2 -1]] "="] end ]
		set idx1 $idx2
		if {$page > $maxPage} {set maxPage $page}
	}
	
	return $maxPage	

}

proc ::yam::pic_page_list {id book page {passwd ""} {cb ::yam::pic_get_cb}} {
	variable Priv
	variable policy
	
	set id [string tolower $id]
	
	set url "$Priv(albumUrl)/${id}&folder=${book}&page=$page"

	if {$passwd != ""} {
		set data ""
		::yam::pic_check_login $url data $passwd
		if {$data == "" || [string first [string tolower $id] $data] <0} {return ""}
	} else {
		set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
		catch {
			set code 403	
			set tok [http::geturl $url -headers $headers -timeout $Priv(timeout) -progress $cb]
			set data [encoding convertfrom utf-8 [http::data $tok]]
			set code [http::ncode $tok]
			http::cleanup $tok
		}
		if {$code != 200} {
			tk_messageBox -title [::msgcat::mc "資訊"] \
				-message  [::msgcat::mc "天空現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
				-type ok \
				-icon info
			return ""
		}
	}
	
	set data2 "<html><body>"
	set idx1 [string first {<div id="photobody">} $data]
	set idx2 [string first {<div class="pageCtrl">} $data $idx1]

	append data2 [string range $data $idx1 [expr $idx2 -1]] "</div></body></html>"

	set ret ""
	
	set doc [dom parse -html $data2]
	set root [$doc documentElement]	
	foreach {div} [$root selectNode {//div[@class='photo']}] {
		set img [$div selectNode {./table/tr/td/a/img}]
		set title [$img getAttribute title]
		set thumb [$img getAttribute src]
		set sn [string range [file tail $thumb] 2 end]
		set url [string range $thumb 0 [string last "/" $thumb]]
		append url $sn
		set sn [file rootname $sn]
		lappend ret [list $sn $title $thumb $url ]
	}
	$doc delete
	
	return $ret
	
}

proc ::yam::vfriend_list {id {cb ::yam::pic_get_cb}} {
	return [::yam::friend_list $id $cb]
}

proc ::yam::video_check_login {url html passwd} {
	variable Priv
	return
}

proc ::yam::video_get {url fpath {passwd ""} {cb ::yam::pic_get_cb}} {
	variable Priv
	return ""
}

proc ::yam::video_page_count {id {cb ::yam::pic_get_cb} {p 1} } {
	variable Priv
	return 0
}	

proc ::yam::video_page_list {id page {cb ::yam::pic_get_cb}} {
	variable Priv
	return ""
}	

#::yam::book_page_list  pureland 1
#puts [::yam::pic_page_list ahguo 6024422 1]
#puts [::yam::friend_list a267360]
#::yam::vfriend_list good771108
#exit
#puts [::yam::video_page_count howard260]
#exit

#foreach item [::yam::video_page_list anne106112 1] {
#	lassign $item date title url thumb key
#	::yam::video_get $url ~/tmp/a.flv ""
#	break
#}
#exit
