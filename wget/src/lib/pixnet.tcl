package provide pixnet 1.0
package require http
package require tdom

namespace eval ::pixnet {
	variable Priv
	array set Priv [list \
		timeout 15000 \
		retry 5 \
		albumUrl "pixnet.net/album" \
		debug 0 \
	]
	
	http::config -useragent {Mozilla/5.0 (Windows; U; Windows NT 5.1; zh-TW; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12}
	
}

proc ::pixnet::book_page_count {id {cb ::wretch::pic_get_cb} {p 1}}  {
	variable Priv
	
	set id [string tolower $id]
	
	set url "http://$id.$Priv(albumUrl)"
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
			-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return 0		
	}

	if {$code != 200} {return 0}

	set idx1 [string first "class=\"pageLast\"" $data] 
	
	if { $idx1 == "-1"} {
		return 1
	} else {
		set idx1 [string first ">" $data $idx1]
		set idx2 [string first "<" $data $idx1]
		return [string range $data [expr $idx1+1] [expr $idx2-1]]
	}
	
}

proc ::pixnet::book_page_list {id page {cb ::wretch::pic_get_cb}} {
	variable Priv
	
	if {$id == "人氣相簿"} {return [::pixnet::hot_page_list "thot" $page $cb]}
	if {$id == "精選相簿"} {return [::pixnet::hot_page_list "dhot" $page $cb]}	
	if {$id == "隨機推薦"} {return [::pixnet::hot_page_list "rand" $page $cb]}	
	
	set id [string tolower $id]
	
	set url "http://$id.$Priv(albumUrl)/$page"	

	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7"]
	catch {
		set code 403		
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout)]
		set data [http::data $tok]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}	
	if {$code != 200} {return ""}
	
	set idx1 [string first {<div class="albList">} $data]
	set idx1 [string first "<ul>" $data $idx1]
	set idx2 [string first "</ul>" $data $idx1]
	set data [string range $data $idx1 [expr $idx2 + 4]]
	set data [regsub -all "<><" $data ""]
	set doc [dom parse -html $data]
	set root [$doc documentElement]
	set ret ""

	foreach album [$root selectNode {li}]	{
		set book [[$album selectNode {./div/span/a}] getAttribute href]
		if { [string first "/album/folder" $book] ne "-1"} {
			set folder [lindex [split $book "/"] end]
			set pageNum [::pixnet::book_folder_page_count $id $folder]
			for {set p 1} {$p <= $pageNum} {incr  p} {
				::pixnet::book_folder_list $id $folder $p ret
			}
		} else {
			set book [lindex [split $book "/"] end]
			set thumb [[$album selectNode {./div/span/a/img}] getAttribute src]
			set thumb [lindex [split $thumb "?"] 0]
			set key 0
			set new 0
			foreach span [$album getElementsByTagName "span"] {
				if [$span hasAttribute class] {
					switch [$span getAttribute class] {
						"albTitle" {	set title [encoding convertfrom utf-8  [[$span firstChild] text]] }
						"albPrivate" { set key 1 }
						"albNew" { set new 1 }
						"albNum" { set num "[string range [$span  text] 1 end-1] 張照片" }
					}
				}
			}
			regsub -all {\.}  $title "_" title
			lappend ret [list $id $book $title $num $thumb $new $key]
		}
	}

	$doc delete
	return $ret
}

proc ::pixnet::book_folder_page_count {id folder {cb ::wretch::pic_get_cb} {p 1}}  {
	variable Priv
	
	set id [string tolower $id]
	
	set url "http://$id.$Priv(albumUrl)/folder/$folder"
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
			-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return 0		
	}

	if {$code != 200} {return 0}

	set idx1 [string first "class=\"pageLast\"" $data] 
	if { $idx1 == "-1"} {
		return 1
	} else {
		set idx1 [string first ">" $data $idx1]
		set idx2 [string first "<" $data $idx1]
		return [string range $data [expr $idx1+1] [expr $idx2-1]]
	}
	
}

