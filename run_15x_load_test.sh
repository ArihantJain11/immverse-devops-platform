#!/usr/bin/env bash
set -euo pipefail

command -v k6 >/dev/null 2>&1 || { 
  echo "k6 is required but not installed. Please install k6 (brew install k6 or apt-get install k6).";
  exit 1;
}

cat << 'EOF' > /tmp/load_test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 150 },   // Baseline: 150 req/s
    { duration: '1m',  target: 150 },
    { duration: '2m',  target: 2250 },  // Ramp-up to 15x peak (2,250 req/s)
    { duration: '2m',  target: 2250 },  // Sustain peak
    { duration: '1m',  target: 150 },   // Cooldown
  ],
  thresholds: {
    http_req_duration: ['p(95)<400'],   // p95 latency under 400ms target
    http_req_failed: ['rate<0.001'],    // Error rate under 0.1% (99.9% availability)
  },
};

export default function () {
  const res = http.get('http://localhost:8080/healthz');
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(0.1);
}
EOF

echo "Running 15x autoscaling load test via k6..."
k6 run /tmp/load_test.js