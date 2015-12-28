package provide imap 1.0
package require tls

namespace eval ::imap {
	variable Priv
	array set Priv [list sn 0 debug 0]
	
	variable Sessions
	array set Sessions ""
}

proc ::imap::cmd_cmd {tok msg {cb ""} {cbSize 4096}} {
	variable Priv
	variable Sessions
	if {$Sessions($tok,sn) == "*"} {set Sessions($tok,sn) 0}
	incr Sessions($tok,sn)
	set sck $Sessions($tok,sck)
	debug "Send : $Sessions($tok,sn) $msg"
	chan puts $sck "$Sessions($tok,sn) $msg"
	chan flush $sck
	
	return [$tok wait_ret $cb]
}

proc ::imap::cmd_copy {tok range mbox} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "COPY $range $mbox"] sn state msg
	if {$state != "OK" } {return 0}
	return 1	
}

proc ::imap::cmd_create {tok mbox} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "CREATE $mbox"] sn state msg
	if {$state != "OK" } {return 0}
	return 1
}

proc ::imap::cmd_delete {tok mbox} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "DELETE $mbox"] sn state msg
	if {$state != "OK" } {return 0}
	return 1
}

proc ::imap::cmd_fetch {tok query {cb ""} {cbSize 4096}} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "FETCH $query" $cb] sn state msg
	if {$state != "OK" } {return 0}
	set Sessions($tok,data) $msg
	return 1
}

proc ::imap::cmd_disconnect {tok} {
	variable Priv
	variable Sessions
	$tok logout
	catch {close $Sessions($tok,sck)}
	interp alias {} $tok {} {}
	array unset Sessions $tok,*
	return
}

proc ::imap::cmd_list {tok ref mbox} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "LIST \"$ref\" \"$mbox\""] sn state msg
	if {$state != "OK" } {return 0}
	return 1
}

proc ::imap::cmd_login {tok} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "LOGIN $Sessions($tok,username) $Sessions($tok,password)"] sn state msg
	if {$state != "OK" } {return 0}
	return 1
}

proc ::imap::cmd_logout {tok} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "LOGOUT"] sn state msg
	if {$state != "OK" } {return 0}
	return 1
}

proc ::imap::cmd_response {tok key} {
	variable Priv
	variable Sessions
	return $Sessions($tok,$key)
}

proc ::imap::cmd_search {tok query} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "SEARCH $query"] sn state msg
	if {$state != "OK" } {return 0}
	set msg [string trim [lindex [split $msg "\n"] 0]]
	set Sessions($tok,data) [string trim [lrange $msg 2 end]]
	return 1
}

proc ::imap::cmd_select {tok mbox} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "SELECT $mbox"] sn state msg
	if {$state != "OK" } {return 0}
	return 1
}

proc ::imap::cmd_store {tok query} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "STORE $query"] sn state msg
	if {$state != "OK" } {return 0}
	return 1	
}


proc ::imap::cmd_uid {tok query} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "UID $query"] sn state msg
	if {$state != "OK" } {return 0}
	return 1	
}

proc ::imap::cmd_wait_ret {tok {cb ""} {cbSize 4096} {tout 5000}} {
	variable Priv
	variable Sessions
	
	set sck $Sessions($tok,sck)
	set sn $Sessions($tok,sn)
	set Session($tok,data) ""
	
	set state "BAD"
	
	set total 0
	set len 0
	set buf ""
	set ret ""
	
	#set t1 [clock milliseconds]
	#set t2 $t1
	
	while {[set cut [chan gets $sck buf]] >= 0} {
		incr cut 2
		incr total $cut
		incr len $cut
		append ret $buf "\r\n"
		debug "Recv : $buf"
		lassign $buf sn state
		if {$cb != "" && $len >= $cbSize} {
			set cmd $cb
			eval [lappend cmd $total]
			set len 0
			update
		}
		if {$sn == $Sessions($tok,sn)} {break}
	}

	if {$cb != ""} {
		set cmd $cb
		eval [lappend cmd $total]
		set len 0
		update
	}	
	return [list $sn $state $ret]
}

proc ::imap::connect {server port username password args} {
	variable Priv
	variable Sessions
	
	array set opts [list \
			-server $server \
			-port $port \
			-command "" \
			-tls 0 \
	]
	array set opts $args

	set tok ::imap::$Priv(sn)
	interp alias {} $tok {} ::imap::dispatch $tok	 	
	incr Priv(sn)	
	
	set sckcmd "socket"
	if {$opts(-tls) == 1} {set sckcmd "tls::socket"}
	
    if {[catch {set sck [$sckcmd $opts(-server) $opts(-port) ]}]} {
		$tok disconnect
		return ""
	 }
    chan configure $sck -blocking 1 -encoding binary -translation crlf
	 
	set Sessions($tok,username) $username
	set Sessions($tok,password) $password
	set Sessions($tok,server) $opts(-server)
	set Sessions($tok,port) $opts(-port)
	set Sessions($tok,command) $opts(-command)	 
	set Sessions($tok,sck) $sck
	set Sessions($tok,sn) *
	lassign [$tok wait_ret] sn state ret
	if {$state != "OK"} {$tok disconnect ; return ""}
	if {![$tok login]} {$tok disconnect ; return ""}	
	return $tok
}

proc ::imap::debug {msg {newline 1}} {
	if {$newline} {
		if {$::imap::Priv(debug)} {puts $msg}
	} else {
		if {$::imap::Priv(debug)} {puts -nonewline $msg}
	}
}

proc ::imap::dispatch {tok args} {
	variable Priv
	set cmd [list ::imap::cmd_[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]
}

#test
#set user "dai.gdisk.1"
#set passwd "1qaz1qaz"
# [Gmail]/&V4NXPmh2-
#set tok [::imap::connect  "imap.gmail.com" "993" $user $passwd  -tls 1]
#$tok login
#$tok delete {[Gmail]/&V4NXPmh2-}
#$tok select GDisk2
#$tok delete GFS-pool
#$tok delete GFS-Trash
#$tok create GDisk
#$tok create GTrash
#$tok select "INBOX"
#if {[$tok search "SUBJECT GFS::ac590604-01c6-4169-51c8-59b8e731b17d"]} {
#	set ret [$tok response data]
#	$tok fetch [format {%s (UID BODY[TEXT])} $ret]
#	package require base64
#	set data [$tok response data]
#	set idx1 [string first "base64" $data]
#	if {$idx1 == -1} {set idx1 [string first BASE64 $data]}
#	set idx1 [string first "\r\n\r\n" $data $idx1]
#	set idx2 [string first "\r\n\r\n" $data [expr $idx1 + 4]]
#	set data [string range $data $idx1 $idx2]
#	set fd [open ~/tmp/a.txt w]
#	chan configure $fd -encoding binary -translation binary
#	puts $fd [::base64::decode $data]
#	close $fd	
#}
#$tok fetch {1:1 (UID BODY[TEXT])}

#set fd [open a.txt w]
#puts $fd [$tok response data]
#close $fd
#$tok store "1:2 +flags \\Seen"
#$tok store "1:2 +flags \\Deleted"
#$tok copy 1:2 {[Gmail]/&V4NXPmh2-}
#$tok select GFS-pool
#$tok list "" "*"
#$tok disconnect
#exit
