/** @type {import('next').NextConfig} */
const nextConfig = {
  // SECURITY FIX: Enable strict mode for better React security
  // Was: false - misses potential issues
  reactStrictMode: true,
  
  // SECURITY FIX: Disable X-Powered-By header
  // Was: true - leaks technology stack to attackers
  poweredByHeader: false,
  
  // ADDED: Enable standalone output for optimized Docker builds
  output: 'standalone',
  
  // ADDED: Security headers
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;
