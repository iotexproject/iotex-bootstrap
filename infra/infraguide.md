## IoTeX Delegates Infrastructure Guide

1. Run your node behind a commercial cloud load balancer.

   Cloud provider like amazon AWS[^1], google GCE[^2] or Cloudflare[^3], etc provide good protection against a large amounts of L3, L4 DDoS attack including SYN floods, IP fragment floods, port exhaustion, etc out in the market. We suggest using these solutions network experts built to help you protect your node.

2. Put Envoy Proxy in front of your node as an edge proxy.

   [Envoy](https://www.envoyproxy.io/) combines with [ratelimit](https://github.com/lyft/ratelimit) provides request rate limiting on HTTP/HTTP2 and connection limits on all network traffic. Put your IoTeX node behind an Envoy proxy give you another layer of protection against attackers. Also, since IoTeX node API use GRPC, if you want to become a service node and serve API request for browser single page application, you will need Envoy's [grpc-web](https://github.com/grpc/grpc-web) filter to enable this functionality.

   In our testnet cluster, we set a 20 requests per second per IP rate limit on HTTP/HTTP2 requests 

   ```yaml
   domain: iotex-api
   descriptors:
     - key: remote_address
       rate_limit:
         unit: second
         requests_per_unit: 20
   ---
   domain: iotex-stats
   descriptors:
     - key: remote_address
       rate_limit:
         unit: second
         requests_per_unit: 20
   ```

   And the max connection numbers are set to 50

   ```yaml
   circuit_breakers:
     thresholds:
       max_connections: 50
       max_pending_requests: 500
       max_requests: 100
       max_retries: 3
   ```

   

   Here is the full configuration: [envoy config](https://gist.github.com/yutongp/c61292bf5c9c6e3058df96989365cb0c)

3. Use Kubernetes for deployment and health monitoring.

   [Kubernetes](https://kubernetes.io)(k8s) is a very powerful tool to manage your containerized services.  It is very convenient to deploy and upgrade service running in docker container in Kubernetes. 

   k8s will also do the health check and automatically restart the falling node to maximize your uptime.

   We heavily rely on k8s in our test environment. With our own experience, we can tell that k8s will for sure reduce your operation cost.

   These are the probe configuration we use in our deployment.yaml:

   ```yaml
   livenessProbe:
     httpGet:
       path: "/liveness"
       port: 8080
     initialDelaySeconds: 15
     timeoutSeconds: 2
     periodSeconds: 15
     failureThreshold: 5
   readinessProbe:
     httpGet:
       path: "/readiness"
       port: 8080
     initialDelaySeconds: 30
     timeoutSeconds: 2
     periodSeconds: 15
     failureThreshold: 5
   ```

The delegate bots we currently run for our testnet have a setup is very similar to following graph:![infra](infra.png?raw=true)

## Make It Even Better
We are still new in the area of running decentralized infrastructure. There are still many things we can learn and improve. And since it is decentralized, we will need options and ideas from different perspectives. That means we need a lot of help form your guys to help us getting better.


[^1]: https://aws.amazon.com/answers/networking/aws-ddos-attack-mitigation/
[^2]: https://cloud.google.com/files/GCPDDoSprotection-04122016.pdf
[^3]: https://www.cloudflare.com/ddos/
