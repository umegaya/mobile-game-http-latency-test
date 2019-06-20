## latency-research server containers

- build API server container
``` sh
make base_image image IMAGE=your_desired/api_server_container_name
```

- build static file serving container
``` sh
make redirector IMAGE=your_desired/file_serving_container_name
```
