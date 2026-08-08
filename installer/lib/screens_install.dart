import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class InstallProgressScreen extends StatefulWidget {
  const InstallProgressScreen({super.key});

  @override
  State<InstallProgressScreen> createState() => _InstallProgressScreenState();
}

class _InstallProgressScreenState extends State<InstallProgressScreen> {
  String _selectedProfile = 'devops'; // Padrão: Dev + DevOps
  bool _isInstalling = false;
  double _progress = 0.0;
  String _currentStep = 'Aguardando seleção do perfil...';

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

  Future<void> _startInstallation() async {
    setState(() {
      _isInstalling = true;
      _progress = 0.2;
      _currentStep = 'Iniciando instalação no perfil: ${_profiles[_selectedProfile]!['title']}...';
    });

    try {
      // Passa o perfil como argumento para o script Bash
      var result = await Process.run('/bin/bash', [
        '/usr/local/bin/setup_master_dev.sh',
        _selectedProfile
      ]);

      if (result.exitCode == 0) {
        setState(() {
          _progress = 1.0;
          _currentStep = 'Instalação concluída com sucesso!';
        });
      } else {
        setState(() {
          _progress = 1.0;
          _currentStep = 'Instalação finalizada com alguns avisos.';
        });
      }
    } catch (e) {
      setState(() {
        _progress = 1.0;
        _currentStep = 'Modo de demonstração: Instalação simulada!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.blur_on, color: Color(0xFF0066CC), size: 36),
                  SizedBox(width: 12),
                  Text(
                    'IlluminateBR-OS',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Spacer(),
                  Text('Instalador Personalizado', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 30),

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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: const Text('Iniciar Instalação', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                )
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0066CC)),
                        SizedBox(height: 24),
                        Text(
                          'Instalando o IlluminateBR-OS...',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _currentStep,
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0066CC)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0066CC)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
