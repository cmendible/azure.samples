// https://www.returngis.net/2021/04/proteger-una-api-en-node-js-con-azure-active-directory/

const express = require('express'),
    app = express();

require('dotenv').config();

//Modules to use passport
const passport = require('passport'),
    JwtStrategy = require('passport-jwt').Strategy,
    ExtractJwt = require('passport-jwt').ExtractJwt,
    jwks = require('jwks-rsa');

let jwtOptions = {
    jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
    // Dynamically provide a signing key based on the kid in the header and the signing keys provided by the JWKS endpoint.
    secretOrKeyProvider: jwks.passportJwtSecret({
        jwksUri: `https://login.microsoftonline.com/${process.env.TENANT_ID}/discovery/v2.0/keys`,
    }),
    algorithms: ['RS256'],
    audience: process.env.AUDIENCE,
    issuer: `https://sts.windows.net/${process.env.TENANT_ID}/`
};

const verify = (jwt_payload, done) => {
    console.log(`Signature is valid for the JSON Web Token (JWT), let's check other things...`);
    console.log(jwt_payload);

    let tokenScope = `${jwt_payload.aud}/${jwt_payload.scp}`
    if (jwt_payload && jwt_payload.sub && process.env.SCOPE == tokenScope) {
        return done(null, jwt_payload);
    }

    return done(null, false);
};

passport.use(new JwtStrategy(jwtOptions, verify));

app.get("/protected", passport.authorize('jwt', { session: false }), function (req, res) {
    res.json({ message: "This message is protected" });
});

app.listen(1000, () => {
    console.log(`API running on port 1000!`);
});