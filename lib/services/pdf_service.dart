import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/party.dart';
import '../models/vehicle.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

// ─── Colour palette (mirrors AppColors) ───────────────────────────────────────
const _blue = PdfColor.fromInt(0xFF185FA5);
const _creditBg = PdfColor.fromInt(0xFFEAF3DE);
const _creditText = PdfColor.fromInt(0xFF3B6D11);
const _debitBg = PdfColor.fromInt(0xFFFCEBEB);
const _debitText = PdfColor.fromInt(0xFFA32D2D);
const _rowAlt = PdfColor.fromInt(0xFFF5F5F5); // light-grey alternating row

class PdfService {
  /// Generates a party invoice PDF and opens the native share sheet.
  static Future<void> generatePartyInvoice(
    Party party,
    List<Vehicle> vehicles,
    List<Transaction> transactions,
  ) async {
    final pdf = pw.Document();

    // ── Totals ────────────────────────────────────────────────────────────────
    final credit = transactions
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
    final debit = transactions
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = credit - debit;

    // ── Helper: look-up vehicle number for a transaction ──────────────────────
    String vehicleNumber(Transaction t) {
      if (t.vehicleId == null) return '-';
      return vehicles
          .firstWhere(
            (v) => v.id == t.vehicleId,
            orElse: () => Vehicle(
              id: -1,
              number: '-',
              partyId: party.id ?? -1,
              type: '-',
            ),
          )
          .number;
    }

    // ── Build the transaction table rows (header + data + footer totals) ──────
    pw.Widget _buildTransactionTable() {
      // Column flex widths (total = 24)
      const colWidths = {
        0: pw.FlexColumnWidth(3.0), // Date
        1: pw.FlexColumnWidth(4.0), // Vehicle No.
        2: pw.FlexColumnWidth(2.5), // Qty
        3: pw.FlexColumnWidth(5.5), // Remarks
        4: pw.FlexColumnWidth(2.0), // Type
        5: pw.FlexColumnWidth(4.0), // Amount
      };

      // ── header row ──
      pw.TableRow _headerRow() {
        final labels = ['Date', 'Vehicle No.', 'Qty\n(Loads)', 'Remarks', 'Type', 'Amount'];
        return pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blue),
          children: labels
              .map(
                (label) => _cell(
                  label,
                  bold: true,
                  color: PdfColors.white,
                  align: pw.TextAlign.center,
                  vertPad: 6,
                ),
              )
              .toList(),
        );
      }

      // ── data rows with alternating background ──
      List<pw.TableRow> _dataRows() {
        return List.generate(transactions.length, (i) {
          final t = transactions[i];
          final isAlt = i.isOdd;
          final bg = isAlt ? _rowAlt : PdfColors.white;
          final isCr = t.type == 'credit';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: bg,
              border: const pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            children: [
              _cell(Formatters.formatDate(t.date), fontSize: 8),
              _cell(vehicleNumber(t), fontSize: 8),
              _cell(
                t.quantity % 1 == 0
                    ? t.quantity.toInt().toString()
                    : t.quantity.toString(),
                fontSize: 8,
                align: pw.TextAlign.center,
              ),
              _cell(t.remarks ?? '-', fontSize: 8),
              _cell(
                isCr ? 'CR' : 'DR',
                bold: true,
                fontSize: 8,
                color: isCr ? _creditText : _debitText,
                align: pw.TextAlign.center,
              ),
              _cell(
                Formatters.formatAmount(t.amount),
                fontSize: 8,
                align: pw.TextAlign.right,
              ),
            ],
          );
        });
      }

      // ── footer totals row ──
      pw.TableRow _footerRow() {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blue),
          children: [
            _cell('Totals', bold: true, color: PdfColors.white, colSpan: 1, fontSize: 8),
            _cell('', colSpan: 1),                        // Vehicle
            _cell('', colSpan: 1),                        // Qty
            _cell(
              'CR: ${Formatters.formatAmount(credit)}',
              bold: true,
              color: PdfColors.white,
              fontSize: 8,
            ),
            _cell(
              'DR: ${Formatters.formatAmount(debit)}',
              bold: true,
              color: PdfColors.white,
              fontSize: 8,
            ),
            _cell(
              Formatters.formatAmount(balance.abs()),
              bold: true,
              color: PdfColors.white,
              align: pw.TextAlign.right,
              fontSize: 8,
            ),
          ],
        );
      }

      return pw.Table(
        columnWidths: colWidths,
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        children: [
          _headerRow(),
          ..._dataRows(),
          _footerRow(),
        ],
      );
    }

    // ── MultiPage – handles overflow automatically ─────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildHeader(party),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),

          // ── Party info + Summary box ──────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: party details + vehicles
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Party Details'),
                    pw.SizedBox(height: 6),
                    _infoRow('Name', party.name),
                    if (party.phone != null && party.phone!.isNotEmpty)
                      _infoRow('Phone', party.phone!),
                    _infoRow('Since', Formatters.formatDate(party.createdAt)),
                    pw.SizedBox(height: 10),
                    _sectionLabel('Vehicles (${vehicles.length})'),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      vehicles.isEmpty
                          ? 'No vehicles registered'
                          : vehicles.map((v) => '${v.number} (${v.type})').join(' • '),
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(width: 16),

              // Right: summary box
              pw.Container(
                width: 160,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  children: [
                    // Total Credit
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: const pw.BoxDecoration(
                        color: _creditBg,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(5),
                          topRight: pw.Radius.circular(5),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Total Credit',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            Formatters.formatAmount(credit),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: _creditText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Total Debit
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: const pw.BoxDecoration(color: _debitBg),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Total Debit',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            Formatters.formatAmount(debit),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: _debitText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Net Balance
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(5),
                          bottomRight: pw.Radius.circular(5),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Net Balance',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${balance >= 0 ? '' : '-'}${Formatters.formatAmount(balance.abs())}',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: _blue,
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

          pw.SizedBox(height: 20),

          // ── Transactions table ─────────────────────────────────────────────
          _sectionLabel('Transactions (${transactions.length})'),
          pw.SizedBox(height: 8),
          if (transactions.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 20),
                child: pw.Text(
                  'No transactions recorded.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            )
          else
            _buildTransactionTable(),

          pw.SizedBox(height: 20),
        ],
      ),
    );

    // ── Share / Print ──────────────────────────────────────────────────────────
    final bytes = await pdf.save();
    final filename =
        '${party.name.replaceAll(' ', '_')}_ledger_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ─── Page header (repeated on every page) ─────────────────────────────────
  static pw.Widget _buildHeader(Party party) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const pw.BoxDecoration(color: _blue),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Sand Transport Ledger',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                party.name,
                style: pw.TextStyle(
                  color: PdfColor.fromInt(0xB3FFFFFF),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          pw.Text(
            Formatters.formatDate(DateTime.now()),
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ─── Page footer (repeated on every page) ─────────────────────────────────
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Digital Ledger App',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  // ─── Reusable helpers ──────────────────────────────────────────────────────

  static pw.Widget _sectionLabel(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _blue,
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  /// Single table cell – padding + optional styling
  static pw.Widget _cell(
    String text, {
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 9,
    double vertPad = 5,
    int colSpan = 1,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 5, vertical: vertPad),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
