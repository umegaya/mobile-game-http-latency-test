import * as express from "express";  
import * as bodyParser from "body-parser";
import * as grpc from "grpc";
import * as loader from "@grpc/proto-loader";

console.log('run http server');
express()
    .use(bodyParser.json())
    .get('/', (req, res) => res.send())
    .post('/api/measure', (req, res) => res.status(200).send(req.body))
    .listen(80, () => console.log(`http server starts`));

console.log('run grpc server');
const server = new grpc.Server();
    server.addService((() => {
        const def = loader.loadSync('./proto/api.proto');
        return grpc.loadPackageDefinition(def).latency_research_grpc.Service.service;
    })(), {
        measure: (call: any, callback: any) => {
            callback(null, call.request);
        },
        health: (call: any, callback: any) => {
            callback(null, { diagnoses: "ok" });
        }
    });
    server.bind('0.0.0.0:50051', grpc.ServerCredentials.createInsecure());
    server.start();
    console.log(`grpc server starts`);
