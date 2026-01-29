import 'package:flutter/material.dart';
import 'package:idn_pos/screens/scanner/components/payment_modal.dart';
import 'package:idn_pos/screens/scanner/components/scanner_header.dart';
import 'package:idn_pos/screens/scanner/components/scanner_overlay.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // untuk membuat detectionnya ini tidak ada delay
    returnImage: false
  );

  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack( // menumpuk widget
        children: [
          // CAMERA SCANNER
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isScanned) return;
              // kondisi yg ada diperulangan for adalah kondisi ketik QRcode sudah berhasil dicapture oleh kamera
              for (final barcode in capture.barcodes) {
                _handleQrCode(barcode.rawValue);
              }
            },
          ),
          
          ScannerOverlay(),
          ScannnerHeader(controller: controller),
        ],
      ),
    );
  }

  void _handleQrCode(String? code) {
    if (code != null) {
      if (code.startsWith("PAY:")) {
        //qr code valid
        setState(() {
          _isScanned = true;

          final parts = code.split(":");
          final id = parts[1]; 
          final total = int.tryParse(parts[2]) ?? 0;

          _showPaymentModal(id, total);
        });
      } else{
        // qr tidak valid
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner(); // menghindari/ngumpetin snackbar yang aktif/muncul
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outlined, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text("QR tidak dikenali $code", overflow: TextOverflow.ellipsis)),             
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
            duration: Duration(milliseconds: 1000),
          )
        );

      }
    }
  }

  void _showPaymentModal(String id, int total) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (paymentContext) => PaymentModal(
        id: id,
        total: total,
        // ini bayar
        onPay: () {
          Navigator.pop(paymentContext);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Pembayaran berhasil"),
              backgroundColor: Colors.green,
            )
          );
        },
        // cancel pembayaran
        onCancel: () {
          Navigator.pop(paymentContext);
          setState(() {
            _isScanned =false; // utk meriset state agar bisa scan lagi dr awal

          });
        },
      ) 
    ).then((_) { //anon and private
      if (_isScanned) setState(() => _isScanned = false);
    }); //utk meyakinkan bahwa ini udh ke reset
  }
}