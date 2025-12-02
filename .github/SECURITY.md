# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please follow these steps:

1. **Do not** open a public issue
2. Send an email to security@nitrousos.com or create a private GitHub security advisory
3. Include detailed information about the vulnerability
4. Include steps to reproduce the issue
5. Include any potential impact assessment

## Security Features

NitrousOS includes several security features by default:

- LUKS full-disk encryption support
- SSH hardening with key-only authentication
- Firewall automation with service-aware port management
- Secure boot process with reproducible builds
- Runtime security validation assertions
- Disabled accounts by default with secure password requirements

## Security Updates

Security updates will be:
- Released as soon as possible
- Documented in the changelog
- Tagged with appropriate version numbers
- Communicated through GitHub releases

## Scope

This security policy covers:
- Core NitrousOS system configurations
- Plugin architecture security
- Build system security
- Documentation accuracy regarding security features

Out of scope:
- Third-party packages included in systems
- User-specific configurations
- Hardware-specific vulnerabilities