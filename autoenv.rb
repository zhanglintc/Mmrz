#!/env/bin/ruby
# encoding: utf-8

BAT_STR = '
@echo off

set SSL_CERT_FILE=%cd%\cacert.pem

echo 1. change download server:
cmd /c gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/

echo=
echo 2. install sqlite3:
cmd /c gem install sqlite3

echo=
echo Result: environment for Mmrz is OK
echo Please close this window...
pause>nul

exit
'

CMD_FILE = "autoenv.cmd"

fw = open CMD_FILE, "wb"
fw.write BAT_STR
fw.close

`start #{CMD_FILE}`
`del #{CMD_FILE}`