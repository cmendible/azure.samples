# Azure Application Gateway - Path-Based mTLS Configuration

This Terraform configuration demonstrates how to implement mutual TLS (mTLS) client certificate authentication with Azure Application Gateway.

## Overview

This setup uses an Azure Application Gateway with a wildcard SSL certificate to handle HTTPS traffic. The configuration demonstrates client certificate authentication (mTLS) for specific traffic patterns.

## Architecture

- **Virtual Network**: 10.0.0.0/16
- **Application Gateway Subnet**: 10.0.1.0/24 (with delegation to Microsoft.Network/applicationGateways)
- **Application Gateway**: Standard_v2 SKU
- **Public IP**: Static Standard SKU
- **SSL Certificate**: Wildcard certificate (*.contoso.com)

## Important Limitations

### Path-Based mTLS Limitation

**Azure Application Gateway CANNOT apply mTLS (client certificate authentication) based solely on URL path when using the same hostname.**

#### Why This Limitation Exists

The SSL/TLS handshake, including client certificate validation, occurs at the **connection establishment phase** - **before** the HTTP request (which contains the URL path) is processed. This means:

1. Client connects to the Application Gateway
2. TLS handshake occurs (server presents certificate, optionally requests client certificate)
3. Only after TLS is established, the HTTP request with the path is sent
4. Application Gateway then evaluates the path for routing decisions

Because client certificate validation happens in step 2, and path evaluation happens in step 4, **you cannot conditionally require client certificates based on the path**.

### Current Implementation: Subdomain-Based mTLS

This configuration uses **different subdomains** as a workaround:

- `*.secure.contoso.com` - Requires client certificate (mTLS enabled)
- `*.contoso.com` - No client certificate required

Both can use the same wildcard certificate (`*.contoso.com`) for the server certificate.

### Alternative Approaches

If you absolutely need path-based mTLS on the same hostname, consider these alternatives:

#### 1. Different Ports
- Use different frontend ports (e.g., 443 for regular, 8443 for mTLS)
- Route clients to different ports based on their needs
- Same hostname, different ports

#### 2. Azure Front Door + Application Gateway
- Use Azure Front Door for path-based routing
- Route different paths to different Application Gateway listeners
- Each listener can have different mTLS settings

## Configuration Components

### SSL Profile
The `ssl-profile-mtls` includes:
- SSL policy: `AppGwSslPolicy20220101` (modern, secure TLS policy)
- Trusted client certificates: Reference to the client CA certificate
- `verify_client_cert_issuer_dn`: Validates client certificate issuer

### Listeners
- **listener-secure**: Listens on `secure.contoso.com`, uses mTLS SSL profile
- **listener-default**: Listens on other subdomains, no mTLS

### Backend Pools
- **default-pool**: Backend for non-mTLS traffic
- **secure-pool**: Backend for mTLS-authenticated traffic

### Routing Rules
- **rule-secure**: Routes secure subdomain with path-based routing (priority 100)
- **rule-default**: Routes default traffic with basic routing (priority 200)

## Prerequisites

Before deploying, ensure you have:

1. **Wildcard SSL Certificate** (`contoso.corp.pfx`)
   - PFX file containing the server certificate and private key
   - Password: `123456` (change in production!)

2. **Client CA Certificate** (`client-ca.crt`)
   - Base64-encoded certificate of the CA that signs client certificates
   - Used to validate client certificates during mTLS

## Deployment

1. Update `variables.tf` with your values and then run:

   ```bash
   terraform init
   terraform apply
   ```

## References

- TLS Policy Overview for Azure Application Gateway: Details how TLS policies are applied and confirms that the handshake occurs before HTTP path evaluation. [learn.microsoft.com]
