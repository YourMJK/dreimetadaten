#!/bin/bash

if [ $# -ge 1 ]
then
	case $1 in
		serie)
			json="Serie.json"
			web="index.html"
			;;
		
		spezial)
			json="Spezial.json"
			web="spezial.html"
			;;
		
		kurzgeschichten)
			json="Kurzgeschichten.json"
			web="kurzgeschichten.html"
			;;
		
		die_dr3i)
			json="DiE_DR3i.json"
			web="die_dr3i.html"
			;;
			
		*)
			echo "Invalid argument \"$1\""
			exit 1
			;;
	esac
	
	cd $(dirname "$0")
	bin/D3F-WebGenerator -c metadata/json/"$json" -o "$1" -i web_templates/"$web" > web/"$web"
else
	echo "Usage:  $(basename "$0") (serie | spezial | kurzgeschichten | die_dr3i)"
	exit 1
fi
