package provide smtp 1.0
package require tls
package require base64
package require mime

namespace eval ::smtp {
	variable Priv
	array set Priv [list sn 0 debug 0]
	
	variable Sessions
	array set Sessions ""
}

proc ::smtp::cmd_auth {tok} {
	variable Priv
	variable Sessions
	
	set sck $Sessions($tok,sck)
	
	lassign [$tok cmd "AUTH LOGIN"] state code msg
	if {$code != 334} {return 0}
	lassign [$tok cmd [::base64::encode $Sessions($tok,username)]] state code msg
	if {$code != 334} {return 0}
	lassign [$tok cmd [::base64::encode $Sessions($tok,password)]] state code msg
	if {$code != 235} {return 0}	
	return 1
}

proc ::smtp::cmd_cmd {tok msg {cb ""} {cbSize 4096}} {
	variable Priv
	variable Sessions
	set sck $Sessions($tok,sck)
	debug "Send : $msg"
	chan puts $sck $msg
	chan flush $sck
	
	return [$tok wait_ret $cb]
}


proc ::smtp::cmd_disconnect {tok} {
	variable Priv
	variable Sessions
	$tok quit
	catch {close $Sessions($tok,sck)}
	interp alias {} $tok {} {}
	array unset Sessions $tok,*
	return
}

proc ::smtp::cmd_helo {tok} {
	variable Priv
	variable Sessions
	
	set host [info hostname]
	lassign [$tok cmd "HELO $host"] state code msg
	if {$code == 250} {return 1}
	return 0
}

proc ::smtp::cmd_send {tok subject from to message {cb ""}} {
	variable Sessions
	
	set sck $Sessions($tok,sck)
	
	if {[$tok helo] == 0} {return 0}
	if {$Sessions($tok,tls)} {if {[$tok starttls] == 0} {return 0}}
	if {[$tok auth] == 0} {return 0}
	
	lassign [$tok cmd "MAIL FROM: <$from>"] state code msg
	if {$code != 250} {return 0}
	lassign [$tok cmd "RCPT TO: <$to>"] state code msg
	if {$code != 250} {return 0}
	lassign [$tok cmd "DATA"] state code msg
	if {$code != 354} {return 0}
	chan puts $sck "From: $Sessions($tok,username) <$from>"
	chan puts $sck "To: $Sessions($tok,username) <$to>"
	chan puts $sck "Subject: $subject"
	if {$cb == ""} {
		::mime::copymessage $message $sck
	} else {
		set data [::mime::buildmessage $message]
		set len [string length $data]
		set cut [expr $len/4096]
		if {$len % 4096} {incr cut}
		set total 0
		for {set i 0} {$i < $cut} {incr i} {
			set buf [string range $data [expr $i*4096] [expr $i*4096+4095]]
			incr total [string length $buf]
			chan puts -nonewline $sck $buf
			chan flush $sck
			eval [linsert $cb end $len $total]
		}
		
	}
	chan puts -nonewline $sck "\r\n.\r\n"

	lassign [$tok wait_ret $cb] state code msg
	if {$code != 250} {return 0}
	return 1
}

proc ::smtp::cmd_quit {tok} {
	variable Priv
	variable Sessions
	lassign [$tok cmd "QUIT"] state code msg
	if {$state != "OK" } {return 0}
	return 1
}

proc ::smtp::cmd_starttls {tok} {
	variable Priv
	variable Sessions
	
	set sck $Sessions($tok,sck)
	
	lassign [$tok cmd "STARTTLS"] state code msg
	if {$code != 220} {return 0}
	if {[catch {
		tls::import $sck
		chan configure $sck -buffering none -encoding binary -blocking 1
		tls::handshake $sck
	}]} {return 0}
	chan configure $sck -blocking 1 -encoding binary -translation {auto lf}  -buffering none
	if {[$tok helo] ==  0} {return 0}
	return 1	
}

proc ::smtp::cmd_response {tok key} {
	variable Priv
	variable Sessions
	return $Sessions($tok,$key)
}

proc ::smtp::cmd_wait_ret {tok {cb ""} {cbSize 4096} {tout 5000}} {
	variable Priv
	variable Sessions
	
	set sck $Sessions($tok,sck)
	
	set buf ""
	set state "BAD"
	set ret ""
	set code ""
	while {[set cut [chan gets $sck buf]] >= 0} {
		set state "OK"
		append ret $buf "\n"
		set code [string range $buf 0 2]
		if {[string index $buf 3] == " " } {break}
	}
	set ret [string trimright $ret]
	
	::smtp::debug $ret

	return [list $state $code $ret]
}

proc ::smtp::connect {server port username password args} {
	variable Priv
	variable Sessions

	array set opts [list \
			-server $server \
			-port $port \
			-command "" \
			-tls 0 \
	]
	array set opts $args

	set tok ::smtp::$Priv(sn)
	interp alias {} $tok {} ::smtp::dispatch $tok	 	
	incr Priv(sn)	
	
    if {[catch {set sck [socket $opts(-server) $opts(-port)]}]} {
		$tok disconnect
		return ""
	 }
    chan configure $sck -blocking 1 -encoding binary -translation {auto lf} -buffering none
	 
	set Sessions($tok,username) $username
	set Sessions($tok,password) $password
	set Sessions($tok,server) $opts(-server)
	set Sessions($tok,port) $opts(-port)
	set Sessions($tok,command) $opts(-command)	 
	set Sessions($tok,sck) $sck
	set Sessions($tok,tls) $opts(-tls)
	lassign [$tok wait_ret] state code ret
	return $tok
}

proc ::smtp::debug {msg {newline 1}} {
	if {$newline} {
		if {$::smtp::Priv(debug)} {puts $msg}
	} else {
		if {$::smtp::Priv(debug)} {puts -nonewline $msg}
	}
}

proc ::smtp::dispatch {tok args} {
	variable Priv
	set cmd [list ::smtp::cmd_[lindex $args 0] $tok]
	foreach arg [lrange $args 1 end] {lappend cmd $arg}
	return [eval $cmd]
}

#test
#set user "dai.gdisk.1"
#set passwd "1qaz1qaz"
#set server "smtp.gmail.com"
#set port "25"
#set tok [::smtp::connect $server $port $user $passwd -tls 1]
#tok helo
#tok starttls
#tok auth
#$tok login
#$tok send "mail from dai" "dai.gdisk.1@gmail.com" "dai.gdisk.1@gmail.com" "dsfsdafjflsdfjsadlka"
#$tok disconnect
#exit
