####

- unity (at least 2018.4) uses http/1.1 for its web request, with libcurl 
```
"UnityPlayer/2018.4.0f1 (UnityWebRequest/1.0, libcurl/7.52.0-DEV)"
```

- for establishment of first request, no major difference between http 1.1 and 2
  - android 4G: 400 ~ 500 ms

- TLS handshake takes 300 ~ 400 ms
  - continuous request only takes around 50ms (not so bad as raw 4G latency to lb of aws ap-northeast-1 DC)

- just keep alive connection (with HTTP/1.1!) provides fairly good latency 