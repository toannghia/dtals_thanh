import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_toast.dart';

class EkycSubmitScreen extends StatefulWidget {
  const EkycSubmitScreen({super.key});

  @override
  State<EkycSubmitScreen> createState() => _EkycSubmitScreenState();
}

class _EkycSubmitScreenState extends State<EkycSubmitScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _step = 1; // 1: Front, 2: Back, 3: Selfie
  XFile? _frontImage;
  XFile? _backImage;
  XFile? _selfieImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _setCamera(_step == 3 ? 1 : 0); // Use front camera for selfie
    }
  }

  Future<void> _setCamera(int index) async {
    final oldController = _controller;
    
    // Set to null before awaiting disposal to trigger loading UI
    if (mounted) {
      setState(() {
        _controller = null;
      });
    }
    
    if (oldController != null) {
      await oldController.dispose();
    }
    
    final newController = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    _controller = newController;
    
    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String get _instruction {
    switch (_step) {
      case 1: return 'Chụp mặt trước CCCD';
      case 2: return 'Chụp mặt sau CCCD';
      case 3: return 'Chụp ảnh chân dung';
      default: return '';
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    final image = await _controller!.takePicture();
    setState(() {
      if (_step == 1) _frontImage = image;
      else if (_step == 2) _backImage = image;
      else if (_step == 3) _selfieImage = image;
    });
    
    _showSummary();
  }

  void _showSummary() {
    final XFile imageFile = _step == 1 ? _frontImage! : (_step == 2 ? _backImage! : _selfieImage!);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Xem lại ảnh', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: kIsWeb 
                ? Image.network(imageFile.path, height: 300, fit: BoxFit.cover)
                : Image.file(io.File(imageFile.path), height: 300, fit: BoxFit.cover),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Chụp lại'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (_step < 3) {
                        final nextStep = _step + 1;
                        setState(() {
                          _step = nextStep;
                        });
                        _setCamera(nextStep == 3 ? 1 : 0);
                      } else {
                        _submit();
                      }
                    },
                    child: Text(_step == 3 ? 'Gửi hồ sơ' : 'Tiếp theo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    // Navigate to status or show loading
    AppToast.show(context, 'Đang gửi hồ sơ eKYC...', type: AppToastType.info);
    if (context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 1 / _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          
          // Overlay Guide
          _buildOverlay(),
          
          // Bottom Controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _instruction,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _capture,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Back Button
          Positioned(
            top: 48,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          if (_step < 3)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.9 * 0.63,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.elliptical(200, 300)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
