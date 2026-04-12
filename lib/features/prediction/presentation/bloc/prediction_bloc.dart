import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/ml/ml_model.dart';
import '../../../../core/ml/feature_extractor.dart';
import '../../../../core/routing/graph_manager.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/rainfall_datasource.dart';
import '../../data/models/rainfall_data.dart'; // ✅ ADD THIS IMPORT
import '../../domain/usecases/predict_route_decay_usecase.dart';
import 'prediction_event.dart';
import 'prediction_state.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final MLModel _mlModel;
  final GraphManager _graphManager;
  final RainfallDataSource _rainfallDataSource;

  late PredictRouteDecayUseCase _predictUseCase;
  StreamSubscription? _rainfallSubscription;
  Timer? _predictionTimer;

  PredictionBloc({
    required MLModel mlModel,
    required GraphManager graphManager,
    required RainfallDataSource rainfallDataSource,
  })  : _mlModel = mlModel,
        _graphManager = graphManager,
        _rainfallDataSource = rainfallDataSource,
        super(PredictionInitial()) {

    _predictUseCase = PredictRouteDecayUseCase(
      mlModel: _mlModel,
      featureExtractor: FeatureExtractor(),
      graphManager: _graphManager,
    );

    on<PredictionInitializeRequested>(_onInitializeRequested);
    on<PredictionStartSimulationRequested>(_onStartSimulationRequested);
    on<PredictionStopSimulationRequested>(_onStopSimulationRequested);
    on<PredictionRunRequested>(_onRunRequested);
    on<PredictionLoadModelRequested>(_onLoadModelRequested);
  }

  Future<void> _onInitializeRequested(
      PredictionInitializeRequested event,
      Emitter<PredictionState> emit,
      ) async {
    emit(PredictionLoading());

    try {
      final modelInfo = _mlModel.getModelInfo();
      emit(PredictionReady(modelInfo));

      AppLogger.info('✅ Prediction BLoC initialized');
    } catch (e) {
      emit(PredictionError('Initialization failed: ${e.toString()}'));
    }
  }

  Future<void> _onStartSimulationRequested(
      PredictionStartSimulationRequested event,
      Emitter<PredictionState> emit,
      ) async {
    try {
      AppLogger.info('🌧️ Starting rainfall simulation');

      _rainfallDataSource.startSimulation(event.edgeIds);
      emit(PredictionSimulationRunning(event.edgeIds.length));

      // Run predictions every 5 seconds
      _predictionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        add(PredictionRunRequested());
      });

    } catch (e) {
      emit(PredictionError('Failed to start simulation: ${e.toString()}'));
    }
  }

  Future<void> _onStopSimulationRequested(
      PredictionStopSimulationRequested event,
      Emitter<PredictionState> emit,
      ) async {
    _rainfallDataSource.stopSimulation();
    _predictionTimer?.cancel();

    final modelInfo = _mlModel.getModelInfo();
    emit(PredictionReady(modelInfo));
  }

  Future<void> _onRunRequested(
      PredictionRunRequested event,
      Emitter<PredictionState> emit,
      ) async {
    try {
      // Collect recent rainfall data
      final rainfallData = await _collectRecentData();

      if (rainfallData.isEmpty) {
        AppLogger.warning('No rainfall data available for prediction');
        return;
      }

      // Run predictions
      final predictions = await _predictUseCase.predictAll(rainfallData);

      emit(PredictionResultsAvailable(
        predictions: predictions,
        updatedAt: DateTime.now(),
      ));

      // Log high-risk edges
      final highRisk = predictions.where((p) => p.isHighRisk()).toList();
      if (highRisk.isNotEmpty) {
        AppLogger.warning('⚠️ ${highRisk.length} high-risk edges detected');
      }

    } catch (e, stack) {
      AppLogger.error('Prediction run failed', e, stack);
    }
  }

  Future<void> _onLoadModelRequested(
      PredictionLoadModelRequested event,
      Emitter<PredictionState> emit,
      ) async {
    emit(PredictionLoading());

    try {
      _mlModel.loadFromSklearn(event.modelData);

      final modelInfo = _mlModel.getModelInfo();
      emit(PredictionReady(modelInfo));

      AppLogger.info('✅ Model loaded from external data');
    } catch (e) {
      emit(PredictionError('Model loading failed: ${e.toString()}'));
    }
  }

  /// Collect recent rainfall data (✅ FIXED TYPE)
  Future<List<RainfallData>> _collectRecentData() async {
    // For simulation, return current state
    // In production, query last N readings per edge
    return <RainfallData>[]; // ✅ Fixed return type
  }

  @override
  Future<void> close() {
    _rainfallSubscription?.cancel();
    _predictionTimer?.cancel();
    _rainfallDataSource.dispose();
    return super.close();
  }
}