// Function to map ecret key-value pairs to Kubernetes secret format
local mapSecret(obj) =
  [
    {
      name: key,
      valueFrom: {
        secretKeyRef: {
          name: obj[key].secret,
          key: obj[key].key,
        },
      },
    }
    for key in std.objectFields(obj)
  ];

// Function that defines environment variables per namespace
local getMapSecret(namespace) = mapSecret(
  {
    'app-prod-13': {
      SECRET_PASSWORD: {
        secret: 'demo-api-secret',
        key: 'password',
      },
    },
  }[namespace]
);

{
  getMapSecret: getMapSecret,
}