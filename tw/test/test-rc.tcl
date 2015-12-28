#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

lappend ::auto_path ../

package require ::tw::rc

set rc	[::tw::rc new a.rc]

puts exists=[$rc exists Files]
puts gets=[$rc get Files]

$rc set Files "a.txt aecf" 
# a.txt

$rc append Files "append.txt dec"

puts exists=[$rc exists Files]
puts gets=[$rc get Files]

$rc append Dirs "dir1" "dir2"
puts names=[$rc names]

$rc delete Files
puts exists=[$rc exists Files]
puts gets=[$rc get Files]

$rc destroy

file delete a.rc
