import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/particle_background.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'ALL';

  final List<Map<String, dynamic>> _batches = [
    {'id': 'PT-2024-A09', 'drug': 'Ibuprofen 400mg', 'form': 'Tablet',
     'stability': 0.892, 'risk': 0.18, 'status': 'ACTIVE',
     'date': '2024-01-10', 'shelf_life': 19.2},
    {'id': 'PT-2024-A08', 'drug': 'Metformin 500mg', 'form': 'Tablet',
     'stability': 0.764, 'risk': 0.41, 'status': 'REVIEW',
     'date': '2024-01-08', 'shelf_life': 14.7},
    {'id': 'PT-2024-A07', 'drug': 'Amlodipine 5mg', 'form': 'Capsule',
     'stability': 0.541, 'risk': 0.67, 'status': 'ALERT',
     'date': '2024-01-05', 'shelf_life': 11.3},
    {'id': 'PT-2024-A06', 'drug': 'Atorvastatin 20mg', 'form': 'Tablet',
     'stability': 0.931, 'risk': 0.12, 'status': 'PASSED',
     'date': '2024-01-02', 'shelf_life': 22.1},
    {'id': 'PT-2024-A05', 'drug': 'Paracetamol 500mg', 'form': 'Tablet',
     'stability': 0.912, 'risk': 0.14, 'status': 'PASSED',
     'date': '2023-12-28', 'shelf_life': 20.4},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _batches.where((b) {
      final matchSearch = b['drug'].toString().toLowerCase()
          .contains(_searchController.text.toLowerCase()) ||
          b['id'].toString().toLowerCase()
          .contains(_searchController.text.toLowerCase());
      final matchStatus =
          _filterStatus == 'ALL' || b['status'] == _filterStatus;
      return matchSearch && matchStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(density: 15),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BATCHES',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [AppTheme.neonCyan, AppTheme.neonGreen],
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                            ),
                          ),
                          Text(
                            '${_batches.length} PHARMACEUTICAL BATCHES',
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      FloatingActionButton.small(
                        onPressed: _showCreateBatchDialog,
                        backgroundColor: AppTheme.neonCyan,
                        foregroundColor: AppTheme.bgDeep,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),

                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: AppTheme.glassDecoration(borderRadius: 12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search batches...',
                        prefixIcon: Icon(Icons.search, color: AppTheme.neonCyan, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),

                // Status filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['ALL', 'ACTIVE', 'REVIEW', 'ALERT', 'PASSED']
                        .map((s) => _StatusFilter(
                              label: s,
                              isSelected: _filterStatus == s,
                              onTap: () => setState(() => _filterStatus = s),
                            ))
                        .toList(),
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 8),

                // Batch list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final batch = filtered[index];
                      return _BatchCard(batch: batch)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 100 * index))
                          .slideX(begin: 0.1);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateBatchDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.borderGlass),
      ),
      builder: (ctx) => const _CreateBatchSheet(),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusFilter({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color {
    switch (label) {
      case 'ACTIVE': return AppTheme.neonCyan;
      case 'REVIEW': return AppTheme.neonYellow;
      case 'ALERT': return AppTheme.neonRed;
      case 'PASSED': return AppTheme.neonGreen;
      default: return AppTheme.neonCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? _color.withOpacity(0.15) : AppTheme.bgSurface,
          border: Border.all(
            color: isSelected ? _color : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            color: isSelected ? _color : AppTheme.textMuted,
            letterSpacing: 0.8,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final Map<String, dynamic> batch;

  const _BatchCard({required this.batch});

  Color get _statusColor {
    switch (batch['status']) {
      case 'ACTIVE': return AppTheme.neonCyan;
      case 'REVIEW': return AppTheme.neonYellow;
      case 'ALERT': return AppTheme.neonRed;
      case 'PASSED': return AppTheme.neonGreen;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stability = batch['stability'] as double;
    final risk = batch['risk'] as double;
    final riskColor = AppTheme.getRiskColor(risk);

    return GlassCard(
      borderColor: _statusColor.withOpacity(0.2),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: _statusColor,
                  boxShadow: [
                    BoxShadow(
                        color: _statusColor.withOpacity(0.4), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          batch['id'],
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _statusColor.withOpacity(0.1),
                            border: Border.all(
                                color: _statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            batch['status'],
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 9,
                              color: _statusColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${batch['drug']} · ${batch['form']}',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderSubtle, height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BatchMetric(
                label: 'STABILITY',
                value: '${(stability * 100).toStringAsFixed(1)}%',
                color: AppTheme.getStabilityColor(stability),
              ),
              Container(width: 1, height: 32, color: AppTheme.borderSubtle),
              _BatchMetric(
                label: 'RISK',
                value: '${(risk * 100).toStringAsFixed(0)}%',
                color: riskColor,
              ),
              Container(width: 1, height: 32, color: AppTheme.borderSubtle),
              _BatchMetric(
                label: 'SHELF LIFE',
                value: '${batch['shelf_life']}M',
                color: AppTheme.neonCyan,
              ),
              Container(width: 1, height: 32, color: AppTheme.borderSubtle),
              _BatchMetric(
                label: 'DATE',
                value: batch['date'],
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BatchMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 8,
            color: AppTheme.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _CreateBatchSheet extends StatefulWidget {
  const _CreateBatchSheet();

  @override
  State<_CreateBatchSheet> createState() => _CreateBatchSheetState();
}

class _CreateBatchSheetState extends State<_CreateBatchSheet> {
  final _drugController = TextEditingController();
  String _selectedForm = 'Tablet';
  double _strength = 400;
  double _drugLoad = 40;
  String _packaging = 'Blister';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CREATE NEW BATCH',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 16,
              color: AppTheme.neonCyan,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _drugController,
            style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'SpaceMono'),
            decoration: const InputDecoration(
              labelText: 'DRUG NAME',
              hintText: 'e.g. Ibuprofen',
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedForm,
                  dropdownColor: AppTheme.bgCard,
                  decoration: const InputDecoration(labelText: 'DOSAGE FORM'),
                  items: ['Tablet', 'Capsule', 'Coated Tablet', 'Extended Release']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, style: const TextStyle(
                              fontFamily: 'SpaceMono', fontSize: 12, color: AppTheme.textPrimary))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedForm = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _packaging,
                  dropdownColor: AppTheme.bgCard,
                  decoration: const InputDecoration(labelText: 'PACKAGING'),
                  items: ['Blister', 'HDPE Bottle', 'Glass Bottle', 'Strip Pack']
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, style: const TextStyle(
                              fontFamily: 'SpaceMono', fontSize: 12, color: AppTheme.textPrimary))))
                      .toList(),
                  onChanged: (v) => setState(() => _packaging = v!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Batch created successfully'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              },
              child: const Text('CREATE BATCH'),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Stub screens for routing
class BatchDetailScreen extends StatelessWidget {
  final String batchId;
  const BatchDetailScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: Text('BATCH $batchId')),
      body: const Center(
          child: Text('Batch Detail', style: TextStyle(color: AppTheme.textPrimary))),
    );
  }
}

class PredictionDetailScreen extends StatelessWidget {
  final String predictionId;
  const PredictionDetailScreen({super.key, required this.predictionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: Text('PREDICTION $predictionId')),
      body: const Center(
          child: Text('Prediction Detail', style: TextStyle(color: AppTheme.textPrimary))),
    );
  }
}
