
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MeuApp(),
    ),
  );
}

class MeuApp extends StatefulWidget {
  const MeuApp({super.key});

  @override
  State<MeuApp> createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> {
  final diaController = TextEditingController();
  final atividadeController = TextEditingController();

  // Servidor Node (A16/SERVIDOR). Web/desktop -> localhost,
  // emulador Android -> 10.0.2.2.
  // Celular físico: troque pelo IP do PC (ex.: http://192.168.0.10:3000)
  static String get servidor {
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  final String url = '$servidor/atividades';

  List atividades = [];

  int mes = DateTime.now().month;
  int ano = DateTime.now().year;

  final meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    diaController.text = DateTime.now().day.toString();
    carregarAtividades();
  }

  @override
  void dispose() {
    diaController.dispose();
    atividadeController.dispose();
    super.dispose();
  }

  void mensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> carregarAtividades() async {
    try {
      final resposta = await http.get(
        Uri.parse('$url?mes=$mes&ano=$ano'),
      );

      if (resposta.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          atividades = jsonDecode(resposta.body);
        });
      } else {
        mensagem('Erro ao carregar atividades.');
      }
    } catch (e) {
      mensagem('Erro de conexão com o servidor.');
    }
  }

  Future<void> salvarAtividade() async {
    int? dia = int.tryParse(diaController.text);
    String atividade = atividadeController.text.trim();

    int ultimoDia = DateTime(ano, mes + 1, 0).day;

    if (dia == null ||
        dia < 1 ||
        dia > ultimoDia ||
        atividade.isEmpty) {
      mensagem('Preencha os campos corretamente.');
      return;
    }

    String data =
        '$ano-${mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';

    try {
      final resposta = await http.post(
        Uri.parse(url),
        body: {
          'dia': data,
          'atividade': atividade,
        },
      );

      if (resposta.statusCode == 200 || resposta.statusCode == 201) {
        atividadeController.clear();

        mensagem('Atividade cadastrada com sucesso!');

        await carregarAtividades();
      } else {
        mensagem('Erro ao cadastrar atividade.');
      }
    } catch (e) {
      mensagem('Erro de conexão com o servidor.');
    }
  }

  void alterarMes(int valor) {
    setState(() {
      DateTime novaData = DateTime(ano, mes + valor);

      ano = novaData.year;
      mes = novaData.month;
      atividades = [];
    });

    carregarAtividades();
  }

  String formatarData(String data) {
    List<String> partes = data.split('-');

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Atividades'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                IconButton(
                  onPressed: () => alterarMes(-1),
                  icon: const Icon(Icons.chevron_left),
                ),

                Text(
                  '${meses[mes - 1]} de $ano',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: () => alterarMes(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: diaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Dia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: atividadeController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Atividade desenvolvida',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: salvarAtividade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Cadastrar atividade',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Divider(),

            const Text(
              'Atividades do mês',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: atividades.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma atividade cadastrada.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: atividades.length,

                      itemBuilder: (context, index) {
                        final item = atividades[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.assignment),
                            ),

                            title: Text(
                              item['atividade'],
                            ),

                            subtitle: Text(
                              formatarData(item['dia']),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
