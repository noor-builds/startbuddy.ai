import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startbuddy/models/startup.dart';
import 'package:startbuddy/models/document.dart';
import 'package:startbuddy/service/db/db_service.dart';
import 'package:startbuddy/service/http.dart';
import 'package:startbuddy/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsView extends StatefulWidget {
  final Startup startup;

  const DocumentsView({super.key, required this.startup});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  final DbService _db = DbService();
  final HttpService _http = HttpService();

  bool _loading = true;
  bool _generating = false;
  List<StartupDocument> _documents = [];

  final List<Map<String, String>> _docTypes = [
    {'type': 'pitch_deck', 'label': 'Pitch Deck Outline'},
    {'type': 'business_plan', 'label': 'Business Plan'},
    {'type': 'problem_solution', 'label': 'Problem-Solution Document'},
    {'type': 'model_canvas', 'label': 'Business Model Canvas'},
    {'type': 'user_persona', 'label': 'User Persona Sheet'},
    {'type': 'gtm_strategy', 'label': 'Go-To-Market Strategy'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() => _loading = true);
      final data = await _db.fetchDocumentsForStartup(widget.startup.id);
      
      if (!mounted) return;
      setState(() {
        _documents = data.map((d) => StartupDocument.fromJson(d)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load documents: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _generateDoc(String type, String label) async {
    if (_generating) return;
    setState(() => _generating = true);

    try {
      final response = await _http.generateDocument(widget.startup.id, type);
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300 && body['ok'] == true) {
        await _loadDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label generated successfully!')),
          );
        }
      } else {
        throw Exception(body['error']?['message'] ?? 'Failed to generate document');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open PDF link: $e. Copying to clipboard.'), backgroundColor: AppTheme.warning),
        );
      }
    }
  }

  void _showDocumentViewer(StartupDocument doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Modal Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          doc.title,
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (doc.fileUrl != null)
                        ElevatedButton.icon(
                          onPressed: () => _openPdf(doc.fileUrl!),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: const Text('Open PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                // Markdown Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        doc.content ?? 'No content available.',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGenerateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate Business Document',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose a strategy document for AI to formulate based on your business idea.',
                style: GoogleFonts.roboto(fontSize: 13, color: AppTheme.textSecondaryDark),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _docTypes.length,
                  itemBuilder: (context, index) {
                    final item = _docTypes[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.auto_awesome, color: AppTheme.accent),
                      title: Text(
                        item['label']!,
                        style: GoogleFonts.roboto(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _generateDoc(item['type']!, item['label']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Business Vault',
                style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: _generating ? null : _showGenerateMenu,
                icon: _generating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_rounded, size: 16),
                label: Text(_generating ? 'Generating...' : 'New Document'),
              ),
            ],
          ),
        ),

        // Documents list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _documents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 48, color: Colors.white.withOpacity(0.12)),
                          const SizedBox(height: 12),
                          Text(
                            'No documents generated yet.',
                            style: GoogleFonts.roboto(fontSize: 14, color: AppTheme.textSecondaryDark),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: InkWell(
                            onTap: () => _showDocumentViewer(doc),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  child: const Icon(Icons.insert_drive_file_outlined, color: AppTheme.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc.title,
                                        style: GoogleFonts.roboto(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Type: ${doc.type.toUpperCase().replaceAll('_', ' ')}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 11.5,
                                          color: AppTheme.textSecondaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondaryDark),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
