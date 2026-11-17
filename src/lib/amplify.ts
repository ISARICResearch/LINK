import { PUBLIC_USER_POOL_CLIENT_ID, PUBLIC_USER_POOL_ID } from '$env/static/public';
import { Amplify } from 'aws-amplify';

console.log('AMPLIFY');

Amplify.configure({
	Auth: {
		Cognito: {
			userPoolId: PUBLIC_USER_POOL_ID,
			userPoolClientId: PUBLIC_USER_POOL_CLIENT_ID,
			loginWith: {
				oauth: {
					domain: 'eu-west-2b7drqdhtu.auth.eu-west-2.amazoncognito.com',
					scopes: ['openid', 'email'],
					redirectSignIn: [
						'https://link.isaric.org/home/', // production
						'http://localhost:5173/home/', // development
						'http://localhost:4173/home/' // test build
					],
					redirectSignOut: [
						'https://link.isaric.org/', // production
						'http://localhost:5173/', // development
						'http://localhost:4173/' // test build
					],
					responseType: 'code'
				}
			}
		}
	}
});
