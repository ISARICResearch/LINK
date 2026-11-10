import { signOut } from 'aws-amplify/auth';
import { withTimeout } from './utils/utils';
//import { redirect } from '@sveltejs/kit';

function clearLocalAuthState() {
	Object.keys(localStorage)
		.filter((k) => k.startsWith('CognitoIdentityServiceProvider.'))
		.forEach((k) => localStorage.removeItem(k));

	return;
}

export const trySignOut = async () => {
    
	try {
        console.log("trySignOut 0")
		await withTimeout(signOut());
	} catch {
        console.log("trySignOut 1")
		try {
            console.log("trySignOut 2")
			await withTimeout(signOut({ global: false }), 2000);
		} catch {
            console.log("trySignOut 3")
			clearLocalAuthState();
			//redirect(500, '/');
		}
	}
};
