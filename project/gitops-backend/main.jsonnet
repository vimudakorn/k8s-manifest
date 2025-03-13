local constants = import '../../constants/constants.json';
local env = import 'configs/env.jsonnet';
local secret = import 'configs/secret.jsonnet';
local vars = import 'vars/vars.json';

function(
  namespace='app-prod-13',
)
  local appName = 'gitops-backend';
  local mapEnvVars = env.getMapEnv(namespace);
  local mapSecretVars = secret.getMapSecret(namespace);
  local domain = 'api-group-13.iamgraph.live';

  [
    {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: appName,
        namespace: namespace,
        labels: {
          app: appName,
        },
      },
      spec: {
        replicas: 2,
        revisionHistoryLimit: 0,
        strategy: {
          type: 'RollingUpdate',
          rollingUpdate: {
            maxSurge: 1,
            maxUnavailable: 1,
          },
        },
        selector: {
          matchLabels: {
            app: appName,
          },
        },
        template: {
          metadata: {
            labels: {
              app: appName,
            },
          },
          spec: {
            containers: [
              {
                name: appName,
                image: constants.registryURL + '/<DOCKER_USERNAME>/' + appName + ':' + vars[namespace].version,
                imagePullPolicy: 'Always',
                env: mapEnvVars + mapSecretVars,
                ports: [
                  {
                    name: 'http',
                    containerPort: 8080,
                    protocol: 'TCP',
                  },
                ],
                resources: {
                  requests: {
                    cpu: '250m',
                    memory: '256Mi',
                  },
                  limits: {
                    cpu: '500m',
                    memory: '512Mi',
                  },
                },
              },
            ],
          },
        },
      },
    },
    {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        namespace: namespace,
        name: appName,
      },
      spec: {
        type: 'ClusterIP',
        ports: [
          {
            name: 'http',
            port: 8080,
            targetPort: 8080,
          },
        ],
        selector: {
          app: appName,
        },
      },
    },
    {
      apiVersion: 'networking.k8s.io/v1',
      kind: 'Ingress',
      metadata: {
        name: appName + '-ingress',
        namespace: namespace,
        annotations: {
          'nginx.ingress.kubernetes.io/proxy-body-size': '0',
          'nginx.ingress.kubernetes.io/proxy-read-timeout': '600',
          'nginx.ingress.kubernetes.io/proxy-send-timeout': '600',
        },
      },
      spec: {
        ingressClassName: 'nginx',
        rules: [
          {
            host: domain,
            http: {
              paths: [
                {
                  path: '/',
                  pathType: 'Prefix',
                  backend: {
                    service: {
                      name: appName,
                      port: {
                        number: 8080,
                      },
                    },
                  },
                },
              ],
            },
          },
        ],
      },
    },
  ]
