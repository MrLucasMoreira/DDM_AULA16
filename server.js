import 'dotenv/config';

import express from 'express';
import cors from 'cors';

import { initializeApp } from 'firebase/app';
import {
  getDatabase,
  ref,
  get,
  set,
  push
} from 'firebase/database';

const app = express();
const port = 3000;

// =======================================
// FIREBASE (mesmo projeto da A13/A14,
// a "tabela" aqui é o nó "atividades/")
// =======================================

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: 'ddmapi.firebaseapp.com',
  databaseURL: 'https://ddmapi-default-rtdb.firebaseio.com',
  projectId: 'ddmapi',
  storageBucket: 'ddmapi.firebasestorage.app',
  messagingSenderId: '724860875864',
  appId: '1:724860875864:web:9dae57c24ef0b3606f462d'
};

const firebaseApp = initializeApp(firebaseConfig);
const db = getDatabase(firebaseApp);

const T_ATIVIDADES = process.env.TABELA_ATIVIDADES || 'atividades';

// =======================================
// MIDDLEWARES
// =======================================

app.use(cors());
app.use(express.json());
// Aceita também o formato de formulário (igual ao $_POST do PHP)
app.use(express.urlencoded({ extended: false }));

// =======================================
// UTILITÁRIOS
// =======================================

// Confere se é uma data real no formato AAAA-MM-DD
function dataValida(texto) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(texto)) return false;

  const [ano, mes, dia] = texto.split('-').map(Number);
  const data = new Date(Date.UTC(ano, mes - 1, dia));

  return data.getUTCFullYear() === ano &&
    data.getUTCMonth() === mes - 1 &&
    data.getUTCDate() === dia;
}

// =======================================
// ROTA INICIAL
// =======================================

app.get('/', (req, res) => {
  res.json({ mensagem: 'API Atividades funcionando!' });
});

// =======================================
// CADASTRAR ATIVIDADE
// =======================================

app.post('/atividades', async (req, res) => {
  try {
    const dia = String(req.body.dia || '');
    const atividade = String(req.body.atividade || '').trim();

    if (!dataValida(dia) || !atividade || atividade.length > 500) {
      return res.status(400).json({ erro: 'Dados inválidos' });
    }

    const novoRef = push(ref(db, T_ATIVIDADES));

    const registro = {
      id: novoRef.key,
      dia,
      atividade,
      criadoEm: new Date().toISOString()
    };

    await set(novoRef, registro);

    console.log('Atividade cadastrada:', dia);

    return res.status(201).json({
      mensagem: 'Atividade cadastrada',
      ...registro
    });

  } catch (erro) {
    console.error('Erro ao cadastrar:', erro);
    return res.status(500).json({ erro: 'Erro ao cadastrar' });
  }
});

// =======================================
// LISTAR ATIVIDADES DO MÊS
// =======================================

app.get('/atividades', async (req, res) => {
  try {
    const hoje = new Date();
    const mes = Number(req.query.mes ?? hoje.getMonth() + 1);
    const ano = Number(req.query.ano ?? hoje.getFullYear());

    if (!Number.isInteger(mes) || mes < 1 || mes > 12 ||
        !Number.isInteger(ano)) {
      return res.status(400).json({ erro: 'Mês ou ano inválido.' });
    }

    const snapshot = await get(ref(db, T_ATIVIDADES));

    if (!snapshot.exists()) {
      return res.status(200).json([]);
    }

    // Ex.: "2026-11-" -> todas as datas de novembro/2026
    const prefixo = `${ano}-${String(mes).padStart(2, '0')}-`;

    const atividades = Object.values(snapshot.val())
      .filter(a => a && String(a.dia).startsWith(prefixo))
      .sort((a, b) =>
        // dia DESC, depois cadastro mais recente primeiro
        b.dia.localeCompare(a.dia) ||
        String(b.criadoEm).localeCompare(String(a.criadoEm))
      )
      .map(({ id, dia, atividade }) => ({ id, dia, atividade }));

    return res.status(200).json(atividades);

  } catch (erro) {
    console.error('Erro ao listar:', erro);
    return res.status(500).json({ erro: 'Erro ao carregar atividades.' });
  }
});

// =======================================
// INICIAR SERVIDOR
// =======================================

app.listen(port, () => {
  console.log(`Servidor rodando em http://localhost:${port}`);
});
