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

## High Availability

It's likely that one IoTeX node could be in outage because of code bugs, insufficient compute resource, host failure, network failure and etc, or you have to shutdown a node to do some maintenance work. Running multiple IoTeX nodes is the way to guarantee high availability (zero downtime) of your delegation. We provide the feature to run these nodes conveniently.

Assuming that you will run 3 nodes for your delegate, 1 will run actively and participant into the consensus work, and 2 will standby and only listen to the blocks.

All nodes can use the SAME `producerPrivKey`. For all nodes, add the following settings in `config.yaml`:

```yaml
...
network:
  ...
  masterKey: producer_private_key-replica_id
  ...
...
```

For the active node, add the following settings in `config.yaml`:

```yaml
...
system:
  ...
  active: true
  ...
...
```

For the standby nodes, add the following settings in `config.yaml`: 

```yaml
...
system:
  ...
  active: false
  ...
...
```

Additionally, export `9009` port from the node's docker container. Once the active node is down, use `http://ip-to-one-node:9009/ha?activate=true` to turn a standby node into active mode. Similarly, you can turn an active node into standby mode by using `http://ip-to-one-node:9009/ha?activate=false`. `http://ip-to-one-node:9009/ha` can tell you the mode of a node.

If you have quite a few nodes, and want to get rid of the tedious manual operation from your nodes or just want to try out the fancy setup of a high availability cluster, please check out the leader election solution [here](https://github.com/zjshen14/iotex-leader-election).

## Decentralized Gravity Chain Binding

IoTeX relies on the election result on our contract deployed on Ethereum, so that the server needs to a list of Ethereum JSON-RPC endpoints to consume the relevant data. While we provide a list of default JSON-RPC endpoints, delegates are encouraged to 
setup their own endpoint, to be more decentralized, secured and performant.

There are two approaches that we have experimented before and you could consider of:

- Setup an Ethereum node (no need to mine) ([geth](https://github.com/ethereum/go-ethereum/wiki/Installing-Geth) and [parity](https://wiki.parity.io/Setup)) for your own, and expose the JSON-RPC endpoint.
- Use [Infura](https://infura.io/) Ethereum blockchain infrasturcture: signing up an account and creating an project. The JSON-RPC endpoint would be https://mainnet.infura.io/v3/YOUR-PROJECT-ID. For more details of setting up Infura endpoint, please check [here](https://ethereumico.io/knowledge-base/infura-api-key-guide/).

After getting your own JSON-RPC endpoint, you could add it into following place in `config.yaml` and restart your server. Then, your IoTeX server will read from this endpoint to get Ethereum data. You could also create and add multiple endpoints for the sake of robustness.

```yaml
...
chain:
  ...
  committee:
    ...
    gravityChainAPIs:
      - [YOUR JSON-RPC ENDPOINT]
      ...
    ...
  ...
...
```

## Make It Even Better
We are still new in the area of running decentralized infrastructure. There are still many things we can learn and improve. And since it is decentralized, we will need options and ideas from different perspectives. That means we need a lot of help form your guys to help us getting better.


[^1]: https://aws.amazon.com/answers/networking/aws-ddos-attack-mitigation/
[^2]: https://cloud.google.com/files/GCPDDoSprotection-04122016.pdf
[^3]: https://www.cloudflare.com/ddos/
