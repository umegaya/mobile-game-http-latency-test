import * as express from "express";  
import * as bodyParser from "body-parser";

express()
    .use(bodyParser.json())
    .post('/measure', (req, res) => res.status(200).send(req.body))
    .listen(80, () => console.log(`server starts`));
