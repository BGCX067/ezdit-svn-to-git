#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}
set appPath [file normalize [info script]]
if {[file type $appPath] eq "link"} {set appPath [file readlink $appPath]}
set appPath [file dirname $appPath]

source -encoding utf-8 [file join $appPath dApp.tcl] 
