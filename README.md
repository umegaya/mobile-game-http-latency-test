## purpose of the research
- determine most efficient way to reduce latency of http request for Unity3d mobile app, which contains both API call (small size request body and upto medium size response) and downloading file (none or tiny request body and big size response)

## approach
- basic idea
  - recently grpc is likely to choose when developer wants to reduce web API invoking latency, and actually its more efficient for API call than rest API with http1.1 
  - but in this research, we focus on the enviornment that mixing API call and downloading file, and grpc does not handle file download. 
  - here is one question. grpc is efficient, but does the efficiency comes from grpc implementation itself, or from http2 spec efficiency? 
  - if efficiency comes from http2 spec, simple http2 should be better solution, because it can support both API call and downloading file in single connection. 
- what we do
  - implement efficient http2 implementation for Unity iOS/Android, called [Mhttp](https://github.com/umegaya/mhttp)
    - iOS: as C# binding of twitter network layer 
    - Android: as C# binding of okhttp
  - setup following infrastructure
    - L4 load balancer for grpc
    - L7 load balancer for rest API/downloading files
  - comparing performance of rest API call/downloading file with grpc API call/UnityWebRequest DownloadHandlerBuffer against above infrastructure, respectivley. 

## result
- for downloading file, Mhttp is about 2x faster than Unity DownloadHandlerBuffer
- for API call, Mhttp is slightly slower than grpc < 10ms/call, but it does not seems to be noticable for usual user.
  - Mhttp does not seem to produce extra handshake latency once it start to request to L7 LB, probably because downloading file/API can be share TLS connection (they have same domain) 

## conclusion
- for downloading file, we should use http2 enable request even for iOS, which also utilize same mechanism of twitter network layer (CFNetwork)
  - Android http agent: ```"UnityPlayer/2018.4.0f1 (UnityWebRequest/1.0, libcurl/7.52.0-DEV)"```
  - iOS http agent: ```"lr/0 CFNetwork/978.0.7 Darwin/18.6.0"```
- for API call, grpc have small advantage even if http2 enabled API call is available. 
  - considering grpc causes extra TLS handshake latency in addition to the handshake for downloading file, initial UX (just launching app and start accessing API/files) may be better than grpc plus extra connection for file downloading
  - but because AWS does not provide efficient way to integrate cloud storage (s3 of AWS) with load balancer target group, combination of grpc and Mhttp is probably best option for **AWS**, OTOH for **GCP**, using Mhttp for both downloding file and API call (both are under unified domain) should be right way. 
  - bonus: common cloud load balancer supports L7 balancing for it. OTOH grpc is only supported as L4 balancing
    - I know envoy supports L7 grpc balancing, but without doubt most of Unity game developpers don't want to maintain envoy cluster by themselves (we are always busy for making game fun :P)

## test

#### test environment 
- device 
  - iOS: iPhone Xr simulator with 4G tethering
  - Android: Pixel 2 XL (Android 9)
- client library/tools
  - XCode: 10.2.1
  - Android SDK: API Level 29
  - Android NDK: r20
  - Unity: 2019.1.6f
  - iOS Twitter Network Layer: 2.6
  - okhttp: 3.14.0
  - okio: 1.17.4
- infra (see terraform scripts in infra/aws for detail setting)
  - AWS ALB (L7 balancing for rest API server/static file distribution nginx server)
  - AWS NLB (L4 balancing for grpc API server)
  - AWS ECS with host network + daemon scheduling (running servers)
  - EC2 autoscaling group of t3.small
  - S3 for file distribution storage

#### test items

1. download 5 files sequencially with using UnityWebRequest and Mhttp
```
-rw-r--r--@ 1 iyatomi  staff  241776  6 19 17:20 capitol-2212102_1280.jpg
-rw-r--r--@ 1 iyatomi  staff  276101  6 19 17:20 hanoi-4176310_1280.jpg
-rw-r--r--@ 1 iyatomi  staff  465284  6 19 17:18 jordan-1846284_1280.jpg
-rw-r--r--@ 1 iyatomi  staff  455135  6 19 17:21 mirror-house-4278611_1280.jpg
-rw-r--r--@ 1 iyatomi  staff  163763  6 19 17:20 sunset-4274662_1280.jpg
```

2. then call API 5 times sequencially with using grpc and Mhttp

3. measure request completion time of 1. and 2. 5 times, under unstable network environment (eg. in the moving train)


#### iOS (iPhone Xr simulator with tethering)

- raw data
```
---------- mhttp DL ---------- 
1174|1466|400|700|667
1172|1067|333|633|801
752|734|299|401|633
781|600|1234|1333|600
1188|631|335|799|934

---------- unity DL ---------- 
665|1067|667|900|1333
999|1533|733|867|1533
632|1067|533|732|1000
765|1767|900|1067|1467
798|1301|2099|1567|1600

---------- mhttp API ---------- 
88|99|67|67|67
90|66|101|100|66
56|67|65|68|66
89|100|66|68|99
90|134|100|100|66

---------- grpc API ---------- 
233|100|66|67|101
199|67|101|67|66
200|100|66|67|67
168|66|66|67|66
233|67|67|99|100

```

- summry (exclude 1st sample because it may contain TLS handshake latency)
```
mhttp DL: 465.85 bytes/sec
unity DL: 286.58 bytes/sec

mhttp API: 81.6 ms/call
grpc API: 76.65 ms/call
```

#### Android (pixel 2 XL)

- raw data
```
---------- mhttp DL ---------- 
817|277|284|266|450
453|146|167|166|183
279|325|467|668|481
398|179|183|133|166
307|162|166|200|250

---------- unity DL ---------- 
4310|3221|417|549|632
833|779|266|401|631
3332|1311|332|515|1064
783|513|231|167|316
716|282|183|214|232

---------- mhttp API ---------- 
153|53|101|68|101
87|73|51|68|65
104|54|34|50|50
89|57|67|83|65
85|57|34|49|51

---------- grpc API ---------- 
515|64|100|66|50
298|67|49|32|49
314|49|68|49|66
251|32|49|50|51
333|49|48|50|49

```

- summry (exclude 1st sample because it may contain TLS handshake latency)
```
mhttp DL: 1278.70 bytes/sec
unity DL: 554.95 bytes/sec

mhttp API: 61.55 ms/call
grpc API: 54.35 ms/call
```


## observation

#### Common
- very first request seems to include tls handshake latency except mhttp API (iOS/Android) and unity DL (iOS) test
- I think this is because:
  - mhttp API already finished its handshake on mhttp DL test
  - unity DL (iOS) uses CFNetwork internally, which is same as Mhttp. and CFNetwork probably globally reuse connection for same domain for making request.

#### iOS
- pure http2 48% faster than unity DownloadHandlerBuffer
- pure http2 5ms slower than grpc API call
  - but it seems to be able to save first 50 ~ 150 msec handshake latency

#### Android
- pure http2 57% faster than unity DownloadHandlerBuffer
- pure http2 7ms slower than grpc
  - but it seems to be able to save first 150 ~ 350 msec handshake latency


## try latency-research systrem
- every resources to do additional exmaination should be in this repo, including infra/client/server. 
- following these instruction
  1. infra/aws/README.md
  2. server/README.md
  3. client/README.md