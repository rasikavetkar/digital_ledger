import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/party.dart';
import '../models/vehicle.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class PdfService {
  static Future<void> generatePartyInvoice(
    Party party,
    List<Vehicle> vehicles,
    List<Transaction> transactions,
  ) async {
    final pdf = pw.Document();

    final credit = transactions
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
    final debit = transactions
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = credit - debit;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Header banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('185FA5'),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Sand Transport Ledger',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Digital Ledger Report',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Party info block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Party Details',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Name: ${party.name}'),
                      if (party.phone != null && party.phone!.isNotEmpty)
                        pw.Text('Phone: ${party.phone}'),
                      pw.Text('Created: ${Formatters.formatDate(party.createdAt)}'),
                    ],
                  ),
                  // Summary box
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Total Credit: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text: Formatters.formatAmount(credit),
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('3B6D11'),
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Total Debit: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text: Formatters.formatAmount(debit),
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('A32D2D'),
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Net Balance: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text: Formatters.formatAmount(balance.abs()),
                                style: pw.TextStyle(
                                  color: PdfColor.fromHex('185FA5'),
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Vehicles list
              pw.Text(
                'Vehicles (${vehicles.length})',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                vehicles.isEmpty
                    ? 'No vehicles'
                    : vehicles.map((v) => '${v.number} (${v.type})').join(', '),
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 16),

              // Transactions table
              if (transactions.isNotEmpty) ...[
                pw.Text(
                  'Transactions',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>[
                      'Date',
                      'Vehicle',
                      'Qty (Loads)',
                      'Remarks',
                      'Type',
                      'Amount',
                    ],
                    ...transactions.map((t) {
                      final vehicle = vehicles.firstWhere(
                        (v) => v.id == t.vehicleId,
                        orElse: () => Vehicle(
                          id: -1,
                          number: 'Unknown',
                          partyId: party.id!,
                          type: 'Unknown',
                        ),
                      );
                      return [
                        Formatters.formatDate(t.date),
                        vehicle.number,
                        '${t.quantity}',
                        t.remarks ?? '-',
                        t.type.toUpperCase(),
                        Formatters.formatAmount(t.amount),
                      ];
                    }),
                  ],
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('185FA5'),
                  ),
                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.grey300,
                      ),
                    ),
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  cellHeight: 20,
                ),
                pw.SizedBox(height: 16),

                // Footer totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Total Credit: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text: Formatters.formatAmount(credit),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Total Debit: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text: Formatters.formatAmount(debit),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'Balance: ',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                              pw.TextSpan(
                                text: Formatters.formatAmount(balance.abs()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated by Digital Ledger App',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey,
                ),
              ),
              pw.Text(
                'Date: ${Formatters.formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Share the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${party.name}_ledger_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
