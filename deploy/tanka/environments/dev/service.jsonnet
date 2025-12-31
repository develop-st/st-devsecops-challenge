// SECURITY FIX: Use ClusterIP instead of LoadBalancer
// LoadBalancer creates public-facing endpoint
// Use ClusterIP + Ingress for better security control
{
  apiVersion: "v1",
  kind: "Service",
  metadata: { 
    name: "light-backend", 
    namespace: "light",  // Match deployment namespace
  },
  spec: {
    type: "ClusterIP",  // Was: LoadBalancer - exposed service to internet
    selector: { app: "light-backend" },
    ports: [{ port: 80, targetPort: 8080, name: "http" }],
  },
}
