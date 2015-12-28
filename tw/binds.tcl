#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

event add <<ButtonL-Click>> <Button-1>
event add <<ButtonL-Release>> <ButtonRelease-1>
