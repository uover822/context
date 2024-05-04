:
pid=`curl -s --cookie-jar cj.txt -X POST 'http://192.168.1.3:8000/login' -d 'username=john&password=password' -c - | curl -s -b @- -X POST -H 'Content-Type: application/json' 'http://192.168.1.3:8000/api/metaroot.rcv' -d '{}' | jq -r '.id'`
curl -s -X POST -H 'Content-Type: application/json' 'http://192.168.1.3:4567/iot' --data-urlencode "{\"value\":\"${pid}_[when]{this} precedes {that}=c+rndm+_describes.{this}() c+rndm+_precedes.{that}() \n\
[when]{this} before {that}=c+rndm+_describes.{that}() c+rndm+_describes.{this}(before == '{that}') \n\
[then]it's {adj}!;=insert(new javassist.ClassPool(true).makeClass('c+rndm+_describes.{adj}').toClass().getConstructor().newInstance()); sse.Push.main('+this.id+_describes|r|{adj}!|d');|dsl|dsl|n|\
if this precedes that then it\'s neat!|drl|drl|n|test2|p|that|a|before|n|this|d|that|d|precedes|sr\"}"
