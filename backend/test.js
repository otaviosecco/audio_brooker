// test.js
import axios from 'axios';

const baseUrl = 'http://localhost:3000'; // Altere para o endereço IP do seu servidor, se necessário

async function testServer() {
  try {
    // Teste 1: Requisição de login
    const loginResponse = await axios.post(`${baseUrl}/login`, {
      username: 'user',
      password: 'senha',
    });
    console.log('Resposta do login:', loginResponse.data);

    // Teste 2: Obter lista de áudios
    const audioListResponse = await axios.get(`${baseUrl}/audioList`);
    console.log('Lista de áudios:', audioListResponse.data);

    // Teste 3: Pesquisa de áudios
    const searchResponse = await axios.get(`${baseUrl}/search`, {
      params: { q: 'RenanAud.mp3' },
    });
    console.log('Resultado da pesquisa:', searchResponse.data);

  } catch (error) {
    if (error.response) {
      console.log('Erro na requisição:', error.response.status, error.response.data);
    } else {
      console.log('Erro ao conectar ao servidor:', error.message);
    }
  }
}

testServer();