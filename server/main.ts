import * as express from "express";  
import * as bodyParser from "body-parser";
import { resolve } from "dns";

express()
    .use(bodyParser.json())
    .get('/', (req, res) => res.send())
    .post('/api/measure', (req, res) => res.status(200).send(req.body))
    .listen(80, () => console.log(`server starts`));
