#!/bin/bash
# Check availability of license plate on California DMV website
# Usage: platecheck.sh <plate text>
#
# Copyright James Morle, 2016
#

instr=`echo $1 | tr [:lower:] [:upper:]`

COOKIES_PATH=./cookie
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"

req=`echo $instr | awk ' {for (i=0;i<7;i++) { if (i!=0) {printf "&"} if (i>=length($1)) chr="*"; else chr=substr($1,i+1,1); printf "plateChar%d=%s",i,chr; } }'`

rm $COOKIES_PATH.txt 2>/dev/null

curl \
    --silent \
    --location \
    --user-agent "$USER_AGENT" \
    --cookie-jar "$COOKIES_PATH.txt" \
	https://www.dmv.ca.gov/portal/dmv > /dev/null 2>&1
curl \
	--silent \
    --location \
    --user-agent "$USER_AGENT" \
    --cookie "$COOKIES_PATH.txt" \
    --cookie-jar "$COOKIES_PATH.txt" \
'https://www.dmv.ca.gov/portal/dmv/detail/portal/ipp2/welcome' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://www.dmv.ca.gov/portal/dmv/dmv/onlinesvcs/specialinterestplates' -H 'Connection: keep-alive' --compressed > /dev/null 2>&1

curl \
	--silent \
    --location \
    --user-agent "$USER_AGENT" \
    --cookie "$COOKIES_PATH.txt" \
    --cookie-jar "$COOKIES_PATH.txt" \
'https://www.dmv.ca.gov/wasapp/ipp2/initPers.do' -H 'Accept-Encoding: gzip, deflate, sdch, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Referer: https://www.dmv.ca.gov/portal/dmv/detail/portal/ipp2/welcome' -H 'Connection: keep-alive' --compressed > /dev/null 2>&1

curl \
	--silent \
    --location \
    --user-agent "$USER_AGENT" \
    --cookie "$COOKIES_PATH.txt" \
    --cookie-jar "$COOKIES_PATH.txt" \
'https://www.dmv.ca.gov/wasapp/ipp2/processPers.do' -H 'Origin: https://www.dmv.ca.gov' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://www.dmv.ca.gov/wasapp/ipp2/initPers.do' -H 'Connection: keep-alive' --data 'imageSelected=platePetLoversPers.jpg&vehicleType=AUTO&isVehLeased=no&plateType=Z' --compressed > /dev/null 2>&1

curl 'https://www.dmv.ca.gov/wasapp/ipp2/processConfigPlate.do' \
	--silent \
    --location \
    --user-agent "$USER_AGENT" \
    --cookie "$COOKIES_PATH.txt" \
    --cookie-jar "$COOKIES_PATH.txt" \
-H 'Origin: https://www.dmv.ca.gov' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.8' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Referer: https://www.dmv.ca.gov/wasapp/ipp2/processPers.do' -H 'Connection: keep-alive' --data "kidsPlate=&plateType=Z&plateLength=7&${req}" --compressed 2>/dev/null > resp.$$

rm $COOKIES_PATH.txt

grep '<p class="alert">Sorry, the plate you have requested is not available' resp.$$ >/dev/null

if [ $? -eq 0 ]
then
	echo "Not available"
	rm resp.$$
	exit 2
fi
grep '<h3>Step 3: Complete Order Form</h3>' resp.$$ > /dev/null
if [ $? -eq 0 ]
then
	echo "Available!"
	rm resp.$$
	exit 0
fi
echo "unknown response, check resp.$$"
