/**
  Kubernetes Deployment for light-backend
  SECURITY FIXES APPLIED:
  - Removed privileged mode
  - Added resource limits
  - Added health probes
  - Reference secrets from K8s Secret instead of plaintext
  - Use specific image tag instead of :latest
*/
{
  apiVersion: "apps/v1",
  kind: "Deployment",
  metadata: { 
    name: "light-backend", 
    namespace: "light",  // SECURITY: Use dedicated namespace, not default
    labels: { app: "light-backend" } 
  },
  spec: {
    replicas: 2,
    selector: { matchLabels: { app: "light-backend" } },
    template: {
      metadata: { labels: { app: "light-backend" } },
      spec: {
        // SECURITY: Use non-root service account
        serviceAccountName: "light-backend",
        automountServiceAccountToken: false,
        containers: [
          {
            name: "backend",
            // SECURITY FIX: Use specific version tag, not :latest
            // :latest is unpredictable and makes rollbacks difficult
            image: "ghcr.io/lightinc/light-backend:v1.0.0",
            imagePullPolicy: "IfNotPresent",
            ports: [{ containerPort: 8080 }],
            env: [
              { name: "DATABASE_URL", value: "jdbc:postgresql://postgres.light.svc.cluster.local:5432/postgres" },
              { name: "DATABASE_USER", value: "postgres" },
              // SECURITY FIX: Reference secret from K8s Secret, not plaintext
              { 
                name: "DATABASE_PASSWORD", 
                valueFrom: { 
                  secretKeyRef: { 
                    name: "backend-secrets", 
                    key: "DATABASE_PASSWORD" 
                  } 
                } 
              },
            ],
            // SECURITY FIX: Non-privileged security context
            securityContext: {
              privileged: false,              // Was: true - gives full host access!
              allowPrivilegeEscalation: false, // Was: true - allows escaping container
              readOnlyRootFilesystem: true,   // Was: false - prevents writes
              runAsNonRoot: true,             // Was: false - don't run as root
              runAsUser: 1000,
              capabilities: {
                drop: ["ALL"],
              },
            },
            // ADDED: Resource limits prevent DoS and noisy neighbor issues
            resources: {
              requests: {
                memory: "256Mi",
                cpu: "100m",
              },
              limits: {
                memory: "512Mi",
                cpu: "500m",
              },
            },
            // ADDED: Health probes for K8s to monitor app health
            livenessProbe: {
              httpGet: {
                path: "/health",
                port: 8080,
              },
              initialDelaySeconds: 30,
              periodSeconds: 10,
            },
            readinessProbe: {
              httpGet: {
                path: "/ready",
                port: 8080,
              },
              initialDelaySeconds: 5,
              periodSeconds: 5,
            },
          },
        ],
      },
    },
  },
}
