import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:idn_pos/models/products.dart';
import 'package:idn_pos/screens/cashier/components/checkout_panel.dart';
import 'package:idn_pos/screens/cashier/components/printer_selector.dart';
import 'package:idn_pos/screens/cashier/components/product_card.dart';
import 'package:idn_pos/screens/cashier/components/qr_result_modal.dart';
import 'package:idn_pos/utils/currency_format.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevices;
  bool _connected = false;
  final Map<Product, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  // LOGIKA BLUETOOTH
  Future<void> _initBluetooth() async {
    // meminta IZIINN lokasi dan bluetooth ke hp (wajib)
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();

    List<BluetoothDevice> devices = [
      // list ini akan otomatis terisi, jika BT di hp menyala, dan sudah ada device yang siap dikoneksikan
    ];
    try {
      devices = await bluetooth.getBondedDevices(); // jika ada yg siap 
    } catch (e) {
      debugPrint("Error Bluetooth: $e");
    }

    if (mounted) {
      setState(() {
        _devices = devices;
      });
    }

     bluetooth.onStateChanged().listen((State){
      if (mounted) {
        setState(() {
          _connected = State == BlueThermalPrinter.CONNECTED;
        });
      }
     });
  }

void _connectToDevice(BluetoothDevice? device){
  // if (kondisi) utama, yang mempelopori if-if selanjutnya
    if(device != null){
      bluetooth.isConnected.then((isConnected){
        // if yg merupakan anak/ cabang utama dari if utama.
        // if ini memiliki sebuah kondisi yang menjawab pertanyaan/statement dari kondisi utama
        if(isConnected = false){
          bluetooth.connect(device).catchError((error){
            // if ini wajib memiliki opini yang sama, seperti if kedua
            if(mounted) setState(() => _connected = false); // kl device aktif tp ga connect
          });
          // statement dalam if ini akan dijalankan ketika if-if sblmnya tidak terpenuhi
          // atau if ini adalah opsi terakhir yg akan dijalankan ketika if-if sblmnya tdk terpenuhi(tdk berjalan)
          if(mounted) setState(() => _selectedDevices = device); // akan dijalankan jika device aktif dan connect
        }
      });
    }
  }

  // LOGIKA ADD TO CART
  void _addToCart(Product product) { // meng handle action ktika user menambah product ke keranjang
    setState(() {
      _cart.update(
        // utk mendefinisikan product yg ada di menu
       product,
       // logika matematis, yang dijalankan ketika 1 product sudah berada di keranjang, dan user klik +, yg nantinya jumlahnya akan ditambah 1
       (value) => value + 1,
       // jika user tidak menambahkan lagi jumlah product(jumlah hanya 1) dikeranjang, maka default jumlah dari barang tsb adalah 1
       ifAbsent: () => 1);
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product) && _cart[product]! > 1) {
        _cart[product] = _cart[product]! - 1;
      } else {
        _cart.remove(product);
      }
    });
  }

  int _calculateTotal() {
    int total = 0;
    _cart.forEach((key, value) => total += (key.price * value));
    return total;
  }

  // LOGIKA PRINTING
  void _handlePrint() async {
    int total = _calculateTotal();
    if (total == 0) {
      ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text("Keranjang masih kosong!"))); // printer udh siap tp keranjang masi kosong
    }

    String trxId = "TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    String qrData = "PAY:$trxId:$total";
    bool isPrinting = false;

    // menyiapkan tanggal saat ini (current date)
    DateTime now = DateTime.now(); // waktu saat ini
    String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(now); // utk menyimpan tgl yg sudah diformat

    // LAYOUTING STRUK
    if (_selectedDevices !=null && await bluetooth.isConnected == true) {
      // header struk
      bluetooth.printNewLine(); 
      bluetooth.printCustom("IDN CAFE", 3, 1); // judul besar (center)
      bluetooth.printNewLine();
      bluetooth.printCustom("Jl. Bagus Dayeuh", 1, 1); // alamat (center)

      //tanggal dan ID
      bluetooth.printNewLine();
      bluetooth.printLeftRight("Waktu:", formattedDate, 1);

      //daftar items
      bluetooth.printCustom("--------------------------------", 1, 1);
      _cart.forEach((product,qty){
        String priceTotal = formatRupiah(product.price * qty);
        //cetak nama barang di kali qty
        bluetooth.printLeftRight("${product.name} x${qty}", priceTotal, 1);
      });
      bluetooth.printCustom("--------------------------------", 1, 1);

      // total & QR 
      bluetooth.printLeftRight("TOTAL", formatRupiah(total), 3);
      bluetooth.printNewLine();
      bluetooth.printCustom("Scan QR dibawah:", 1, 1);
      bluetooth.printQRcode(qrData, 200, 200, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom("Thank you", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();

      isPrinting = true;
    }

    // utk menampilkan modal hasil QR code  (pop up)
    _showQRModal(qrData, total, isPrinting);
  }

  void _showQRModal(String qrData, int total, bool isPrinting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrResultModal(  // simodal isinya apa
        qrData: qrData,
        total: total,
        isPrinting: isPrinting,
        onClose: () => Navigator.pop(context),
      ) 
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Menu Kasir",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // dropdown select printer
          PrinterSelector(
            devices: _devices,
            selectedDevice: _selectedDevices,
            isConnected: _connected,
            onSelected: _connectToDevice,
          ),

          //grid for product list
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 kotak samping
                childAspectRatio: 0.8,
                crossAxisSpacing: 15, // spacing secara horizontal
                mainAxisExtent: 15,
              ),
              itemCount: menus.length, // .length = ngambil seluruh data menunya
              itemBuilder: (context, index) {
                final product = menus[index];
                final qty = _cart[product] ?? 0; // default quantity = 0

                // pemanggilan product list pada product cart
                return ProductCard(
                  product: product,
                  qty: qty,
                  onAdd: () => _addToCart(product),
                  onRemove: () => _removeFromCart(product),

                );
              },
            ),
          ),

          //bottom sheet panel
          CheckoutPanel(
            total: _calculateTotal(),
            onPressed: _handlePrint,
          )
        ],
      ),
    );
  }
}