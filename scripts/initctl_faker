#!/bin/sh

case "$1" in
    list )
        exec service --status-all
        ;;
    reload-configuration )
        exec service $2 restart
        ;;
    start|stop|restart|reload|status)
        exec service $2 $1 
        ;;
    \?)
        exit 0
        ;;
esac
