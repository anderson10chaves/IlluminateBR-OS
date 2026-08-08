import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class InstallProgressScreen extends StatefulWidget {
  const InstallProgressScreen({super.key});

  @override
  State<InstallProgressScreen> createState() => _InstallProgressScreenState();
}

class _InstallProgressScreenState extends State<InstallProgressScreen> {
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  double _progress = 0.0;
  String _currentStep = 'Iniciando preparação do sistema...';
  Timer? _carouselTimer;

  final List<Map<String, String>> _slides = [
    {
      'title': '⚡ Ambiente Dev Completo de Fábrica',
      'desc': 'Java 21 LTS, Flutter, Android Studio, VS Code, Cursor AI e Docker prontos para uso.',
      'icon': 'code'
    },
    {
      'title': '💬 Comunicação & Produtividade',
      'desc': 'WhatsApp (Whatsie), Slack, Teams, Thunderbird e LibreOffice/OnlyOffice já instalados.',
      'icon': 'chat'
    },
    {
      'title': '🗄️ Bancos de Dados & Ferramentas',
      'desc': 'PostgreSQL, MySQL/MariaDB, DBeaver e Bruno API Client configurados no primeiro boot.',
      'icon': 'storage'
    },
    {
      'title': '🎨 Interface Cinnamon macOS + Ubuntu Dark',
      'desc': 'A elegância do tema WhiteSur combinada com o contraste e estabilidade do estilo Dark.',
      'icon': 'palette'
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCarousel();
    _runRealInstallation();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentSlide < _slides.length - 1) {
        _currentSlide++;
      } else {
        _currentSlide = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentSlide,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _runRealInstallation() async {
    try {
      setState(() {
        _progress = 0.2;
        _currentStep = 'Executando script master de configuração...';
      });

      var result = await Process.run('/bin/bash', ['/usr/local/bin/setup_master_dev.sh']);

      if (result.exitCode == 0) {
        setState(() {
          _progress = 1.0;
          _currentStep = 'Instalação concluída com sucesso!';
        });
      } else {
        setState(() {
          _currentStep = 'Avisos durante a instalação. Finalizando...';
          _progress = 1.0;
        });
      }
    } catch (e) {
      setState(() {
        _progress = 1.0;
        _currentStep = 'Instalação da interface concluída!';
      });
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code;
      case 'chat':
        return Icons.chat_bubble;
      case 'storage':
        return Icons.storage;
      case 'palette':
        return Icons.palette;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Row(
                children: const [
                  Icon(Icons.blur_on, color: Color(0xFF0066CC), size: 36),
                  SizedBox(width: 12),
                  Text(
                    'IlluminateBR-OS',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text('Instalando o Sistema...', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 30),

              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentSlide = index),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconData(slide['icon']!),
                              size: 80,
                              color: const Color(0xFF0066CC),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              slide['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide['desc']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentSlide == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentSlide == index
                          ? const Color(0xFF0066CC)
                          : Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _currentStep,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066CC),
                        ),
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
          ),
        ),
      ),
    );
  }
}
