// test.js
import axios from 'axios';

const baseUrl = 'http://192.168.1.53:3000'; // Use the server's IP address

async function testServer() {
  try {
    // Test 1: Obter lista de áudios
    const audioListResponse = await axios.get(`${baseUrl}/audioList`);
    console.log('Lista de áudios:', audioListResponse.data);

    // Verificar se a lista de áudios não está vazia
    if (audioListResponse.data.length === 0) {
      console.log('Nenhum áudio encontrado na lista.');
    } else {
      console.log('Áudios encontrados:', audioListResponse.data.length);
    }

    // Test 2: Obter um arquivo de áudio específico
    const audioId = audioListResponse.data[0].id;
    const audioUrl = audioListResponse.data[0].audioUrl;
    const specificAudioResponse = await axios.get(audioUrl, { responseType: 'stream' });
    console.log(`Obtendo áudio com ID ${audioId} de ${audioUrl}:`, specificAudioResponse.status === 200 ? 'Sucesso' : 'Falha');


  } catch (error) {
    if (error.response) {
      console.log('Erro na requisição:', error.response.status, error.response.data);
    } else {
      console.log('Erro ao conectar ao servidor:', error.message);
    }
  }
}

testServer();