## IoTeX 代表(delegate)基础设施指南

1. 在商业云负载均衡器后面运行您的节点。

   像amazon AWS[^1], google GCE[^2] or Cloudflare[^3] 等云提供商会提供良好的保护, 防止大量的包括 SYN floods, IP fragment floods, port exhaustion在内的 L3, L4 DDoS 攻击, 我们建议使用这些解决方案网络专家来帮助您保护您的节点。

2. 将Envoy Proxy作为边缘代理放在节点前面。

   [Envoy](https://www.envoyproxy.io/) 与 [ratelimit](https://github.com/lyft/ratelimit) 对HTTP / HTTP2和所有网络流量的连接限制提供请求速率限制。将您的IoTeX节点置于Envoy代理后面，为您提供针对攻击者的另一层保护。此外，由于IoTeX节点API使用GRPC，如果您想成为服务节点并为浏览器单页面应用程序提供API请求, 您将需要Envoy的 [grpc-web](https://github.com/grpc/grpc-web) 过滤器以启用此功能。

   在我们的测试网络集群中，我们在HTTP / HTTP2请求上为每个IP速率限制设置了每秒20个请求

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

   并且最大连接数设置为50

   ```yaml
   circuit_breakers:
     thresholds:
       max_connections: 50
       max_pending_requests: 500
       max_requests: 100
       max_retries: 3
   ```

   

   以下是完整配置: [envoy config](https://gist.github.com/yutongp/c61292bf5c9c6e3058df96989365cb0c)

3. 使用Kubernetes进行部署和运行状况监控。

   [Kubernetes](https://kubernetes.io)(k8s) 是一个非常强大的用于管理您的容器化服务工具。在Kubernetes中部署和升级在docker容器中运行的服务非常方便。

   k8s 还将执行运行状况检查并自动重启下降节点以最大化正常运行时间。

   我们在测试环境中非常依赖k8s。根据我们自己的经验，我们可以确定k8s肯定会降低您的运营成本。


   这些是我们在deployment.yaml中使用的探测器配置：
   
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

   我们目前为testnet运行的委托机器人的设置与下图非常相似:![infra](https://github.com/iotexproject/iotex-testnet/blob/master/infra.png?raw=true)

## 让它变得更好
   我们在运行分散式基础设施方面仍然不够成熟。我们还有很多东西可以学习和改进。由于它是分散的，我们将需要从不同角度来看的选项和想法。这意味着我们需要很多帮助才能帮助我们变得更好。


[^1]: https://aws.amazon.com/answers/networking/aws-ddos-attack-mitigation/
[^2]: https://cloud.google.com/files/GCPDDoSprotection-04122016.pdf
[^3]: https://www.cloudflare.com/ddos/
