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
