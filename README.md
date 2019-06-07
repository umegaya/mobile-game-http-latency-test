### fact
- unity (at least 2018.4) uses http/1.1 for its web request, with libcurl 
```
"UnityPlayer/2018.4.0f1 (UnityWebRequest/1.0, libcurl/7.52.0-DEV)"
```

### test1 
- send sequencial 5 request with http1.1 and grpc
- android
```
06-06 09:12:50.834 30146 30161 I Unity   : --------------- rest ---------------
06-06 09:12:50.836 30146 30161 I Unity   : 328|16|16|17|32
06-06 09:13:15.198 30320 30335 I Unity   : 731|50|49|50|50
06-06 09:13:39.180 30414 30430 I Unity   : 343|50|50|50|50
06-06 09:14:14.931 30532 30548 I Unity   : 366|49|50|50|50
06-06 09:12:51.065 30146 30161 I Unity   : --------------- grpc ---------------
06-06 09:12:51.066 30146 30161 I Unity   : 144|33|16|18|16
06-06 09:13:15.995 30320 30335 I Unity   : 642|50|34|34|32
06-06 09:13:39.524 30414 30430 I Unity   : 207|33|33|33|33
06-06 09:14:15.241 30532 30548 I Unity   : 174|33|34|33|33
```

- using single connection for each request (because it seems to use keep alive and share single conneciton)
  - 2nd ~ request get much faster than first (about 80~90% latency reduction)


### test2
- send concurrent 5 request with http1.1 and grpc
- android
```
06-06 09:16:35.038 30922 30937 I Unity   : --------------- rest ---------------
06-06 09:16:35.040 30922 30937 I Unity   : 531|335|334|334|334
06-06 09:16:57.065 31016 31031 I Unity   : 355|153|152|152|153
06-06 09:17:24.826 31141 31157 I Unity   : 370|155|170|155|169
06-06 09:17:48.682 31279 31295 I Unity   : 448|233|265|250|250
06-06 09:16:35.351 30922 30937 I Unity   : --------------- grpc ---------------
06-06 09:16:57.275 31016 31031 I Unity   : 190|122|122|122|121
06-06 09:16:35.351 30922 30937 I Unity   : 291|222|221|221|220
06-06 09:17:25.037 31141 31157 I Unity   : 191|121|121|120|119
06-06 09:17:48.976 31279 31295 I Unity   : 259|188|188|204|187
```

- using different connection for each request (because keep alive connection can send only 1 request at a time, Unity seems to assign new connection for request to send it right now)
  - but why first request takes longer duration? initialization overhead? 


### test3
- send 1 request, then send 4 concurrent request with http1.1 and grpc
- android
```
--------------- rest ---------------
330|202|49|90|219
--------------- grpc ---------------
208|52|50|50|35
```

- grpc always low latency on concurrent 4 requests
  - once grpc connection established, it always available for request sending, because of multiplexing. 
- rest often contains longer duration for some part of 4 concurrent requests, others are low latency
  - sometimes seems to reuse existing keep alive connection


### insight
- recently, most of bottleneck of mobile communication latency is TLS handshake. 
  - grpc, http1.1(with keepalive), http2 should be no big latency difference once TLS connection established. 
- to reduce the mobile communication latency, following efforts are useful
  - http2/http1.1: using single domain name for all request (including static files), cause request for different domain requires new TLS connection. 
  - http2/grpc: multiplexing request to reduce connection establishment freqency when request concurrency is high.

### conclusion
- we have both high concurrency for API and static file request, http2 should be best choice. 
- if concurrency is not so high, I recommend http 1.1 with single domain
