import { downloadAndConvertToMp3 } from './parseYt.js'; // Import the function

const testUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'; // Rick Astley - Never Gonna Give You Up

(async () => {
  try {
    const info = await downloadAndConvertToMp3(testUrl);
    console.log('Título do vídeo:', info.videoDetails.title);
  } catch (error) {
    console.error('Erro ao obter informações do vídeo:', error);
  }
})();