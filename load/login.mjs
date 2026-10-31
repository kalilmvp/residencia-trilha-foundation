import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const require = createRequire(join(root, "site/package.json"));
const {
  AuthenticationDetails,
  CognitoUser,
  CognitoUserPool,
} = require("amazon-cognito-identity-js");

const fileEnv = (path) => {
  try {
    return Object.fromEntries(
      readFileSync(path, "utf8")
        .split("\n")
        .map((line) => line.match(/^([A-Z0-9_]+)=(.*)$/))
        .filter(Boolean)
        .map((match) => [match[1], match[2]]),
    );
  } catch {
    return {};
  }
};

const siteEnv = fileEnv(join(root, "site/.env.production.local"));
const userPoolId = process.env.K6_USER_POOL_ID || siteEnv.VITE_COGNITO_USER_POOL_ID;
const clientId = process.env.K6_CLIENT_ID || siteEnv.VITE_COGNITO_CLIENT_ID;
const username = process.env.K6_USERNAME;
const password = process.env.K6_PASSWORD;

if (!userPoolId || !clientId || !username || !password) {
  console.error("Set K6_USERNAME and K6_PASSWORD. The user pool client only allows SRP sign-in.");
  process.exit(1);
}

const user = new CognitoUser({
  Username: username,
  Pool: new CognitoUserPool({ UserPoolId: userPoolId, ClientId: clientId }),
});

user.authenticateUser(new AuthenticationDetails({ Username: username, Password: password }), {
  onSuccess: (session) => {
    process.stdout.write(session.getIdToken().getJwtToken());
  },
  newPasswordRequired: () => {
    console.error("This user still has a new-password challenge. Finish the first sign-in on the site, then retry.");
    process.exit(1);
  },
  onFailure: (error) => {
    console.error(error?.message || "Cognito sign-in failed.");
    process.exit(1);
  },
});
