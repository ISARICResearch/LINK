import { Amplify } from 'aws-amplify';

console.log("AMPLIFY");

Amplify.configure({
	Auth: {
		Cognito: {
			userPoolId: 'eu-west-2_B7drQDHTU',
			userPoolClientId: '7hq3co9kq52rgglklohvdjac6f',
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

