import { json } from '@sveltejs/kit';
import { CognitoJwtVerifier } from 'aws-jwt-verify';
import { supabaseAdmin } from '$lib/server/supabaseAdmin';
import { PUBLIC_USER_POOL_CLIENT_ID, PUBLIC_USER_POOL_ID } from '$env/static/public';

const idVerifier = CognitoJwtVerifier.create({
	userPoolId: PUBLIC_USER_POOL_ID,
	clientId: PUBLIC_USER_POOL_CLIENT_ID,
	tokenUse: 'id'
});
const accessVerifier = CognitoJwtVerifier.create({
	userPoolId: PUBLIC_USER_POOL_ID,
	clientId: PUBLIC_USER_POOL_CLIENT_ID,
	tokenUse: 'access'
});

export async function POST({ request }) {
	console.log('api linkprofile');
	let id, access;
	try {
		const { idToken, accessToken } = await request.json();
		id = await idVerifier.verify(idToken);
		access = await accessVerifier.verify(accessToken);
	} catch {
		return json({ error: 'invalid token' }, { status: 401 });
	}

	if (id.sub !== access.sub || id.event_id !== access.event_id) {
		return json({ error: 'mismatch' }, { status: 401 });
	}
	if (id.email_verified !== true || typeof id.email !== 'string') {
		return json({ error: 'email not verified' }, { status: 403 });
	}

	const { data, error } = await supabaseAdmin().rpc('link_profile', {
		p_sub: id.sub,
		p_email: id.email
	});
	if (error) return json({ error: 'link failed' }, { status: 500 });

	return json({ profile: data });
}
