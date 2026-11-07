import { json } from '@sveltejs/kit';
import { CognitoJwtVerifier } from 'aws-jwt-verify';
import { supabaseAdmin } from '$lib/server/supabaseAdmin';
import type { SupabaseClient } from '@supabase/supabase-js';
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
	console.log('api update profile');
	let id, access, language, profession;
	try {
		const body = await request.json();
		({ language, profession } = body);
		id = await idVerifier.verify(body.idToken);
		access = await accessVerifier.verify(body.accessToken);
	} catch {
		return json({ error: 'invalid token' }, { status: 401 });
	}

	if (id.sub !== access.sub || id.event_id !== access.event_id)
		return json({ error: 'mismatch' }, { status: 401 });

	if (id.email_verified !== true || typeof id.email !== 'string')
		return json({ error: 'email not verified' }, { status: 403 });

	const { error } = await supabaseAdmin.rpc('update_profile', {
		u_sub: id.sub,
		u_lang: language,
		u_prof: profession
	});
	if (error) return json({ error: error }, { status: 500 });

	return json({ success: true });
}
