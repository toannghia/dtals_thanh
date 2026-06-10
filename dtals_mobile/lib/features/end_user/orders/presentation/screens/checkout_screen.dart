import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../../../../core/widgets/app_toast.dart';

class CheckoutScreen extends StatefulWidget {
  final String url;
  const CheckoutScreen({super.key, required this.url});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  WebViewController? _controller;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.contains('payment-success') || request.url.contains('success')) {
              context.replace('/user/payment-result?status=success');
              return NavigationDecision.prevent;
            }
            if (request.url.contains('payment-fail') || request.url.contains('cancel')) {
              context.replace('/user/payment-result?status=fail');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _saveQRImage() async {
    setState(() => _isSaving = true);
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 100));
      if (image != null) {
        final result = await ImageGallerySaverPlus.saveImage(
          image,
          quality: 100,
          name: "QR_Payment_${DateTime.now().millisecondsSinceEpoch}",
        );
        if (mounted) {
          if (result['isSuccess'] == true) {
            AppToast.show(context, 'Đã lưu ảnh QR vào thư viện thành công', type: AppToastType.success);
          } else {
            AppToast.show(context, 'Lưu ảnh QR thất bại', type: AppToastType.error);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Lỗi khi lưu ảnh: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final uri = Uri.tryParse(widget.url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Mở trang thanh toán'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        actions: [
          if (!kIsWeb)
            TextButton.icon(
              icon: _isSaving 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download, color: Colors.white),
              label: const Text('Lưu ảnh QR', style: TextStyle(color: Colors.white)),
              onPressed: _isSaving ? null : _saveQRImage,
            )
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}
