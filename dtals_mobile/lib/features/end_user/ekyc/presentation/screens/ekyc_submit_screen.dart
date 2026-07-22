import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../data/ekyc_repository.dart';

class EkycSubmitScreen extends StatefulWidget {
  const EkycSubmitScreen({super.key});

  @override
  State<EkycSubmitScreen> createState() => _EkycSubmitScreenState();
}

class _EkycSubmitScreenState extends State<EkycSubmitScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _step = 1; // 1: Front, 2: Back, 3: Selfie
  XFile? _frontImage;
  XFile? _backImage;
  XFile? _selfieImage;
  bool _isFlashOn = false;

  // ML Kit Face Detection
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  bool _isProcessing = false;
  bool _isAutoCapturing = false;
  bool _isFaceDetected = false;
  String _faceInstruction = 'Vui lòng đưa khuôn mặt vào khung hình';
  
  // Smart Guidance and Countdown
  int _countdown = 0;
  Timer? _countdownTimer;
  Timer? _stabilizationTimer;
  
  // Throttling frames
  int _lastProcessingTime = 0;

  // Animation for scanning effect
  late AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _setCamera(_step == 3 ? 1 : 0);
      }
    } catch (e) {
      debugPrint('Error getting cameras: $e');
      if (mounted) {
        setState(() {
          _faceInstruction = 'Không tìm thấy camera hoặc bị từ chối quyền.';
        });
      }
    }
  }

  Future<void> _setCamera(int index) async {
    final oldController = _controller;
    
    if (mounted) {
      setState(() {
        _controller = null;
        _isFaceDetected = false;
        _isAutoCapturing = false;
      });
    }
    
    if (oldController != null) {
      if (oldController.value.isStreamingImages) {
        await oldController.stopImageStream();
      }
      await oldController.dispose();
    }
    
    if (_cameras == null || _cameras!.isEmpty) return;
    
    // Fallback to index 0 if the requested camera index is not available (e.g. laptops with only 1 webcam)
    final int safeIndex = index < _cameras!.length ? index : 0;

    final preset = _step == 3 ? ResolutionPreset.medium : ResolutionPreset.high;

    final newController = CameraController(
      _cameras![safeIndex],
      preset,
      enableAudio: false,
      imageFormatGroup: kIsWeb ? ImageFormatGroup.jpeg : (defaultTargetPlatform == TargetPlatform.android ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888),
    );
    
    _controller = newController;
    
    try {
      await _controller!.initialize();
      if (!kIsWeb) {
        try {
          await _controller!.setFocusMode(FocusMode.auto);
          if (_isFlashOn) {
            await _controller!.setFlashMode(FlashMode.torch);
          } else {
            await _controller!.setFlashMode(FlashMode.off);
          }
        } catch (e) {
          debugPrint('Flash/Focus not supported: $e');
        }
      }
      
      if (!mounted) return;

      if (_step == 3 && !kIsWeb) {
        // Start face detection stream. Not supported on Web.
        try {
          await _controller!.startImageStream(_processCameraImage);
        } catch (e) {
          debugPrint('Failed to start image stream: $e');
        }
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !mounted || _isAutoCapturing) return;
    
    // OPTIMIZATION: Process max 3 frames per second (throttle 333ms)
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - _lastProcessingTime < 333) return;
    
    _lastProcessingTime = currentTime;
    _isProcessing = true;

    try {
      if (kIsWeb) {
        // ML Kit does not support Flutter Web. Fallback to manual capture.
        if (mounted && _step == 3) {
           setState(() {
              _isFaceDetected = false;
              _faceInstruction = 'Trên Web, vui lòng bấm nút chụp thủ công';
           });
        }
        return;
      }

      final camera = _cameras![1]; // front camera
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      if (imageRotation == null) {
        _isProcessing = false;
        return;
      }

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
      
      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isNotEmpty) {
        final face = faces.first;
        final box = face.boundingBox;
        
        final double imgW = imageSize.width;
        final double imgH = imageSize.height;
        
        final double faceSize = math.max(box.width, box.height);
        final double minImgDim = math.min(imgW, imgH);
        
        // Smart position checking (Ultra Loose)
        // Face size should be between 20% and 70% of the minimum dimension
        if (faceSize < minImgDim * 0.20) {
          _handleFaceGuidance('Lại gần màn hình hơn', false);
        } else if (faceSize > minImgDim * 0.70) {
          _handleFaceGuidance('Lùi ra xa một chút', false);
        } else {
          // Centering check: Face center must be within the middle 60% of the screen (Very loose!)
          final double centerX = box.left + box.width / 2;
          final double centerY = box.top + box.height / 2;
          
          if (centerX < imgW * 0.20 || centerX > imgW * 0.80 ||
              centerY < imgH * 0.20 || centerY > imgH * 0.80) {
            _handleFaceGuidance('Di chuyển mặt vào giữa khung', false);
          } else {
            _handleFaceGuidance('✅ Giữ nguyên vị trí...', true);
          }
        }
      } else {
        _handleFaceGuidance('Vui lòng đưa khuôn mặt vào khung hình', false);
      }
    } catch (e) {
      debugPrint('ML Kit error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _handleFaceGuidance(String guidance, bool isPerfect) {
    if (!mounted) return;
    
    // If we are currently counting down, ignore minor deviations
    if (_countdown > 0) {
      if (!isPerfect) {
        _cancelCaptureSequence();
        setState(() {
          _faceInstruction = guidance;
          _isFaceDetected = false;
        });
      }
      return;
    }

    setState(() {
      _faceInstruction = guidance;
      _isFaceDetected = isPerfect;
    });

    if (isPerfect) {
      if (_stabilizationTimer == null) {
        // Wait 1 second before starting countdown
        _stabilizationTimer = Timer(const Duration(milliseconds: 1000), () {
          _startCountdown();
        });
      }
    } else {
      _cancelCaptureSequence();
    }
  }

  void _cancelCaptureSequence() {
    _stabilizationTimer?.cancel();
    _stabilizationTimer = null;
    if (_countdown > 0) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      if (mounted) {
        setState(() {
          _countdown = 0;
        });
      }
    }
  }

  void _startCountdown() {
    if (!mounted || _countdownTimer != null) return;
    setState(() {
      _countdown = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        _countdownTimer = null;
        if (_controller != null && _controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _capture();
      }
    });
  }

  @override
  void dispose() {
    _cancelCaptureSequence();
    _scanAnimationController.dispose();
    _faceDetector.close();
    _controller?.dispose();
    super.dispose();
  }

  String get _instruction {
    switch (_step) {
      case 1: return 'Chụp mặt trước CCCD';
      case 2: return 'Chụp mặt sau CCCD';
      case 3: return _faceInstruction;
      default: return '';
    }
  }

  Color get _instructionColor {
    if (_step < 3) return Colors.white;
    if (_faceInstruction == 'Vui lòng đưa khuôn mặt vào khung hình') return Colors.white;
    if (_faceInstruction.contains('Giữ nguyên vị trí')) return Colors.greenAccent;
    return Colors.yellowAccent;
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (kIsWeb) return; // Web does not support flash
    
    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    if (_step == 3 && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
    
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
    
    final double cropRatio = _step < 3 ? 1.58 : 0.7; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24, left: 24, right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Xem lại ảnh', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(_step < 3 ? 12 : 1000),
                child: AspectRatio(
                  aspectRatio: cropRatio,
                  child: kIsWeb 
                    ? Image.network(imageFile.path, fit: BoxFit.cover)
                    : Image.file(io.File(imageFile.path), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (_step == 3) {
                         _setCamera(1);
                      }
                    },
                    child: const Text('Chụp lại'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                    child: Text(_step == 3 ? 'Gửi hồ sơ' : 'Tiếp theo', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _submit() async {
    if (_frontImage == null || _backImage == null || _selfieImage == null) {
      AppToast.show(context, 'Vui lòng chụp đầy đủ ảnh', type: AppToastType.warning);
      return;
    }

    AppToast.show(context, 'Đang gửi hồ sơ eKYC...', type: AppToastType.info);

    try {
      final repository = EkycRepository();
      await repository.submitKyc(
        frontPath: _frontImage!.path,
        backPath: _backImage!.path,
        selfiePath: _selfieImage!.path,
      );

      if (context.mounted) {
        AppToast.show(context, 'Gửi hồ sơ thành công!', type: AppToastType.success);
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        String errorMsg = 'Có lỗi xảy ra, vui lòng thử lại.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          } else if (e.response?.statusCode == 401) {
            errorMsg = 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại.';
          } else if (e.response?.statusCode != null) {
            errorMsg = 'Lỗi server (${e.response?.statusCode}), vui lòng thử lại sau.';
          }
        }
        AppToast.show(context, errorMsg, type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          Center(
            child: AspectRatio(
              aspectRatio: 1 / _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          
          // Overlay Guide (Custom Paint)
          CustomPaint(
            painter: _step < 3 
                ? IdCardOverlayPainter() 
                : FaceOverlayPainter(
                    isFaceDetected: _isFaceDetected,
                    animationValue: _scanAnimationController.value,
                    borderColor: _instructionColor,
                  ),
            child: Container(),
          ),
          
          // Big Countdown Text in Center
          if (_step == 3 && _countdown > 0)
            Center(
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 4)),
                  ],
                ),
              ),
            ),

          // Top Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Bước $_step/3',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 28),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),

          // Instruction Text Move to TOP
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _instruction,
                  style: TextStyle(
                    color: _instructionColor, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_step < 3)
                  GestureDetector(
                    onTap: _capture,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  // Manual capture fallback for selfie just in case
                  GestureDetector(
                    onTap: _capture,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _isFaceDetected ? Colors.greenAccent : Colors.white54, width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: _isFaceDetected ? Colors.greenAccent.withOpacity(0.5) : Colors.white30,
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CUSTOM PAINTERS FOR OVERLAYS
// ---------------------------------------------------------------------------

class IdCardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    
    // Calculate ID card rect (ratio 8.56 / 5.398 ~ 1.58)
    final double cardWidth = size.width * 0.85;
    final double cardHeight = cardWidth / 1.58;
    final double left = (size.width - cardWidth) / 2;
    final double top = (size.height - cardHeight) / 2;
    
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cardWidth, cardHeight),
      const Radius.circular(16),
    );
    
    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(rrect);
    final overlayPath = Path.combine(PathOperation.difference, bgPath, holePath);
    
    // Draw background with hole
    canvas.drawPath(overlayPath, paint);
    
    // Draw corners
    paint.blendMode = BlendMode.srcOver;
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    
    const double cornerLength = 30;
    
    // Top-left
    canvas.drawPath(Path()..moveTo(left, top + cornerLength)..lineTo(left, top)..lineTo(left + cornerLength, top), paint);
    // Top-right
    canvas.drawPath(Path()..moveTo(left + cardWidth - cornerLength, top)..lineTo(left + cardWidth, top)..lineTo(left + cardWidth, top + cornerLength), paint);
    // Bottom-left
    canvas.drawPath(Path()..moveTo(left, top + cardHeight - cornerLength)..lineTo(left, top + cardHeight)..lineTo(left + cornerLength, top + cardHeight), paint);
    // Bottom-right
    canvas.drawPath(Path()..moveTo(left + cardWidth - cornerLength, top + cardHeight)..lineTo(left + cardWidth, top + cardHeight)..lineTo(left + cardWidth, top + cardHeight - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FaceOverlayPainter extends CustomPainter {
  final bool isFaceDetected;
  final double animationValue;
  final Color borderColor;

  FaceOverlayPainter({
    required this.isFaceDetected, 
    required this.animationValue,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    
    // Face Oval
    final double ovalWidth = size.width * 0.7;
    final double ovalHeight = size.height * 0.5;
    final double left = (size.width - ovalWidth) / 2;
    final double top = (size.height - ovalHeight) / 2;
    
    final rect = Rect.fromLTWH(left, top, ovalWidth, ovalHeight);
    
    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addOval(rect);
    final overlayPath = Path.combine(PathOperation.difference, bgPath, holePath);
    
    // Draw background with hole
    canvas.drawPath(overlayPath, paint);
    
    // Draw border
    paint.blendMode = BlendMode.srcOver;
    paint.color = borderColor;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    
    // Draw dashed or solid oval
    canvas.drawOval(rect, paint);
    
    // Draw scanning line if face is not detected
    if (!isFaceDetected) {
      final lineY = top + (ovalHeight * animationValue);
      paint.color = Colors.white;
      paint.strokeWidth = 2;
      
      final a = ovalWidth / 2;
      final b = ovalHeight / 2;
      final dy = lineY - (top + b);
      if (dy.abs() < b) {
        final dx = a * (1 - (dy * dy) / (b * b));
        if (dx > 0) {
          canvas.drawLine(Offset(left + 20, lineY), Offset(left + ovalWidth - 20, lineY), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.isFaceDetected != isFaceDetected || 
           oldDelegate.animationValue != animationValue ||
           oldDelegate.borderColor != borderColor;
  }
}
