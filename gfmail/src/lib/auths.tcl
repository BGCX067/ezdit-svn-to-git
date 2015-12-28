#!/bin/sh
# -*- tcl -*-
# The next line is executed by /bin/sh, but not tcl \
exec tclsh "$0" ${1+"$@"}

#				proc ::cbfun {max curr} {
#					set ::T2 [clock milliseconds]
#					if {$::T2-$::T1 < 250} {return}
#					
#					set speed [expr ($curr-$::SIZE)/(($::T2-$::T1)/1000.0)]
#					if {$speed <= 0} {return}
#					set util "B"
#					if {$speed > 1024} {
#						set speed [expr $speed/1024.0]
#						set util "KB"
#						if {$speed > 1024} {
#							set speed [expr $speed/1024.0]
#							set util "MB"
#						}
#					}
#					foreach {v1 v2} [split $speed "."] {break}
#					set speed $v1.[string index $v2 0]					
#					set speed "$speed $util"
#					
#					set percent [expr $curr.0/$max*100]
#					foreach {v1 v2} [split $percent  "."] {break}
#					set percent $v1.[string index $v2 0]%%			
#					
#					set remainT [expr int((($::T2-$::T0)*($max.0/$curr -1 )) /1000) + 1]
#					set s [clock add [clock scan "0000-00-00 00:00:00"] $remainT seconds]
#					set remainT [clock format $s -format "%%H:%%M:%%S"]
#
#					set util "B"
#					set size $curr
#					if {$size > 1024} {
#						set size [expr $size/1024.0]
#						set util "KB"
#						if {$size > 1024} {
#							set size [expr $size/1024.0]
#							set util "MB"
#						}
#						foreach {v1 v2} [split $size "."] {break}
#						set size $v1.[string index $v2 0]
#					}
#					set size "$size $util"
#	
#					set tid [::thread::id]
#					::thread::send -async $::parentTID [format {
#						set cb [list %s]
#						eval [lappend cb "%%s" "%%s" "%%s" "%%s" "%%s" "%%s" "%%s"]
#						
#					} $tid $max $curr $speed $percent $size $remainT]
#					set ::T1 $::T2
#					set ::SIZE $curr
#				}
#				set ret 0
#				set ::T0 [clock milliseconds]
#				set ::T1 $::T0
#				set ::T2 $::T0
#				set ::SIZE 0
#				if {[catch {set ret [::start]}]} {set ret 0}
#				::thread::send -async $::parentTID [list ::gvfs::task_finish_cb [::thread::id] $ret]
#				::thread::exit
#		}

	


			INSERT INTO gdisk VALUES(
				NULL,
				"gDisk-1",
				"dai.gdisk.1@gmail.com",
				"1qaz1qaz",
				"smtp.gmail.com",
				"25",
				"imap.gmail.com",
				"993",
				"1",
				""
			);
			INSERT INTO gdisk VALUES(
				NULL,
				"gDisk-2",
				"dai.gdisk.2@gmail.com",
				"1qaz1qaz",
				"smtp.gmail.com",
				"25",
				"imap.gmail.com",
				"993",
				"0",
				""
			);
			INSERT INTO gdisk VALUES(
				NULL,
				"gDisk-3",
				"dai.gdisk.3@gmail.com",
				"1qaz1qaz",
				"smtp.gmail.com",
				"25",
				"imap.gmail.com",
				"993",
				"0",
				""
			);	
