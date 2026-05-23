import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/particle_background.dart';

class PredictionsScreen extends ConsumerStatefulWidget {
  const PredictionsScreen({super.key});

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRunningPrediction = false;

  // Form state
  String _selectedDrug = 'Ibuprofen';
  String _selectedDosageForm = 'Tablet';
  double _drugLoad = 40.0;
  double _humidity = 35.0;
  double _temperature = 25.0;
  double _phLevel = 7.0;
  String _packagingType = 'Blister';

  Map<String, dynamic>? _predictionResult;
  List<dynamic>? _alternatives;
  bool _isLoadingAlternatives = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(density: 20),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNewPredictionTab(),
                      _buildResultsTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI PREDICTIONS',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                ),
              ),
              const Text(
                'LSTM · XGBoost · Bayesian NN',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ).animate().fadeIn().slideX(begin: -0.2),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: AppTheme.neonCardDecoration(glowColor: AppTheme.neonPurple),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.neonPurple,
              size: 22,
            ),
          ).animate().fadeIn().scale(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.bgSurface,
          border: Border.all(color: AppTheme.borderGlass),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: AppTheme.primaryGradient,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          unselectedLabelColor: AppTheme.textMuted,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'NEW RUN'),
            Tab(text: 'RESULTS'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPredictionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Formulation Config card
          GlassCard(
            borderColor: AppTheme.neonBlue.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'FORMULATION PARAMETERS',
                  icon: Icons.science_outlined,
                  color: AppTheme.neonBlue,
                ),
                const SizedBox(height: 20),

                // Drug selection
                _PharmaDropdown(
                  label: 'ACTIVE PHARMACEUTICAL INGREDIENT',
                  value: _selectedDrug,
                  items: [
                    'Ibuprofen', 'Metformin', 'Amlodipine', 'Atorvastatin',
                    'Paracetamol', 'Aspirin', 'Omeprazole', 'Amoxicillin',
                  ],
                  onChanged: (v) => setState(() => _selectedDrug = v!),
                ),

                const SizedBox(height: 16),

                _PharmaDropdown(
                  label: 'DOSAGE FORM',
                  value: _selectedDosageForm,
                  items: ['Tablet', 'Capsule', 'Coated Tablet', 'Extended Release'],
                  onChanged: (v) => setState(() => _selectedDosageForm = v!),
                ),

                const SizedBox(height: 20),

                _SliderParam(
                  label: 'DRUG LOAD',
                  unit: '%',
                  value: _drugLoad,
                  min: 5,
                  max: 80,
                  onChanged: (v) => setState(() => _drugLoad = v),
                  color: AppTheme.neonBlue,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 12),

          // Environmental params card
          GlassCard(
            borderColor: AppTheme.neonOrange.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'ENVIRONMENTAL CONDITIONS',
                  icon: Icons.thermostat_outlined,
                  color: AppTheme.neonOrange,
                ),
                const SizedBox(height: 20),

                _SliderParam(
                  label: 'TEMPERATURE',
                  unit: '°C',
                  value: _temperature,
                  min: 5,
                  max: 60,
                  onChanged: (v) => setState(() => _temperature = v),
                  color: AppTheme.neonOrange,
                ),

                const SizedBox(height: 16),

                _SliderParam(
                  label: 'pH LEVEL',
                  unit: '',
                  value: _phLevel,
                  min: 1.0,
                  max: 14.0,
                  onChanged: (v) => setState(() => _phLevel = v),
                  color: AppTheme.neonPurple,
                ),

                const SizedBox(height: 16),

                _SliderParam(
                  label: 'RELATIVE HUMIDITY',
                  unit: '%RH',
                  value: _humidity,
                  min: 0,
                  max: 100,
                  onChanged: (v) => setState(() => _humidity = v),
                  color: AppTheme.neonCyan,
                ),

                const SizedBox(height: 20),

                _PharmaDropdown(
                  label: 'PACKAGING TYPE',
                  value: _packagingType,
                  items: ['Blister', 'HDPE Bottle', 'Glass Bottle', 'Strip Pack', 'Sachets'],
                  onChanged: (v) => setState(() => _packagingType = v!),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Run prediction button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: _isRunningPrediction
                  ? null
                  : AppTheme.primaryGradient,
              color: _isRunningPrediction ? AppTheme.bgSurface : null,
              boxShadow: _isRunningPrediction
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.neonBlue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _isRunningPrediction ? null : _runPrediction,
                child: Center(
                  child: _isRunningPrediction
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.neonCyan),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'RUNNING AI MODELS...',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 13,
                                color: AppTheme.neonCyan,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'RUN PREDICTION ENGINE',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_predictionResult == null) {
      return const Center(
        child: Text(
          'Run a prediction to see results.',
          style: TextStyle(color: AppTheme.textMuted, fontFamily: 'SpaceMono'),
        ),
      );
    }

    final shelfLife = _predictionResult!['shelf_life_months'] as double;
    final lower = _predictionResult!['shelf_life_lower'] as double;
    final upper = _predictionResult!['shelf_life_upper'] as double;
    final risk = _predictionResult!['degradation_risk'] as double;
    final explanation = _predictionResult!['explanation'] as String;
    final featureImp = _predictionResult!['feature_importance'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Prediction result header
          GlassCard(
            borderColor: AppTheme.neonGreen.withOpacity(0.3),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppTheme.neonGreen.withOpacity(0.15),
                        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.check_circle_outline,
                          color: AppTheme.neonGreen, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PREDICTION COMPLETE',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 13,
                              color: AppTheme.neonGreen,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_selectedDrug $_drugLoad% $_selectedDosageForm | pH ${_phLevel.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: AppTheme.neonRed),
                      onPressed: _generateAndDownloadPdf,
                      tooltip: 'Download PDF Report',
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 12),

          // Shelf Life Prediction
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'SHELF LIFE PREDICTION',
                  icon: Icons.schedule_outlined,
                  color: AppTheme.neonCyan,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppTheme.cyanGradient.createShader(bounds),
                          child: Text(
                            shelfLife.toStringAsFixed(1),
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Text(
                          'MONTHS',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppTheme.neonCyan.withOpacity(0.3)),
                            color: AppTheme.neonCyan.withOpacity(0.08),
                          ),
                          child: Text(
                            '${lower.toStringAsFixed(1)} - ${upper.toStringAsFixed(1)} months | 95% CI',
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 11,
                              color: AppTheme.neonCyan,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Confidence breakdown
                const _ModelConfidenceRow(
                    model: 'LSTM', confidence: 0.94, label: 'Time Series'),
                const _ModelConfidenceRow(
                    model: 'GRU', confidence: 0.91, label: 'Forecasting'),
                const _ModelConfidenceRow(
                    model: 'Bayesian NN', confidence: 0.89, label: 'Uncertainty'),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 12),

          // Risk metrics grid
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  child: Column(
                    children: [
                      const _SectionHeader(
                        title: 'DEGRADATION',
                        icon: Icons.trending_down,
                        color: AppTheme.neonOrange,
                      ),
                      const SizedBox(height: 16),
                      CircularPercentIndicator(
                        radius: 50,
                        lineWidth: 8,
                        percent: risk,
                        center: Text(
                          '${(risk * 100).toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 16,
                            color: AppTheme.neonOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        progressColor: AppTheme.neonOrange,
                        backgroundColor: AppTheme.bgSurface,
                        circularStrokeCap: CircularStrokeCap.round,
                        footer: const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'RISK',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  child: Column(
                    children: [
                      const _SectionHeader(
                        title: 'DISSOLUTION',
                        icon: Icons.water_drop_outlined,
                        color: AppTheme.neonBlue,
                      ),
                      const SizedBox(height: 16),
                      CircularPercentIndicator(
                        radius: 50,
                        lineWidth: 8,
                        percent: 0.97,
                        center: const Text(
                          '97%',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 16,
                            color: AppTheme.neonBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        progressColor: AppTheme.neonBlue,
                        backgroundColor: AppTheme.bgSurface,
                        circularStrokeCap: CircularStrokeCap.round,
                        footer: const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'RELEASE',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Feature importance - XAI
          GlassCard(
            borderColor: AppTheme.neonPurple.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'AI EXPLAINABILITY (XAI)',
                  icon: Icons.bar_chart_outlined,
                  color: AppTheme.neonPurple,
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                ...featureImp.entries.take(5).map((e) => _FeatureImportanceBar(
                  name: e.key,
                  importance: e.value,
                  color: AppTheme.neonPurple,
                )),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 12),

          // Alternatives section
          GlassCard(
            borderColor: AppTheme.neonBlue.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionHeader(
                      title: 'DRUG ALTERNATIVES (OpenFDA)',
                      icon: Icons.medication_outlined,
                      color: AppTheme.neonBlue,
                    ),
                    if (_isLoadingAlternatives)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_alternatives != null && _alternatives!.isEmpty)
                  const Text('No alternatives found.', style: TextStyle(color: AppTheme.textMuted)),
                if (_alternatives != null)
                  ..._alternatives!.map((alt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.neonBlue.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alt['brand_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Generic: ${alt['generic_name']}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          Text('Class: ${(alt['pharm_class'] as List).join(", ")}', style: const TextStyle(color: AppTheme.neonCyan, fontSize: 10)),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final predictions = [
      ('PT-2024-A09', 'Ibuprofen 400mg', '18.2 months', 'LOW', AppTheme.neonGreen),
      ('PT-2024-A08', 'Metformin 500mg', '14.7 months', 'MED', AppTheme.neonYellow),
      ('PT-2024-A07', 'Amlodipine 5mg', '11.3 months', 'HIGH', AppTheme.neonRed),
      ('PT-2024-A06', 'Atorvastatin 20mg', '22.1 months', 'LOW', AppTheme.neonGreen),
      ('PT-2024-A05', 'Paracetamol 500mg', '19.8 months', 'LOW', AppTheme.neonGreen),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: predictions.length,
      itemBuilder: (context, index) {
        final p = predictions[index];
        return GlassCard(
          borderColor: p.$5.withOpacity(0.2),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: p.$5,
                  boxShadow: [
                    BoxShadow(
                        color: p.$5.withOpacity(0.4), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.$1,
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 4),
                    Text(p.$2,
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        )),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(p.$3,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        color: p.$5,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: p.$5.withOpacity(0.1),
                      border: Border.all(color: p.$5.withOpacity(0.3)),
                    ),
                    child: Text(p.$4,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          color: p.$5,
                          letterSpacing: 1,
                        )),
                  ),
                ],
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 100 * index))
            .slideX(begin: 0.1);
      },
    );
  }

  Future<void> _runPrediction() async {
    setState(() {
      _isRunningPrediction = true;
      _predictionResult = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/predictions/', data: {
        'drug_name': _selectedDrug,
        'dosage_form': _selectedDosageForm,
        'drug_load_percent': _drugLoad,
        'strength_mg': 400.0, // simplified
        'temperature_c': _temperature,
        'humidity_rh': _humidity,
        'ph_level': _phLevel,
        'packaging_type': _packagingType,
        'ich_zone': 'II'
      });

      if (mounted) {
        setState(() {
          _predictionResult = response.data;
          _isRunningPrediction = false;
        });
        _tabController.animateTo(1);
        _fetchAlternatives();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRunningPrediction = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction failed: $e')),
        );
      }
    }
  }

  Future<void> _fetchAlternatives() async {
    setState(() => _isLoadingAlternatives = true);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/alternatives/?drug_name=$_selectedDrug');
      if (mounted) {
        setState(() {
          _alternatives = response.data['alternatives'];
          _isLoadingAlternatives = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alternatives = [];
          _isLoadingAlternatives = false;
        });
      }
    }
  }

  Future<void> _generateAndDownloadPdf() async {
    if (_predictionResult == null) return;
    
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'PharmaTwin AI - Prediction Report'),
              pw.SizedBox(height: 20),
              pw.Text('Drug: $_selectedDrug $_drugLoad% $_selectedDosageForm'),
              pw.Text('Parameters: ${_temperature}°C / ${_humidity}% RH / pH ${_phLevel.toStringAsFixed(1)} / $_packagingType'),
              pw.SizedBox(height: 20),
              pw.Text('Predicted Shelf Life: ${_predictionResult!['shelf_life_months'].toStringAsFixed(1)} months', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Text('Degradation Risk: ${(_predictionResult!['degradation_risk'] * 100).toInt()}%'),
              pw.SizedBox(height: 20),
              pw.Text('Explanation:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_predictionResult!['explanation']),
              pw.SizedBox(height: 30),
              pw.Text('Report generated by PharmaTwin AI automatically.', style: const pw.TextStyle(color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Stability_Report_$_selectedDrug.pdf',
    );
  }
}

// Reusable Widgets

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 11,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PharmaDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _PharmaDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.bgSurface,
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppTheme.bgCard,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppTheme.neonCyan, size: 20),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SliderParam extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color color;

  const _SliderParam({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '${value.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: AppTheme.bgSurface,
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ModelConfidenceRow extends StatelessWidget {
  final String model;
  final double confidence;
  final String label;

  const _ModelConfidenceRow({
    required this.model,
    required this.confidence,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              model,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidence,
                backgroundColor: AppTheme.bgSurface,
                valueColor: const AlwaysStoppedAnimation(AppTheme.neonCyan),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(confidence * 100).toInt()}%',
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureImportanceBar extends StatelessWidget {
  final String name;
  final double importance;
  final Color color;

  const _FeatureImportanceBar({
    required this.name,
    required this.importance,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.bgSurface,
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: importance,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: color.withOpacity(0.3),
                      border: Border.all(
                          color: color.withOpacity(0.5), width: 1),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${(importance * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