proc ::pixnet::book_folder_list {id folder page data {cb ::wretch::pic_get_cb}} {
	variable Priv
	
	upvar $data ret
	
	set url "http://$id.$Priv(albumUrl)/folder/$folder/$page"	
	
	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7"]
	catch {
		set code 403		
		set tok [http::geturl $url -headers $headers -timeout $Priv(timeout)]
		set data [http::data $tok]
		set code [http::ncode $tok]
		http::cleanup $tok
	}
	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
		return ""
	}
	
	if {$code != 200} {return ""}

	set idx1 [string first {<div class="albList">} $data]
	set idx1 [string first "<ul>" $data $idx1]
	set idx2 [string first "</ul>" $data $idx1]
	set data [string range $data $idx1 [expr $idx2 + 4]]

	set doc [dom parse -html $data]
	set root [$doc documentElement]

	foreach album [$root selectNode {li}]	{
		set book [[$album selectNode {./div/span/a}] getAttribute href]
		set book [lindex [split $book "/"] end]
		set thumb [[$album selectNode {./div/span/a/img}] getAttribute src]
		set thumb [lindex [split $thumb "?"] 0]
		set key 0
		set new 0
		foreach span [$album getElementsByTagName "span"] {
			if [$span hasAttribute class] {
				switch [$span getAttribute class] {
					"albTitle" {	set title [encoding convertfrom utf-8  [[$span firstChild] text]] }
					"albPrivate" { set key 1 }
					"albNew" { set new 1 }
					"albNum" { set num "[string range [$span  text] 1 end-1] 張照片"}
				}
			}
		}
		regsub -all {\.}  $title "_" title
		lappend ret [list $id $book $title $num $thumb $new $key]
	}

	$doc delete
}

