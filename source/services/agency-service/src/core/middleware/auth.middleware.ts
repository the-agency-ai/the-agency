/**
 * Authentication Middleware
 *
 * Token-based auth that supports two modes:
 * - local: Always passes (for single-principal local development)
 * - jwt: Validates JWT tokens (for multi-principal cloud deployment)
 *
 * Business model:
 * - Free tier: Local mode, single principal
 * - Paid tier: JWT mode, multi-principal
 */

import type { Context, Next } from 'hono';
import { getConfig } from '../config';
import { createServiceLogger } from '../lib/logger';

const logger = createServiceLogger('auth-middleware');

/**
 * User context attached to requests after authentication
 */
export interface AuthUser {
  id: string;
  type: 'principal' | 'agent' | 'system';
  name: string;
}

/**
 * Extend Hono's context with auth user
 */
declare module 'hono' {
  interface ContextVariableMap {
    user: AuthUser;
  }
}

/**
 * Local auth middleware - always passes with default user
 */
async function localAuth(c: Context, next: Next): Promise<Response | void> {
  // In local mode, extract user from header or use default
  const userHeader = c.req.header('X-Agency-User');

  let user: AuthUser;

  if (userHeader) {
    // Parse user header: "type:name" e.g., "agent:housekeeping"
    const [rawType, name] = userHeader.split(':');

    // Validate type is one of the allowed values
    const validTypes: AuthUser['type'][] = ['principal', 'agent', 'system'];
    const type: AuthUser['type'] = validTypes.includes(rawType as AuthUser['type'])
      ? (rawType as AuthUser['type'])
      : 'agent';

    user = {
      id: `local-${type}-${name || 'unknown'}`,
      type,
      name: name || 'unknown',
    };
  } else {
    // Default local user
    user = {
      id: 'local-principal-default',
      type: 'principal',
      name: 'local',
    };
  }

  c.set('user', user);
  logger.debug({ user }, 'Local auth passed');

  await next();
}

/**
 * JWT auth middleware - validates Bearer token
 *
 * SECURITY WARNING: This implementation does NOT verify JWT signatures.
 * JWT mode should ONLY be used when you trust the token source completely
 * (e.g., behind a reverse proxy that validates tokens).
 *
 * For production use with untrusted clients, implement proper JWT verification
 * using a library like 'jose' or 'jsonwebtoken'.
 */
async function jwtAuth(c: Context, next: Next): Promise<Response | void> {
  const config = getConfig();

  // SECURITY: Fail-safe check - warn in production if JWT secret is not configured
  if (config.nodeEnv === 'production' && !config.jwtSecret) {
    logger.error('JWT mode enabled in production without jwtSecret - this is insecure!');
    return c.json({
      error: 'Service Misconfigured',
      message: 'JWT authentication not properly configured',
    }, 500);
  }

  const authHeader = c.req.header('Authorization');

  if (!authHeader?.startsWith('Bearer ')) {
    logger.warn('Missing or invalid Authorization header');
    return c.json({ error: 'Unauthorized', message: 'Missing Bearer token' }, 401);
  }

  const token = authHeader.slice(7);

  try {
    // WARNING: This only decodes, it does NOT verify the signature!
    // An attacker can forge tokens. Only use if tokens are validated upstream.
    const payload = decodeJwt(token, config.jwtSecret);

    // Validate required fields are present
    if (!payload.sub || !payload.type || !payload.name) {
      logger.warn({ payload }, 'JWT missing required fields (sub, type, name)');
      return c.json({ error: 'Unauthorized', message: 'Invalid token claims' }, 401);
    }

    // Validate type is one of allowed values
    const validTypes: AuthUser['type'][] = ['principal', 'agent', 'system'];
    if (!validTypes.includes(payload.type as AuthUser['type'])) {
      logger.warn({ type: payload.type }, 'Invalid user type in JWT');
      return c.json({ error: 'Unauthorized', message: 'Invalid token claims' }, 401);
    }

    const user: AuthUser = {
      id: payload.sub,
      type: payload.type as AuthUser['type'],
      name: payload.name,
    };

    c.set('user', user);
    logger.debug({ userId: user.id }, 'JWT auth passed');

    await next();
  } catch (error) {
    logger.warn({ error }, 'JWT validation failed');
    return c.json({ error: 'Unauthorized', message: 'Invalid token' }, 401);
  }
}

/**
 * JWT decoder - INSECURE: Does NOT verify signature
 *
 * CRITICAL SECURITY WARNING:
 * This function only decodes the JWT payload without cryptographic verification.
 * Anyone can create a valid-looking JWT with arbitrary claims.
 *
 * Only use this when:
 * 1. Tokens are validated by a trusted upstream service (reverse proxy, API gateway)
 * 2. In development/testing environments
 *
 * For production with direct client access, replace with:
 * ```typescript
 * import { jwtVerify } from 'jose';
 * const { payload } = await jwtVerify(token, secretKey);
 * ```
 *
 * @param token - The JWT token string
 * @param _secret - UNUSED - kept for API compatibility when proper verification is added
 * @returns Decoded payload (UNVERIFIED!)
 */
function decodeJwt(token: string, _secret?: string): Record<string, string> {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid JWT format - expected 3 parts');
    }

    // Base64url decode the payload (second part)
    const base64Payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const payload = JSON.parse(atob(base64Payload));

    // Basic sanity check - payload should be an object
    if (typeof payload !== 'object' || payload === null) {
      throw new Error('Invalid JWT payload - expected object');
    }

    return payload;
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    throw new Error(`Failed to decode JWT: ${message}`);
  }
}

/**
 * Main auth middleware - selects strategy based on config
 */
export function authMiddleware() {
  return async (c: Context, next: Next) => {
    const config = getConfig();

    switch (config.authMode) {
      case 'local':
        return localAuth(c, next);

      case 'jwt':
        return jwtAuth(c, next);

      default:
        logger.error({ authMode: config.authMode }, 'Unknown auth mode');
        return c.json({ error: 'Internal Server Error' }, 500);
    }
  };
}

/**
 * Optional auth - doesn't fail if no auth provided (for public endpoints)
 */
export function optionalAuth() {
  return async (c: Context, next: Next) => {
    const config = getConfig();
    const authHeader = c.req.header('Authorization');
    const userHeader = c.req.header('X-Agency-User');

    // If no auth headers, proceed without user
    if (!authHeader && !userHeader) {
      await next();
      return;
    }

    // If auth headers present, validate them
    return authMiddleware()(c, next);
  };
}

/**
 * Require specific user types
 */
export function requireType(...types: AuthUser['type'][]) {
  return async (c: Context, next: Next) => {
    const user = c.get('user');

    if (!user) {
      return c.json({ error: 'Unauthorized', message: 'Not authenticated' }, 401);
    }

    if (!types.includes(user.type)) {
      logger.warn({ user, requiredTypes: types }, 'Insufficient permissions');
      return c.json(
        { error: 'Forbidden', message: `Requires one of: ${types.join(', ')}` },
        403
      );
    }

    await next();
  };
}

export default authMiddleware;
