import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannnerHeader extends StatelessWidget {
  final MobileScannerController controller;
  const ScannnerHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(       //biar widjednya ga numpuk  ke atas ke notifcation bar
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(50)
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white,),
          ),
        ),
        Text(
          "Scanner",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold
          ),
        ), 
        //flashlight button
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, state, child) {
            final isOn = state.torchState == TorchState.on;
            return InkWell(
              onTap: () => controller.toggleTorch(),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOn ? Colors.yellowAccent.withValues(alpha: 0.8) : Colors.white24,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: isOn ? Colors.black : Colors.white,
                ),
              ),
            );
          },
        )
      ],
    ),
  ),
    );
  }
}