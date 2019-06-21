## purpose of the research
- determine most efficient way to reduce latency of http request for Unity3d mobile app, which contains both API call (small size request body and upto medium size response) and downloading file (none or tiny request body and big size response)

## TL; DR
[suggestion from the research](https://github.com/umegaya/mobile-game-http-latency-test#suggestion-from-the-research)

## approach
- recently grpc is likely to choose when Unity developer wants to reduce API call latency against UnityWebRequest  and work well
  - but in our situation, we need to consider both call API and download file on runtime
  - grpc does not handle efficient file download
- in the research, we verify simple http2 can be used replacement of API call by grpc and file download by UnityWebRequest, from a perspective of request latency. 
  - grpc's efficiency probably comes from efficiency of http2, so expected to show similar performance when it replaced by http2 REST API call 
  - for downloading, Android still seems to use non-http2 request, so at least expected to be better performance for Android
  ```
  UnityWebRequest Android http agent: "Dalvik/2.1.0 (Linux; U; Android 9; Pixel 2 XL Build/PQ3A.190605.003)"
  UnityWebRequest iOS http agent: "lr/0 CFNetwork/978.0.7 Darwin/18.6.0"
  ```

## what we do
- implement efficient http2 implementation for Unity iOS/Android, called [Mhttp](https://github.com/umegaya/mhttp)
  - iOS: as C# binding of [twitter network layer](https://github.com/twitter/ios-twitter-network-layer)
  - Android: as C# binding of [okhttp](https://github.com/square/okhttp)
- setup following infrastructure by terraform, for reproducability
  - L4 load balancer for grpc
  - L7 load balancer for rest API/downloading files
  - container service for running API server / file server
- then comparing performance of rest API call/downloading file with grpc API call/UnityWebRequest DownloadHandlerBuffer against above infrastructure, respectivley. 

## result
- downloading file
  - Mhttp is about 2x faster than UnityWebRequest, both iOS and Android
  - but its not only http2 efficiency but for inefficiency of UnityWebRequest. because iOS [seems to use same network stack (NSURLSession)](https://unity3d.com/jp/unity/beta/2019.1.0b1) as Mhttp
- API call
  - all of Mhttp/grpc/UnityWebRequest, latency of 1st request is significantly slower than rest, rom 50ms to 350ms. 
    - Mhttp does not seem to produce this extra handshake latency when it try to API call after download file (and vise versa). 
  - for iOS, both Mhttp and grpc is always significantly faster than UnityWebRequest. 
  - for Android, only 1st request have noticable difference among Mhttp, grpc, UnityWebRequest (appeared earlier is better). 
  
## suggestion from the research
- use Mhttp for downloding file
- use Mhttp for API call if you can unify domain of API server and file URL (eg. GCP GLB)
  - because it reduces extra handshake for API server after downloading file (or vice versa), in exchange of little slow down (about 10ms) compared with grpc
- use grpc for API call if you cannot do above (eg. AWS ALB)
- bonus: common cloud load balancer supports L7 balancing for http2. OTOH grpc is only supported as L4 balancing
  - I know envoy supports L7 grpc balancing, but without doubt most of Unity game developpers don't want to maintain envoy cluster by themselves (we are always busy for making game fun :P)

## test

### test environment 
- all source code to build env put in the repository
- device 
  - iOS: iPhone Xr simulator with 4G tethering
  - Android: Pixel 2 XL (Android 9)
- client library/tools
  - XCode: 10.2.1
  - Android SDK: API Level 29
  - Android NDK: r20
  - Unity: 2019.1.6f
    - [DownloadHandlerBuffer](https://docs.unity3d.com/ja/current/ScriptReference/Networking.DownloadHandlerBuffer.html) for receiving response with UnityWebRequest
  - [Mhttp](https://github.com/umegaya/mhttp)
    - iOS Twitter Network Layer: 2.6
    - Android okhttp: 3.14.0
    - Android okio: 1.17.4
- infra (see terraform scripts in infra/aws for detail setting)
  - AWS ALB (L7 balancing for rest API server/static file distribution nginx server)
  - AWS NLB (L4 balancing for grpc API server)
  - AWS ECS with host network + daemon scheduling (running servers)
  - EC2 autoscaling group of t3.small
  - S3 for file distribution storage
- server
  - nodejs listen on 80(express) and 50051(grpc) for serving API
  - nginx listen on 8080 for proxy_pass requests to s3 bucket

### test items
- A. comparing performance of grpc/Mhttp with UnityWebRequest against API Call latency
- B. comparing performance of Mhttp with UnityWebRequest against downloading file latency, then comparing performance of Mhttp with grpc with API Call latency (for mixing API call and file downloading)

### test A
1. call API 5 times sequencially with using grpc, Mhttp (http2 implementation) and UnityWebRequest. API just echo back request body which contains client timestamp. 
2. measure request completion time of 1. 5 times

#### iOS (iPhone Xr simulator with tethering)
```
---------- unity API ----------
190|175|215|167|200
292|166|167|167|199
228|667|199|200|167
228|266|166|233|267
201|282|200|234|200

---------- mhttp API ----------
199|67|67|66|67
233|33|67|33|533
198|35|33|66|66
165|67|67|34|66
166|66|67|33|67

---------- grpc API ----------
100|33|67|66|34
133|34|33|34|66
100|33|34|66|66
199|34|32|67|67
100|66|34|33|67
```

- summery (separate 1st and rest)

```
unity API: 1st: 227.8 ms/call, rest: 226.85 ms/call
mhttp API: 1st: 192.2 ms/call, rest: 80 ms/call (56.2 ms/call without 533 ms outlier sample)
grpc API: 1st: 126.4 ms/call, rest: 48.3 ms/call, 
```


#### Android (pixel 2 XL)
```
---------- unity API ----------
524|39|50|50|50
650|55|51|49|50
361|56|49|50|51
507|41|49|50|50
376|56|50|49|51

---------- mhttp API ----------
164|79|33|33|50
163|79|50|33|32
197|95|50|49|50
198|94|50|50|66
196|95|49|50|50

---------- grpc API ----------
617|48|36|32|32
369|30|35|33|34
233|33|52|48|52
284|48|50|52|49
217|51|50|34|49
```

- summery (separate 1st and rest)

```
unity API: 1st: 483.6 ms/call, rest: 49.8 ms/call
mhttp API: 1st: 183.6 ms/call, rest: 56.85 ms/call
grpc API: 1st: 344 ms/call, rest: 42.4 ms/call
```

### observation from test A
- 1st request roundtrip time of each test, is significantly longer than rest. 
  - I think that is because 1st request contains TLS handshake latency (even for http1.1, keep alive seems to be enabled, because source address port is same for multiple request)
- comparing without 1st request latency, 
  - iOS: UnityWebRequest significantly slower than Mhttp/grpc, difference between Mhttp and grpc is hard to be noticed by human, if we ignore one outlier. 
  - Android: difference of each methods are not noticable for human 
- comparing 1st request latency, 
  - iOS: grpc faster than other two methods
  - Android: mhttp > grpc > unity. each gaps are noticable for human


### test B

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

- summery (exclude 1st sample because it seems to contain TLS handshake latency)
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

- summery (exclude 1st sample because it seems to contain TLS handshake latency)
```
mhttp DL: 1278.70 bytes/sec
unity DL: 554.95 bytes/sec

mhttp API: 61.55 ms/call
grpc API: 54.35 ms/call
```


### observation from testB

#### Common
- very first request seems to include tls handshake latency except mhttp API (iOS/Android)
  - probably mhttp uses previous connection for DL as connection for API call
  - because if we change order API call => DL, 1st API call latency was increased and 1st DL latency decrease 
- unity DL (iOS) are likely to be faster than that of mhttp DL (these not put here)
  - UnityWebRequest iOS uses NSURLSession internally, which is same as Mhttp. so probably globaly reuse connection for same domain for making request.

#### iOS
- Mhttp 48% faster than UnityWebRequest
- Mhttp 5ms slower than grpc API call
  - but it seems to be able to save first 50 ~ 150 msec handshake latency

#### Android
- Mhttp 57% faster than UnityWebRequest
- Mhttp 7ms slower than grpc
  - but it seems to be able to save first 150 ~ 350 msec handshake latency


## try on your environment
- following these instruction to build test environment
  1. infra/aws/README.md
  2. server/README.md
  3. client/README.md

