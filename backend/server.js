import { server as _server } from '@hapi/hapi';
import Inert from '@hapi/inert';
import { existsSync, readdirSync } from 'fs';
import { join, parse, dirname } from 'path';
import jsmediatags from 'jsmediatags';
import { fileURLToPath } from 'url';
import { downloadAndConvertToMp3 } from './parseYt.js'; // Import the function

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const init = async () => {
  const server = _server({
    port: 3000,
    host: '192.168.1.53', // Ajuste se necessário
    routes: {
      cors: {
        origin: ['*'],
      },
      files: {
        relativeTo: join(__dirname, 'public'),
      },
    },
  });

  await server.register(Inert);
  
  // Ler tags de um arquivo MP3 e retornar objeto com dados
  const readMp3Tags = (filePath) => {
    return new Promise((resolve) => {
      jsmediatags.read(filePath, {
        onSuccess: (tag) => {
          let coverArt = null;
          const image = tag.tags.picture;
          if (image) {
            let base64String = '';
            for (let i = 0; i < image.data.length; i++) {
              base64String += String.fromCharCode(image.data[i]);
            }
            coverArt = `data:${image.format};base64,${Buffer.from(base64String, 'binary').toString('base64')}`;
          }
          resolve({
            title: tag.tags.title || parse(filePath).name,
            artist: tag.tags.artist || 'Unknown',
            album: tag.tags.album || 'Unknown',
            coverArt: coverArt,
          });
        },
        onError: () => {
          resolve(null);
        },
      });
    });
  };
  
  // Gera lista de áudios lendo as tags de cada arquivo
  const gerarAudioList = async () => {
    const audiosDir = join(__dirname, 'public/audios');
    if (!existsSync(audiosDir)) {
      console.error('Diretório de áudios não encontrado.');
      return [];
    }
    const audioFiles = readdirSync(audiosDir).filter((file) => /\.(mp3|wav|ogg)$/i.test(file));

    // Ler tags de todos os arquivos
    const mp3Info = await Promise.all(
      audioFiles.map(async (audioFile, index) => {
        const filepath = join(audiosDir, audioFile);
        const info = await readMp3Tags(filepath);
        return {
          id: index + 1,
          title: info?.title || parse(audioFile).name,
          artist: info?.artist,
          album: info?.album,
          audioUrl: `http://${server.info.address}:${server.info.port}/audios/${audioFile}`,
          coverArt: info?.coverArt, // base64 da capa (se existir)
        };
      })
    );
    return mp3Info;
  };

  // Rota para obter a lista de áudios
  server.route({
    method: 'GET',
    path: '/audioList',
    handler: async (request, h) => {
      const audioList = await gerarAudioList();
      return h.response(audioList).code(200);
    },
  });

  // Rota para servir arquivos de áudio
  server.route({
    method: 'GET',
    path: '/audios/{param*}',
    handler: {
      directory: {
        path: 'audios',
        redirectToSlash: true,
        index: false,
      },
    },
  });

  // Rota para baixar e converter vídeo do YouTube para MP3
  server.route({
    method: 'POST',
    path: '/download',
    handler: async (request, h) => {
      console.log('Received payload:', request.payload); // Log completo do payload
      const { youtubeUrl } = request.payload;
      console.log('youtubeUrl:', youtubeUrl); // Log específico do youtubeUrl

      if (!youtubeUrl) {
        console.error('YouTube URL is required');
        return h.response({ error: 'YouTube URL is required' }).code(400);
      }

      try {
        console.log('Processing YouTube URL:', youtubeUrl);
        const result = await downloadAndConvertToMp3(youtubeUrl);
        console.log('Conversion result:', result);
        return h.response({ message: 'Download and conversion started', result }).code(200);
      } catch (error) {
        console.error('Error downloading and converting video:', error);
        return h.response({ error: 'Failed to download and convert video' }).code(500);
      }
    }
  });

  // Rota para servir arquivos estáticos sob demanda
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

  server.ext('onRequest', (request, h) => {
    console.log(`Received request for: ${request.path}`);
    return h.continue;
  });

  await server.start();
  console.log('Server running on %s', server.info.uri);
};

init();