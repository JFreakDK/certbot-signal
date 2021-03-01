#!/bin/bash

scriptDir=$( cd "$(dirname "$0")" ; pwd -P )
scriptPath="${scriptDir}/$(basename "$0")"

function usage {
cat << EndOfUsage

Usage: ./certbot-signal.sh [OPTIONS..]

Required options:

  -u/--user	    Email address for important account notifications

  -d/--domain	  Comma-separated list of domains to obtain a certificate for

  -s/--sender	  Signal username

  -r/--receiver	Signal recipient

EndOfUsage
}

# Parse command line arguments
while [[ $# > 0 ]]; do
  key="$1"

  case $key in
    -h|--help)
    usage
    exit 0
    ;;
    -u|--user)
    EMAIL="$2"
    shift # past argument
    ;;
    -d|--domain)
    DOMAIN="$2"
    shift # past argument
    ;;
    -s|--sender)
    SENDER="$2"
    shift # past argument
    ;;
    -r|--receiver)
    RECEIVER="$2"
    shift # past argument
    ;;
    *)
      # unknown option
      echo "Unknown option: $key" >&2
      usage >&2
      exit 1
    ;;
  esac
  shift # past argument or value
done

function validateArg {
  if [ -z "$1" ]; then
    echo "Missing argument: $2" >&2
    usage >&2
    exit 2
  fi
  if [ -z "$3" ]; then
    echo "$2" = "$1"
  fi
}

validateArg "$EMAIL" "user"
validateArg "$DOMAIN" "domain"
validateArg "$SENDER" "sender"
validateArg "$RECEIVER" "receiver"

# Done parsing/validating arguments
# Time to submit the request

CURRENT_TIME=$(date "+%Y.%m.%d-%H.%M.%S")
FILENAME="signal-msg.$CURRENT_TIME"
certbot certonly --webroot --webroot-path /var/www/html --domains $DOMAIN -m $EMAIL --renew-by-default --text --non-interactive | tee /tmp/$FILENAME
cat /tmp/$FILENAME | /usr/local/bin/signal-cli -u $SENDER send $RECEIVER >> /var/log/signal-cli.log
rm /tmp/$FILENAME
/usr/local/bin/signal-cli -u $SENDER receive >> /var/log/signal-cli.log
/usr/sbin/service lighttpd restart
