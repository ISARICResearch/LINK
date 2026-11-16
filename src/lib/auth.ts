import { signOut } from 'aws-amplify/auth';
import { withTimeout } from './utils/utils';
import { goto } from '$app/navigation';

function clearLocalAuthState() {
	console.log('AUTH clearLocalAuthState');
	const keys = Object.keys(localStorage).filter(
		(k) =>
			k.startsWith('CognitoIdentityServiceProvider.') ||
			k.startsWith('com.amplify.Auth.') ||
			k.startsWith('amplify-signin-with-hostedUI') ||
			k.startsWith('amplify_')
	);
	console.log('AUTH keys', keys);
	keys.forEach((k) => localStorage.removeItem(k));
}

export const trySignOut = async () => {
	try {
		console.log('trySignOut 1: normal');
		await withTimeout(signOut(), 5000);
	} catch {
		try {
			console.log('trySignOut 2: local');
			await withTimeout(signOut({ global: false }), 2000);
		} catch {
			console.log('trySignOut 3: clear storage');
			clearLocalAuthState();
			//redirect(500, '/');
			
		}
	}
	await goto('/');
};
