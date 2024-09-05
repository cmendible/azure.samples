const { app } = require('@azure/functions');
const axios = require('axios');

app.http('httpTrigger', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        try {
            const response = await axios.get('https://carlos.mendible.com');
        } catch (error) {
            context.log('Error:', error);
        }
    }
});
