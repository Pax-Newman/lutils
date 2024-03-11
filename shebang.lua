#!/bin/sh
_=[[
# This is a lua script that we can run directly from the command line
# By using this shebang hack we can run arbitrary shell scripts before
# running our lua script!
# Everything inside of this multiline string is a shell script that will
# be run before the lua script is run.

# For example lets run the following lua script through the redbean interpreter

# Install redbean if we don't have it nearby already
if ! test -e ./redbean.com ; then
    echo "redbean.com not found. Installing redbean.com"
    curl https://redbean.dev/redbean-latest.com -o ./redbean.com
    chmod 777 ./redbean.com
fi

# Gather the lua script past this shell script into a temporary file
sed -n '/^----LUA----/,$p' "$0" > .tmp.lua

# Execute this script using redbean
./redbean.com -i .tmp.lua "$@"

# Clean things up
rm .tmp.lua
exit 0
]]
----LUA----

-- Let's test out our shebang hack by running a simple lua script
print(Fetch('https://cheat.sh/lua', {headers = {['User-Agent'] = 'curl/8.4.0'}}))