proc ::pixnet::hot_page_list {type page {cb ::pixnet::pic_get_cb}} {
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
				-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
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

proc ::pixnet::debug {msg} {
	variable Priv
	if {$Priv(debug)} {puts $msg}
}

proc ::pixnet::friend_list {id {cb ::wretch::pic_get_cb}} {
	return ""
}

proc ::pixnet::pic_get {url fpath {cb ::pixnet::pic_get_cb}} {
	set url [string tolower $url]
	set url [lindex [split $url "?"] 0]
	set headers [list Pragms no-cache Cache-Control no-cache ]
	
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
			-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
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

proc ::pixnet::pic_check_login {url html passwd} {
	variable Priv
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

	foreach {name value} $meta {
		if {$name eq "Set-Cookie"} {			
			set cookie [lindex [split $value {;}] 0]
			break
		}
	}
	
	set idx1 [string first "checklogin.php" $data]
	set idx2 [string first ">" $data $idx1]
	set api [string range $data $idx1 [expr $idx2-2]]
	
	set idx1 [string first "<form action" $data]
	set idx2 [string first "</form>" $data $idx1]	
	set data [string range $data $idx1 [expr $idx2+6]]
	set data "<html><body>$data</body></html>"

	set doc [dom parse -html $data]

	set root [$doc documentElement]
	set form [$root selectNode {/html/body/form}]
	set stok [[$form selectNode {input[1]}] getAttribute value]
	set b [[$form selectNode {input[3]}] getAttribute value]
	$doc delete
	
	set post [http::formatQuery sToken $stok albumpass $passwd submitpass $b]

	set hdr ""
	lappend hdr \
		Keep-Alive 300 \
		Connection keep-alive \
		Referer $url \
		Accept-Language "zh-tw;q=0.7,en;q=0.3" \
		Accept-Charset "utf-8;q=0.7,*;q=0.7" \
		Cookie $cookie
	
	set tok [http::geturl $url -headers $hdr -query $post]
	
	if {[catch {
		set tok [http::geturl $url -headers $hdr ]
		set data [http::data $tok]
		upvar \#0 $tok state
		set meta $state(meta)
		http::cleanup $tok
	}]} {set data "" ; return}

	if {[string first {class="thumbList"} $data] > 0} {return}
	set data ""
}

proc ::pixnet::pic_get_cb {tok total current} {
	upvar #0 $tok state
	#puts "$total $current"
	return
}
#
#
proc ::pixnet::pic_page_count {id book {passwd ""} {cb ::pixnet::pic_get_cb} {p 1}} {
	variable Priv
	
	set id [string tolower $id]
	
	set url "http://$id.$Priv(albumUrl)/set/$book"
	
	if {$passwd != ""} {
		::pixnet::pic_check_login $url data $passwd
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
				-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"] \
				-type ok \
				-icon info
			return 0
		}	
		if {$code != 200} {return 0}	
	}
	
	set idx1 [string first "class=\"pageLast\"" $data] 
	
	if { $idx1 == "-1"} {
		return 1
	} else {
		set idx1 [string first ">" $data $idx1]
		set idx2 [string first "<" $data $idx1]
		return [string range $data [expr $idx1+1] [expr $idx2-1]]
	}
}

proc ::pixnet::pic_page_list {id book page {passwd ""} {cb ::pixnet::pic_get_cb}} {
	variable Priv
	variable policy
	
	set id [string tolower $id]
	
	set url "http://$id.$Priv(albumUrl)/set/$book/$page"

	if {$passwd != ""} {
		::pixnet::pic_check_login $url data $passwd
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
				-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
				-type ok \
				-icon info
			return ""
		}	
		if {$code != 200} {return ""}	
	}

	set data [string tolower $data]

	if {[string first "passalbmsg" $data] > 0} {return ""}
	if {[string first "<b>empty" $data] > 0} {return ""}
	
	set idx1 [string first {class="thumblist"} $data]
	set idx1 [string first "<ul>" $data $idx1]
	set idx2 [string first "</ul>" $data $idx1]
	set data [string range $data $idx1 [expr $idx2 + 4]]

	set doc [dom parse -html $data]
	set root [$doc documentElement]
	set ret ""

	foreach pic [$root selectNode {li}]	{
		set img [$pic selectNode {./div/span/a/img}]
		set thumb [$img getAttribute src]
		lassign [split $thumb "_"] host fname
		set pid [file root $fname ]
		set fname [string range $fname 0 [expr [string first "?" $fname] - 1]]
		set thumb [string range $thumb 0 [expr [string first "?" $thumb] - 1]]
		set title [encoding convertfrom utf-8 [[$pic selectNode {./div[2]/span}] text]]

		if { [$img hasAttribute "width"] ||  [$img hasAttribute "height"]} {
			set furl "[string range $host 0 end-5]$fname"
			set type "pic"
		} else {
			if {[string first "speaker.jpg" $thumb] != -1} {
				set furl [[$pic selectNode {./div/span/a}] getAttribute href]
				set type "mp3"			
			} else {
				set href [[$pic selectNode {./div/span/a}] getAttribute href]
				if { [::pixnet::pic_check_type $href] eq "flv"} {
					set idx [string first "userpics" $thumb]			
					set furl [string range $thumb [expr $idx + 8] end]
					regsub "thumb_" $furl "" furl
					regsub ".jpg" $furl ".flv" furl
					set type "flv"								
				} else {
					set furl "[string range $host 0 end-5]$fname"			
					set type "pic"				
				}				
			} 	
		}
		lappend ret [list $pid $title $thumb $furl $type]
	}
	$doc delete
	return $ret
	
}

proc ::pixnet::vfriend_list {id {cb ::wretch::pic_get_cb}} {
	return ""
}

proc ::pixnet::video_page_count {id {cb ::wretch::pic_get_cb} {p 1} } {
	variable Priv
	return 0
}	

proc ::pixnet::video_page_list {id page {cb ::wretch::pic_get_cb}} {
	return ""
}

proc ::pixnet::mkurl {type args} {
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

proc ::pixnet::pic_check_type {url {cb ::pixnet::pic_get_cb}} {
	variable Priv
	set headers [list Accept-Language "zh-tw;q=0.7,en;q=0.3" Accept-Charset "utf-8;q=0.7,*;q=0.7" ]
		catch {
			set code 403	
			set tok [http::geturl "$url" -headers $headers -timeout $Priv(timeout) -progress $cb]
			set data [http::data $tok]
			set code [http::ncode $tok]
			http::cleanup $tok
		}

	if {$code == 999} {
		tk_messageBox -title [::msgcat::mc "資訊"] \
			-message  [::msgcat::mc "Pixnet現在不允許您的連線，請稍後再試或使用代理伺服器。"]\
			-type ok \
			-icon info
	}	

	if {$code == 200} {
		set data [string tolower $data]
		if {[string first "embedcode.gif" $data] > 0} {
			return "flv"
		} else {
			return "pic"
		}
	}
}

