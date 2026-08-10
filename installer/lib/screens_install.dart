import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class InstallProgressScreen extends StatefulWidget {
  final String initialProfile;

  const InstallProgressScreen({super.key, this.initialProfile = 'devops'});

  @override
  State<InstallProgressScreen> createState() => _InstallProgressScreenState();
}

class _InstallProgressScreenState extends State<InstallProgressScreen> {
  late String _selectedProfile;
  bool _isInstalling = false;
  bool _isFinished = false;
  bool _hasError = false;
  double _progress = 0.0;
  String _currentStep = 'Aguardando seleção do perfil...';
  
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTerminalExpanded = true;

  final Map<String, Map<String, dynamic>> _profiles = {
    'dev': {
      'title': '💻 Apenas Dev',
      'desc': 'Java 21, Flutter, Node, Angular, CachyOS, Docker, IDEs e tema macOS.',
      'icon': Icons.code,
    },
    'devops': {
      'title': '☁️ Dev + DevOps & Infra',
      'desc': 'Tudo do Dev + Kubernetes, Terraform, Ansible, AWS CLI e Ferramentas de Redes.',
      'icon': Icons.cloud,
    },
    'full': {
      'title': '🎥 Completo (Dev + Mídia/Marketing)',
      'desc': 'Tudo do DevOps + OBS Studio, Kdenlive, Blender, GIMP, Inkscape e Audacity.',
      'icon': Icons.video_camera_back,
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedProfile = widget.initialProfile;
  }

  void _processOutputLine(String line) {
    if (!mounted) return;

    setState(() {
      if (line.startsWith('[PROGRESS:')) {
        final valStr = line.replaceAll('[PROGRESS:', '').replaceAll(']', '').trim();
        final val = double.tryParse(valStr);
        if (val != null) {
          _progress = (val / 100.0).clamp(0.0, 1.0);
        }
      } else if (line.startsWith('[STEP:')) {
        _currentStep = line.replaceAll('[STEP:', '').replaceAll(']', '').trim();
      } else {
        _logs.add(line);
      }
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startInstallation() async {
    setState(() {
      _isInstalling = true;
      _progress = 0.02;
      _currentStep = 'Iniciando instalação do perfil...';
      _logs.clear();
    });

    try {
      final scriptFile = File('/usr/local/bin/setup_master_dev.sh');
      final scriptPath = scriptFile.existsSync()
          ? '/usr/local/bin/setup_master_dev.sh'
          : '/home/illuminate/IlluminateBR-OS/scripts/install.sh';

      final process = await Process.start(
        'sudo',
        [scriptPath, _selectedProfile],
      );

      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        _processOutputLine(line);
      });

      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        _processOutputLine(line);
      });

      final exitCode = await process.exitCode;
      
      if (mounted) {
        setState(() {
          _isFinished = true;
          if (exitCode == 0) {
            _progress = 1.0;
            _currentStep = 'Instalação concluída com sucesso!';
          } else {
            _hasError = true;
            _currentStep = 'Instalação finalizada com avisos/erros (Código: $exitCode).';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFinished = true;
          _hasError = true;
          _currentStep = 'Erro de execução: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              // Cabeçalho
              Row(
                children: [
                  const Icon(Icons.blur_on, color: Color(0xFF0066CC), size: 36),
                  const SizedBox(width: 12),
                  const Text(
                    'IlluminateBR-OS',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0066CC).withOpacity(0.5)),
                    ),
                    child: Text(
                      'Perfil: ${_selectedProfile.toUpperCase()}',
                      style: const TextStyle(color: Color(0xFF0066CC), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tela de Seleção
              if (!_isInstalling) ...[
                const Text(
                  'Escolha o Perfil de Instalação:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: _profiles.entries.map((entry) {
                      final key = entry.key;
                      final data = entry.value;
                      final isSelected = _selectedProfile == key;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedProfile = key),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0066CC).withOpacity(0.2) : const Color(0xFF2D2D2D),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0066CC) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(data['icon'], size: 40, color: isSelected ? const Color(0xFF0066CC) : Colors.grey),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAlignment.start,
                                  children: [
                                    Text(
                                      data['title'],
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      data['desc'],
                                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: key,
                                groupValue: _selectedProfile,
                                activeColor: const Color(0xFF0066CC),
                                onChanged: (val) => setState(() => _selectedProfile = val!),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _startInstallation,
                    child: const Text('Iniciar Instalação', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ] 
              // Tela de Progresso + Terminal Embutido
              else ...[
                Card(
                  color: const Color(0xFF2B2B2B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _currentStep,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0066CC)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 10,
                            backgroundColor: const Color(0xFF404040),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _hasError ? Colors.redAccent : const Color(0xFF0066CC),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Barra superior do Terminal
                InkWell(
                  onTap: () => setState(() => _isTerminalExpanded = !_isTerminalExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.terminal, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('Detalhes do Shell (Terminal em Tempo Real)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Icon(
                          _isTerminalExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),

                // Terminal Visual
                if (_isTerminalExpanded)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Text(
                            _logs[index],
                            style: const TextStyle(
                              color: Color(0xFF00FF66),
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(height: 16),

                if (_isFinished)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasError ? Colors.redAccent : const Color(0xFF0066CC),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Process.run('reboot', []),
                      child: Text(
                        _hasError ? 'Reiniciar Sistema (Falha Detectada)' : 'Concluir e Reiniciar Sistema',
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
