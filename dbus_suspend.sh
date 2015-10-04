#!/bin/sh
dbus-send --print-reply --dest='org.freedesktop.PowerManagement' /org/freedesktop/PowerManagement org.freedesktop.PowerManagement.Suspend
