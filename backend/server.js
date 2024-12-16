import Hapi from '@hapi/hapi';
import Inert from '@hapi/inert';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const users = [
  { username: 'user', password: 'senha' },
];

const audioList = [
  {
    id: 1,
    title: 'RenanAud.mp3',
    audioUrl: 'http://192.168.1.8:3000/audios/RenanAud.mp3',
    imageUrl: 'http://192.168.1.8:3000/images/RenanImg.png',
  },
  // Adicione mais itens conforme necessário
];

const init = async () => {
  const server = Hapi.server({
    port: 3000,
    host: '0.0.0.0',
    routes: {
      cors: {
        origin: ['*'], // Permite todas as origens
      },
      files: {
        relativeTo: join(__dirname, 'public'),
      },
    },
  });

  // Registrar o plugin Inert para servir arquivos estáticos
  await server.register(Inert);

  // Rota para o login
  server.route({
    method: 'POST',
    path: '/login',
    handler: (request, h) => {
      const { username, password } = request.payload;
      const user = users.find(u => u.username === username && u.password === password);
      if (user) {
        return h.response('Login successful').code(200);
      } else {
        return h.response('Invalid credentials').code(401);
      }
    },
  });

  // Rota para obter a lista de áudios
  server.route({
    method: 'GET',
    path: '/audioList',
    handler: (request, h) => {
      return h.response(audioList).code(200);
    },
  });

  // Rota para servir arquivos estáticos (áudios e imagens)
  server.route({
    method: 'GET',
    path: '/{param*}',
    handler: {
      directory: {
        path: '.',
        redirectToSlash: true,
        index: false,
      },
    },
  });

  await server.start();
  console.log('Server running on %s', server.info.uri);
};

process.on('unhandledRejection', err => {
  console.log(err);
  process.exit(1);
});

init();