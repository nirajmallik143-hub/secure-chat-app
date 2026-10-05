# Security Policy

## Reporting a vulnerability
Please **do not** open a public issue. Use GitHub's private vulnerability reporting (Security tab → *Report a vulnerability*) for this repository, or contact the maintainer, Niraj Mallik, through GitHub. We aim to acknowledge reports within 72 hours.

## Scope and practices
- Passwords are hashed with bcrypt; refresh tokens are random, single-use and stored hashed.
- API uses helmet, CORS, rate limiting and zod input validation.
- Secrets live in environment variables / GitHub secrets only. Never commit `.env`, keystores or certificates.
- Production requires strong `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` (≥32 chars) and HTTPS.

Note: chat messages are currently protected in transit (TLS) but **not** end-to-end encrypted; E2EE is on the roadmap.
