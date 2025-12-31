import React from "react";

export default function Home() {
  // SECURITY FIX: Removed dangerouslySetInnerHTML
  // Original code used dangerouslySetInnerHTML which is vulnerable to XSS attacks
  // If 'sample' came from user input, attacker could inject: <script>steal(cookies)</script>
  // Now using safe React text rendering instead
  const sample = "Hello world";
  return (
    <main style={{ padding: 24 }}>
      <h1>Light Starter</h1>
      <p><strong>Hello</strong> world</p>
    </main>
  );
}
