:
pid=`curl -s --cookie-jar cj.txt -X POST 'http://192.168.1.3:8000/login' -d 'username=john&password=password' -c - | curl -s -b @- -X POST -H 'Content-Type: application/json' 'http://192.168.1.3:8000/api/metaroot.rcv' -d '{}' | jq -r '.id'`
curl -s -X POST -H 'Content-Type: application/json' 'http://192.168.1.3:4567/iot' --data-urlencode "{\"value\":\"${pid}_[when]I\'m eating a hot fudge sundae topped with almonds and a cherry on top=c+rndm+_eating.sundae(flavor == 'hot_fudge') \nc+rndm+_topped_with.nuts(type == 'almonds') \nc+rndm+_on_top.cherry(type == 'maraschino') \n\
[then]life is good;=insert(new javassist.ClassPool(true).makeClass('c+rndm+_life_is_good').toClass().getConstructor().newInstance()); sse.Push.main('+this.id+_is|r|good|a|quality|n|life|d');|dsl|dsl|n|\
if I\'m eating a hot fudge sundae topped with almonds and a cherry on top then life is good|drl|drl|n|\
atest|p|eating|r|hot_fudge|a|flavor|n|[when]I\'m having ice cream=c+rndm+_having.icecream() \n\
[then]I\'m eating a hot fudge sundae;=insert(new javassist.ClassPool(true).makeClass('c+rndm+_eating_a_hot_fudge_sundae').toClass().getConstructor().newInstance()); sse.Push.main('+this.id+_eating|r|hot_fudge|a|flavor|n|sundae|d');|dsl|dsl|n|\
if I\'m having ice cream then I\'m eating a hot fudge sundae|drl|drl|n|\
sundae|p|on_top|r|maraschino|a|type|n|cherry|d|topped_with|r|almonds|a|type|n|nuts|d|\
having|r|icecream|d\"}"
