import 'package:flutter/material.dart';

class ExportExcelButton extends StatelessWidget {
  final VoidCallback? onExcel;
  final VoidCallback? onPdf;
  final bool loading;

  const ExportExcelButton({
    super.key,
    this.onExcel,
    this.onPdf,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: loading ? null : onExcel,
          icon: loading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.table_view),
          label: const Text("خروجی Excel"),
        ),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          onPressed: loading ? null : onPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("خروجی PDF"),
        ),
      ],
    );
  }
}