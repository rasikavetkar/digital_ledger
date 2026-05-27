import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
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
    // Load Roboto from Google Fonts to support Unicode characters like "₹"
    final robotoRegular = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();
    final robotoItalic = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: robotoRegular,
        bold: robotoBold,
        italic: robotoItalic,
      ),
    );

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
    pw.Widget buildTransactionTable() {
      // Column flex widths (total = 24)
      const colWidths = {
        0: pw.FlexColumnWidth(2.5), // Date
        1: pw.FlexColumnWidth(10.0), // Details (Vehicle, Remarks, Qty)
        2: pw.FlexColumnWidth(3.8), // Debit(-)
        3: pw.FlexColumnWidth(3.8), // Credit(+)
        4: pw.FlexColumnWidth(3.9), // Balance
      };

      // ── header row ──
      pw.TableRow headerRow() {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blue),
          children: [
            _cell('Date', bold: true, color: PdfColors.white, align: pw.TextAlign.left, vertPad: 6),
            _cell('Details', bold: true, color: PdfColors.white, align: pw.TextAlign.left, vertPad: 6),
            _cell('Debit(-)', bold: true, color: PdfColors.white, align: pw.TextAlign.right, vertPad: 6),
            _cell('Credit(+)', bold: true, color: PdfColors.white, align: pw.TextAlign.right, vertPad: 6),
            _cell('Balance', bold: true, color: PdfColors.white, align: pw.TextAlign.right, vertPad: 6),
          ],
        );
      }

      // ── Group and build rows chronologically with running balance and monthly totals ──
      final sortedTxns = List<Transaction>.from(transactions)
        ..sort((a, b) => a.date.compareTo(b.date));

      final dataRows = <pw.TableRow>[];
      double runningBalance = 0.0;
      int? currentMonth;
      int? currentYear;
      double monthDebit = 0.0;
      double monthCredit = 0.0;

      void addMonthTotalRow(int month, int year, double deb, double cred) {
        final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));
        dataRows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _rowAlt),
            children: [
              _cell('', fontSize: 8),
              _cell('$monthName Total', bold: true, fontSize: 8),
              _cell(
                deb > 0 ? Formatters.formatAmount(deb) : '0.00',
                bold: true,
                fontSize: 8,
                align: pw.TextAlign.right,
              ),
              _cell(
                cred > 0 ? Formatters.formatAmount(cred) : '0.00',
                bold: true,
                fontSize: 8,
                align: pw.TextAlign.right,
              ),
              _cell('', fontSize: 8),
            ],
          ),
        );
      }

      for (int i = 0; i < sortedTxns.length; i++) {
        final t = sortedTxns[i];

        // Check if month/year changed to insert the previous month's total row
        if (currentMonth != null && (t.date.month != currentMonth || t.date.year != currentYear)) {
          addMonthTotalRow(currentMonth, currentYear!, monthDebit, monthCredit);
          monthDebit = 0.0;
          monthCredit = 0.0;
        }

        currentMonth = t.date.month;
        currentYear = t.date.year;

        final isCr = t.type == 'credit';
        if (isCr) {
          runningBalance += t.amount;
          monthCredit += t.amount;
        } else {
          runningBalance -= t.amount;
          monthDebit += t.amount;
        }

        final isAlt = i.isOdd;
        final bg = isAlt ? _rowAlt : PdfColors.white;
        final vNum = vehicleNumber(t);
        final details = 'Vehicle: $vNum (${t.quantity % 1 == 0 ? t.quantity.toInt() : t.quantity} loads)${t.remarks != null && t.remarks!.isNotEmpty ? ' | ${t.remarks}' : ''}';

        dataRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: bg,
              border: const pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            children: [
              _cell(DateFormat('dd MMM').format(t.date), fontSize: 8),
              _cell(details, fontSize: 8),
              _cell(
                !isCr ? Formatters.formatAmount(t.amount) : '-',
                fontSize: 8,
                color: !isCr ? _debitText : null,
                align: pw.TextAlign.right,
              ),
              _cell(
                isCr ? Formatters.formatAmount(t.amount) : '-',
                fontSize: 8,
                color: isCr ? _creditText : null,
                align: pw.TextAlign.right,
              ),
              _cell(
                '${Formatters.formatAmount(runningBalance.abs())} ${runningBalance >= 0 ? 'Cr' : 'Dr'}',
                fontSize: 8,
                bold: true,
                color: runningBalance >= 0 ? _creditText : _debitText,
                align: pw.TextAlign.right,
              ),
            ],
          ),
        );
      }

      // Add final month's total row
      if (currentMonth != null) {
        addMonthTotalRow(currentMonth, currentYear!, monthDebit, monthCredit);
      }

      // ── footer totals row ──
      pw.TableRow footerRow() {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(color: _blue),
          children: [
            _cell('Totals', bold: true, color: PdfColors.white, fontSize: 8),
            _cell('No. of Entries: ${transactions.length}', color: PdfColors.white, fontSize: 8),
            _cell(
              Formatters.formatAmount(debit),
              bold: true,
              color: PdfColors.white,
              align: pw.TextAlign.right,
              fontSize: 8,
            ),
            _cell(
              Formatters.formatAmount(credit),
              bold: true,
              color: PdfColors.white,
              align: pw.TextAlign.right,
              fontSize: 8,
            ),
            _cell(
              '${Formatters.formatAmount(balance.abs())} ${balance >= 0 ? 'Cr' : 'Dr'}',
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
          headerRow(),
          ...dataRows,
          footerRow(),
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

          // ── Party details & Vehicles ──────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Party Details'),
                  pw.SizedBox(height: 4),
                  _infoRow('Name', party.name),
                  if (party.phone != null && party.phone!.isNotEmpty)
                    _infoRow('Phone', party.phone!),
                  _infoRow('Since', Formatters.formatDate(party.createdAt)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _sectionLabel('Vehicles (${vehicles.length})'),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    vehicles.isEmpty
                        ? 'No vehicles registered'
                        : vehicles.map((v) => '${v.number} (${v.type})').join('\n'),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // ── Four Summary Cards (Opening Balance, Total Debit, Total Credit, Net Balance) ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryCard('Opening Balance', Formatters.formatAmount(0.0), subtitle: '(on ${Formatters.formatDate(party.createdAt)})'),
              _summaryCard('Total Debit(-)', Formatters.formatAmount(debit), color: _debitText, bg: _debitBg),
              _summaryCard('Total Credit(+)', Formatters.formatAmount(credit), color: _creditText, bg: _creditBg),
              _summaryCard(
                'Net Balance', 
                '${Formatters.formatAmount(balance.abs())} ${balance >= 0 ? 'Cr' : 'Dr'}', 
                color: balance >= 0 ? _creditText : _debitText,
                bg: balance >= 0 ? _creditBg : _debitBg,
                subtitle: balance >= 0 ? '(${party.name} will pay)' : '(${party.name} will get)'
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
            buildTransactionTable(),

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

  static pw.Widget _summaryCard(
    String title,
    String value, {
    PdfColor? color,
    PdfColor? bg,
    String? subtitle,
  }) {
    return pw.Container(
      width: 125,
      height: 60,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: bg ?? PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColors.black,
            ),
          ),
          pw.Text(
            subtitle ?? ' ',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
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
