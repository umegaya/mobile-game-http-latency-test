### fact
- unity (at least 2018.4) uses http/1.1 for its web request, with libcurl 
```
"UnityPlayer/2018.4.0f1 (UnityWebRequest/1.0, libcurl/7.52.0-DEV)"
```

### test1 
- send sequencial 5 request with http1.1 and grpc
  - for establishment of first request, no major difference between http 1.1 and 2
    - android 4G: 400 ~ 700 ms

  - TLS handshake takes 300 ~ 600 ms
    - continuous request only takes around 50ms (not so bad as raw 4G latency to lb of aws ap-northeast-1 DC)

### test2
- send concurrent 5 request with http1.1 and grpc


### test3
- send concurrent API and static file request with http1.1 and grpc


### insight
- recently, most of bottleneck of mobile communication latency is TLS handshake. 
  - grpc, http1.1(with keepalive), http2 should be no big latency difference once TLS connection established. 
- to reduce the mobile communication latency, following efforts are useful
  - http2/http1.1: using single domain name for all request (including static files), cause request for different domain requires new TLS connection. 
  - http2/grpc: multiplexing request to reduce connection establishment freqency when request concurrency is high.

### conclusion
- we have both high concurrency for API and static file request, http2 should be best choice. 
- if concurrency is not so high, I recommend http 1.1 with single domain
