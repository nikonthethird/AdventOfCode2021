#! /bin/bash

path=`realpath input.txt | sed 's/\//\\\\\//g'`
sed "s/'input\.txt'/\'$path'/" main.sql | sqlite3