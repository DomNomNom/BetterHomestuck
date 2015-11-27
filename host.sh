#!/bin/bash
coffee -m -o compiledCoffee/ -cw coffee/ &
python3 -m http.server &> /dev/null &
