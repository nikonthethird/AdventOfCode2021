#! /bin/bash

if [ ! -f saxon-he-10.6.jar ]; then
    echo "You have to download Saxon manually. Check build.sh for the expected file name."
    exit
fi

java -jar saxon-he-10.6.jar -s:input.xml -xsl:main.xsl -o:out.txt