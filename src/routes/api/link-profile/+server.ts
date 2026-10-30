import { json } from '@sveltejs/kit';
import { CognitoJwtVerifier } from 'aws-jwt-verify';
import { supabaseAdmin } from '$lib/server/supabaseAdmin';

const idVerifier = CognitoJwtVerifier.create({
	userPoolId: 'eu-west-2_B7drQDHTU',
	clientId: '7hq3co9kq52rgglklohvdjac6f',
	tokenUse: 'id'
});
const accessVerifier = CognitoJwtVerifier.create({
	userPoolId: 'eu-west-2_B7drQDHTU',
	clientId: '7hq3co9kq52rgglklohvdjac6f',
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

	const { data, error } = await supabaseAdmin.rpc('link_profile', {
		p_sub: id.sub,
		p_email: id.email
	});
	if (error) return json({ error: 'link failed' }, { status: 500 });

	return json({ profile: data });
}
