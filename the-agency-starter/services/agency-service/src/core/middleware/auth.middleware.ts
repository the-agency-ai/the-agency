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
 */
async function jwtAuth(c: Context, next: Next): Promise<Response | void> {
  const config = getConfig();
  const authHeader = c.req.header('Authorization');

  if (!authHeader?.startsWith('Bearer ')) {
    logger.warn('Missing or invalid Authorization header');
    return c.json({ error: 'Unauthorized', message: 'Missing Bearer token' }, 401);
  }

  const token = authHeader.slice(7);

  try {
    // TODO: Implement actual JWT validation
    // For now, just decode and trust (placeholder for real implementation)
    const payload = decodeJwt(token, config.jwtSecret);

    const user: AuthUser = {
      id: payload.sub || 'unknown',
      type: payload.type || 'agent',
      name: payload.name || 'unknown',
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
 * Placeholder JWT decoder (replace with real implementation)
 */
function decodeJwt(token: string, _secret?: string): Record<string, string> {
  // TODO: Use a proper JWT library for validation
  // This is a placeholder that just decodes without verification
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid JWT format');
    }
    const payload = JSON.parse(atob(parts[1]));
    return payload;
  } catch {
    throw new Error('Failed to decode JWT');
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
