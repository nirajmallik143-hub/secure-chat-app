import http from 'http';
import { createApp } from './app';
import { env } from './config/env';
import { attachSockets } from './sockets';

const server = http.createServer(createApp());
attachSockets(server);
server.listen(env.port, () => console.log(`API listening on :${env.port}`));
