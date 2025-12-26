import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../data/models/cart_item_model.dart';

class PdfService {
  
  // Define Brand Colors
  static const PdfColor brandBlue = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor brandOrange = PdfColor.fromInt(0xFFFF6F00);
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFEEEEEE);

  // 1. GENERATE FILE
  Future<File> generatePdfFile(
    List<CartItem> items, 
    double totalAmount, 
    String orderId, 
    String customerName,
    {int sequenceNumber = 1}
  ) async {
    final pdf = pw.Document();
    
    // Use Helvetica for a clean, professional look
    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final now = DateTime.now();
    final dateStr = DateFormat('dd-MMM-yyyy').format(now);
    final displayOrderNo = orderId.padLeft(4, '0');

    // SORT ITEMS ALPHABETICALLY
    items.sort((a, b) => a.product.name.compareTo(b.product.name));

    // Helper: Logic for Alternate Quantity
    String calculateAltQty(CartItem item) {
      int? factor = item.product.conversionFactor;
      String? secUom = item.product.secondaryUom;

      if (factor == null || factor <= 1 || secUom == null || secUom.isEmpty) {
        return "-";
      }

      int totalBaseUnits = 0;
      if (item.uom == secUom) {
        totalBaseUnits = item.quantity * factor;
      } else {
        totalBaseUnits = item.quantity;
      }

      int major = totalBaseUnits ~/ factor; 
      int minor = totalBaseUnits % factor;  

      return "$major-$minor $secUom";
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return [
            // --- 1. HEADER SECTION ---
            pw.Column(
              children: [
                pw.Text("BAJRANG DISTRIBUTORS", 
                  style: pw.TextStyle(
                    font: fontBold, 
                    fontSize: 24, 
                    color: brandBlue
                  )
                ),
                pw.SizedBox(height: 4),
                pw.Text("General Order Estimate", 
                  style: pw.TextStyle(
                    font: fontRegular, 
                    fontSize: 12, 
                    letterSpacing: 2,
                    color: PdfColors.grey700
                  )
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: brandOrange, thickness: 2),
              ]
            ),
            pw.SizedBox(height: 20),

            // --- 2. INFO ROW (Customer & Order Details) ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Customer Details (Left)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("BILL TO:", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(customerName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: brandBlue)),
                  ]
                ),
                // Invoice Details (Right)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(children: [
                      pw.Text("Order No: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("#$displayOrderNo", style: pw.TextStyle(color: PdfColors.red)),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text("Date: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(dateStr),
                    ]),
                  ]
                )
              ]
            ),
            pw.SizedBox(height: 20),

            // --- 3. PRODUCT TABLE ---
            pw.TableHelper.fromTextArray(
              border: null, // No grid lines for cleaner look
              headerDecoration: const pw.BoxDecoration(color: brandBlue),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: lightGrey, width: 0.5))),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              cellStyle: const pw.TextStyle(fontSize: 10),
              
              // Column Alignments
              cellAlignments: {
                0: pw.Alignment.centerLeft,  // S.No
                1: pw.Alignment.centerLeft,  // Item
                2: pw.Alignment.center,      // Qty
                3: pw.Alignment.center,      // Alt
                4: pw.Alignment.center,      // Scheme
                5: pw.Alignment.centerRight, // Rate
                6: pw.Alignment.centerRight, // Amt
              },
              
              headers: ['S.No', 'Item Description', 'Qty', 'Alt Qty', 'Sch', 'Rate', 'Amount'],
              columnWidths: {
                0: const pw.FixedColumnWidth(30),  
                1: const pw.FlexColumnWidth(4),    
                2: const pw.FixedColumnWidth(50),  
                3: const pw.FixedColumnWidth(50),  
                4: const pw.FixedColumnWidth(40),  
                5: const pw.FixedColumnWidth(50),  
                6: const pw.FixedColumnWidth(60),  
              },
              data: List.generate(items.length, (index) {
                final item = items[index];
                return [
                  "${index + 1}",
                  item.product.name,
                  "${item.quantity} ${item.uom}", 
                  calculateAltQty(item), 
                  item.scheme, 
                  item.sellPrice.toStringAsFixed(0), 
                  item.total.toStringAsFixed(0),
                ];
              }),
            ),
            
            pw.SizedBox(height: 20),
            
            // --- 4. TOTAL SECTION ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: pw.BoxDecoration(
                    color: brandBlue,
                    borderRadius: pw.BorderRadius.circular(4)
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text("TOTAL:  ", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text("Rs. ${totalAmount.toStringAsFixed(0)}", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    ]
                  )
                )
              ]
            ),

            pw.Spacer(),
            
            // --- 5. FOOTER ---
            pw.Divider(color: lightGrey),
            pw.Center(
              child: pw.Text("Thank you for your business!", style: pw.TextStyle(color: PdfColors.grey, fontSize: 10, fontStyle: pw.FontStyle.italic))
            )
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Invoice_$displayOrderNo.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // 2. OPEN PDF (With Fallback)
  Future<void> openPdf(File file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      await Share.shareXFiles([XFile(file.path)], text: 'View Invoice');
    }
  }

  // 3. LEGACY SUPPORT
  Future<void> generateAndShareInvoice(
    List<CartItem> items, 
    double totalAmount, 
    String orderId, 
    String customerName,
    {int sequenceNumber = 1}
  ) async {
    final file = await generatePdfFile(items, totalAmount, orderId, customerName, sequenceNumber: sequenceNumber);
    await Share.shareXFiles([XFile(file.path)], text: 'Invoice $orderId');
  }
}