console.log('Server side code running');

const express = require('express');
const app = express();

//serve files from the public
app.use(express.static('public'));
app.listen(8070, () => {
    console.log('listening on 8070');
});