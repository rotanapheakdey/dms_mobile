import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfSignatureOverlayScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String signatureSource; // URL or File path of the signature image
  final bool isSignatureUrl;   // True if signatureSource is a web URL, false if it's a local file path

  const PdfSignatureOverlayScreen({
    super.key,
    required this.pdfBytes,
    required this.signatureSource,
    required this.isSignatureUrl,
  });

  @override
  State<PdfSignatureOverlayScreen> createState() => _PdfSignatureOverlayScreenState();
}

class _PdfSignatureOverlayScreenState extends State<PdfSignatureOverlayScreen> {
  PdfDocument? _pdfDocument;
  int _pageCount = 0;
  int _currentPage = 1;
  bool _isLoading = true;
  String? _errorMessage;

  // Rendered page image details
  Uint8List? _pageImageBytes;
  double _pdfPageWidth = 595.0; // Default A4 width in points
  double _pdfPageHeight = 842.0; // Default A4 height in points

  // Coordinates on screen
  double _sigX = 100.0;
  double _sigY = 200.0;
  final double _sigWidth = 120.0;
  final double _sigHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      _pdfDocument = await PdfDocument.openData(widget.pdfBytes);
      _pageCount = _pdfDocument?.pagesCount ?? 0;
      
      // Default to signing the last page (where signatures usually go)
      _currentPage = _pageCount;
      
      await _renderCurrentPage();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF document: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _renderCurrentPage() async {
    if (_pdfDocument == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final page = await _pdfDocument!.getPage(_currentPage);
      _pdfPageWidth = page.width.toDouble();
      _pdfPageHeight = page.height.toDouble();

      // Render page to image bytes (multiply size by 2 for higher resolution preview)
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      await page.close();

      setState(() {
        _pageImageBytes = pageImage?.bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to render PDF page: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfDocument?.close();
    super.dispose();
  }

  void _onConfirm(double containerWidth, double containerHeight) {
    // ─── Scale screen coordinates to PDF points ───
    // Screen coords range from [0, containerWidth] and [0, containerHeight]
    // PDF page coords range from [0, _pdfPageWidth] and [0, _pdfPageHeight]
    
    final scaleX = _pdfPageWidth / containerWidth;
    final scaleY = _pdfPageHeight / containerHeight;

    final pdfX = _sigX * scaleX;
    final pdfY = _sigY * scaleY;
    final pdfW = _sigWidth * scaleX;
    final pdfH = _sigHeight * scaleY;

    Navigator.of(context).pop({
      'x': pdfX,
      'y': pdfY,
      'width': pdfW,
      'height': pdfH,
      'page': _currentPage,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Signature'),
        actions: [
          if (!_isLoading && _pageImageBytes != null)
            TextButton.icon(
              onPressed: () {
                // Confirm will be triggered from the LayoutBuilder dimensions
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
        ],
      ),
      body: _isLoading && _pdfDocument == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : Column(
                  children: [
                    // Page Navigation
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: colorScheme.surfaceContainerLow,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded),
                            onPressed: _currentPage > 1
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                    _renderCurrentPage();
                                  }
                                : null,
                          ),
                          Text(
                            'Page $_currentPage of $_pageCount',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded),
                            onPressed: _currentPage < _pageCount
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                    _renderCurrentPage();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _pageImageBytes == null
                              ? const Center(child: Text('No page content'))
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Calculate aspect ratio fit of the PDF page in the available space
                                    final double maxW = constraints.maxWidth - 32;
                                    final double maxH = constraints.maxHeight - 32;

                                    final double pdfRatio = _pdfPageWidth / _pdfPageHeight;
                                    final double screenRatio = maxW / maxH;

                                    double containerWidth;
                                    double containerHeight;

                                    if (pdfRatio > screenRatio) {
                                      // Fit to width
                                      containerWidth = maxW;
                                      containerHeight = maxW / pdfRatio;
                                    } else {
                                      // Fit to height
                                      containerHeight = maxH;
                                      containerWidth = maxH * pdfRatio;
                                    }

                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Stack(
                                            children: [
                                              // 1. PDF Page Rendered Image
                                              Container(
                                                width: containerWidth,
                                                height: containerHeight,
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.15),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Image.memory(
                                                  _pageImageBytes!,
                                                  fit: BoxFit.fill,
                                                ),
                                              ),

                                              // 2. Draggable Signature Overlay
                                              Positioned(
                                                left: _sigX,
                                                top: _sigY,
                                                child: GestureDetector(
                                                  onPanUpdate: (details) {
                                                    setState(() {
                                                      _sigX = (_sigX + details.delta.dx).clamp(
                                                        0.0,
                                                        containerWidth - _sigWidth,
                                                      );
                                                      _sigY = (_sigY + details.delta.dy).clamp(
                                                        0.0,
                                                        containerHeight - _sigHeight,
                                                      );
                                                    });
                                                  },
                                                  child: Container(
                                                    width: _sigWidth,
                                                    height: _sigHeight,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: colorScheme.primary,
                                                        width: 2,
                                                      ),
                                                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        Center(
                                                          child: widget.isSignatureUrl
                                                              ? Image.network(
                                                                  widget.signatureSource,
                                                                  fit: BoxFit.contain,
                                                                )
                                                              : Image.file(
                                                                  File(widget.signatureSource),
                                                                  fit: BoxFit.contain,
                                                                ),
                                                        ),
                                                        Positioned(
                                                          right: 2,
                                                          top: 2,
                                                          child: Container(
                                                            padding: const EdgeInsets.all(2),
                                                            color: colorScheme.primary,
                                                            child: const Icon(
                                                              Icons.open_with_rounded,
                                                              size: 12,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton.icon(
                                            onPressed: () => _onConfirm(containerWidth, containerHeight),
                                            icon: const Icon(Icons.check_circle_rounded),
                                            label: const Text('Burn Signature to PDF'),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
    );
  }
}
