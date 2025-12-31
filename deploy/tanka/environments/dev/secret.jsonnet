// SECURITY FIX: Secrets should NOT be stored in git as plaintext!
// Options:
// 1. Use SOPS to encrypt this file (sops -e secret.jsonnet > secret.enc.jsonnet)
// 2. Use Sealed Secrets (kubeseal) 
// 3. Use External Secrets Operator with AWS Secrets Manager
// 4. Use Vault with CSI driver
//
// Below is a template - actual values should come from secret management

// For External Secrets Operator pattern:
{
  apiVersion: "external-secrets.io/v1beta1",
  kind: "ExternalSecret",
  metadata: { 
    name: "backend-secrets", 
    namespace: "light",
  },
  spec: {
    refreshInterval: "1h",
    secretStoreRef: {
      name: "aws-secrets-manager",
      kind: "ClusterSecretStore",
    },
    target: {
      name: "backend-secrets",
      creationPolicy: "Owner",
    },
    data: [
      {
        secretKey: "DATABASE_PASSWORD",
        remoteRef: {
          key: "light/dev/database",
          property: "password",
        },
      },
      {
        secretKey: "SENDGRID_API_KEY",
        remoteRef: {
          key: "light/dev/sendgrid",
          property: "api_key",
        },
      },
    ],
  },
}
