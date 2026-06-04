import { randomUUID } from 'crypto';
import { supabaseAdmin } from '../../db.js';

const NOTION_AUTHORIZE_URL = 'https://api.notion.com/v1/oauth/authorize';
const NOTION_TOKEN_URL = 'https://api.notion.com/v1/oauth/token';
const NOTION_API_VERSION = process.env.NOTION_API_VERSION ?? '2022-06-28';

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

class NotionIntegrationError extends Error {
  constructor(message, { statusCode = 400 } = {}) {
    super(message);
    this.name = 'NotionIntegrationError';
    this.statusCode = statusCode;
  }
}

function getNotionConfig() {
  const clientId = process.env.NOTION_CLIENT_ID?.trim();
  const clientSecret = process.env.NOTION_CLIENT_SECRET?.trim();
  const redirectUri = process.env.NOTION_REDIRECT_URI?.trim();

  if (!clientId || !clientSecret || !redirectUri) {
    throw new NotionIntegrationError(
      'NOTION_CLIENT_ID, NOTION_CLIENT_SECRET, and NOTION_REDIRECT_URI must be configured in server/.env',
      { statusCode: 500 }
    );
  }

  return { clientId, clientSecret, redirectUri };
}

function sanitizeAuthId(authId) {
  if (typeof authId !== 'string' || !UUID_REGEX.test(authId.trim())) {
    throw new NotionIntegrationError('authId must be a valid UUID');
  }

  return authId.trim();
}

function encodeState(authId) {
  return Buffer.from(
    JSON.stringify({
      authId,
      nonce: randomUUID(),
    })
  ).toString('base64url');
}

function decodeState(state) {
  if (typeof state !== 'string' || !state.trim()) {
    throw new NotionIntegrationError('Missing OAuth state');
  }

  try {
    const parsed = JSON.parse(Buffer.from(state, 'base64url').toString('utf8'));

    if (!parsed?.authId || !UUID_REGEX.test(parsed.authId)) {
      throw new Error('Invalid authId in state');
    }

    return parsed.authId;
  } catch {
    throw new NotionIntegrationError('Invalid OAuth state');
  }
}

function buildNotionAuthorizationUrl(authId) {
  const { clientId, redirectUri } = getNotionConfig();
  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: 'code',
    owner: 'user',
    state: encodeState(authId),
  });

  return `${NOTION_AUTHORIZE_URL}?${params.toString()}`;
}

function getBasicAuthHeader(clientId, clientSecret) {
  return `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`;
}

async function exchangeNotionCode(code) {
  const { clientId, clientSecret, redirectUri } = getNotionConfig();

  const response = await fetch(NOTION_TOKEN_URL, {
    method: 'POST',
    headers: {
      Authorization: getBasicAuthHeader(clientId, clientSecret),
      'Content-Type': 'application/json',
      'Notion-Version': NOTION_API_VERSION,
    },
    body: JSON.stringify({
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri,
    }),
  });

  const payload = await response.json();

  if (!response.ok) {
    throw new NotionIntegrationError(
      payload?.error_description ??
        payload?.error ??
        'Failed to exchange Notion authorization code',
      { statusCode: response.status }
    );
  }

  return payload;
}

async function saveNotionIntegration(authId, tokenPayload) {
  const record = {
    auth_id: authId,
    access_token: tokenPayload.access_token,
    refresh_token: tokenPayload.refresh_token ?? null,
    bot_id: tokenPayload.bot_id ?? null,
    workspace_id: tokenPayload.workspace_id ?? null,
    workspace_name: tokenPayload.workspace_name ?? null,
    workspace_icon: tokenPayload.workspace_icon ?? null,
    updated_at: new Date().toISOString(),
  };

  const { data, error } = await supabaseAdmin
    .from('notion_integrations')
    .upsert(record, { onConflict: 'auth_id' })
    .select()
    .single();

  if (error) {
    throw new NotionIntegrationError(
      `Failed to store Notion integration: ${error.message}`,
      { statusCode: 500 }
    );
  }

  return data;
}

function buildSuccessRedirect(integration) {
  const successRedirect = process.env.NOTION_SUCCESS_REDIRECT_URI?.trim();

  if (!successRedirect) {
    return null;
  }

  const url = new URL(successRedirect);
  url.searchParams.set('notion', 'connected');

  if (integration?.workspace_name) {
    url.searchParams.set('workspace', integration.workspace_name);
  }

  return url.toString();
}

async function signInWithNotion(req, res) {
  try {
    const authId = sanitizeAuthId(req.body?.authId ?? req.query?.authId ?? '');
    const url = buildNotionAuthorizationUrl(authId);

    return res.status(200).json({
      ok: true,
      url,
    });
  } catch (error) {
    const statusCode = error instanceof NotionIntegrationError ? error.statusCode : 500;

    return res.status(statusCode).json({
      ok: false,
      error: error.message ?? 'Unexpected Notion integration error',
    });
  }
}

async function notionOAuthCallback(req, res) {
  try {
    const { code, state, error: oauthError } = req.query;

    if (oauthError) {
      throw new NotionIntegrationError(
        typeof oauthError === 'string' ? oauthError : 'Notion authorization was denied'
      );
    }

    if (typeof code !== 'string' || !code.trim()) {
      throw new NotionIntegrationError('Missing Notion authorization code');
    }

    const authId = decodeState(state);
    const tokenPayload = await exchangeNotionCode(code.trim());
    const integration = await saveNotionIntegration(authId, tokenPayload);

    const redirectUrl = buildSuccessRedirect(integration);

    if (redirectUrl) {
      return res.redirect(redirectUrl);
    }

    return res.status(200).json({
      ok: true,
      data: {
        authId: integration.auth_id,
        workspaceId: integration.workspace_id,
        workspaceName: integration.workspace_name,
      },
    });
  } catch (error) {
    const statusCode = error instanceof NotionIntegrationError ? error.statusCode : 500;

    return res.status(statusCode).json({
      ok: false,
      error: error.message ?? 'Unexpected Notion callback error',
    });
  }
}

export {
  NotionIntegrationError,
  buildNotionAuthorizationUrl,
  signInWithNotion,
  notionOAuthCallback,
};
