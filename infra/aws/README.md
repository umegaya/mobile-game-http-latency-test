### latency-research AWS infra
- prerequisite
  - docker
  - domain name which is managed by route53
- setup
  ``` sh
  make setup DOMAIN=your.domain.name
  ```
- destroy
  - caution: some of un-charged resource like security group might be remain unremoved. 
  ``` sh
  make destroy DOMAIN=your.domain.name
  ```

- deploy API server container
  - caution: before deploying, make API server container image (see server/README.md for detail)
  ``` sh
  make deploy DOMAIN=your.domain.name IMAGE=your_desired/api_server_container_name
  ```

- deploy file serving container
  - caution: before deploying, make file serving container image (see server/README.md for detail)
  ``` sh
  make deploy DOMAIN=your.domain.name IMAGE=your_desired/file_serving_container_name
  ```