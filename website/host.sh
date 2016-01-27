#!/bin/bash
coffee -m -o compiledCoffee/ -cw coffee/ &
~/Documents/google_appengine/dev_appserver.py .. &
#python3 -m http.server &> /dev/null &
