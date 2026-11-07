import { PUBLIC_USER_POOL_CLIENT_ID, PUBLIC_USER_POOL_ID } from '$env/static/public';
import { Amplify } from 'aws-amplify';

console.log("AMPLIFY");

Amplify.configure({
	Auth: {
		Cognito: {
			userPoolId: PUBLIC_USER_POOL_ID,
			userPoolClientId: PUBLIC_USER_POOL_CLIENT_ID,
			loginWith: {
				oauth: {
					domain: 'eu-west-2b7drqdhtu.auth.eu-west-2.amazoncognito.com',
					scopes: ['openid', 'email'],
					redirectSignIn: ['http://localhost:5173/home/', 'https://link.isaric.org/home/'],
					redirectSignOut: ['http://localhost:5173/', 'https://link.isaric.org/'],
					responseType: 'code'
				}
			}
		}
	}
});

