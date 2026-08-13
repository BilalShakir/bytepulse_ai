import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/app_models.dart';

class GeminiService {
  final String? apiKey;
  final String? modelName;

  GeminiService({this.apiKey, this.modelName});

  String get _effectiveApiKey {
    if (apiKey != null && apiKey!.isNotEmpty) return apiKey!;
    return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  String get _effectiveModel {
    if (modelName != null && modelName!.isNotEmpty) return modelName!;
    return const String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.6-flash');
  }

  Stream<String> streamGeminiResponse({
    required String prompt,
    IntelligenceCard? groundedCard,
    String? customContextTitle,
  }) async* {
    final key = _effectiveApiKey;
    final modelId = _effectiveModel;

    // Construct grounded system context prompt
    final String systemContext = _buildSystemContext(groundedCard, customContextTitle);

    if (key.isEmpty) {
      // Offline/Demo Simulation Stream when API key is not supplied
      yield* _streamSimulatedResponse(prompt, groundedCard);
      return;
    }

    try {
      final model = GenerativeModel(
        model: modelId,
        apiKey: key,
        systemInstruction: Content.system(systemContext),
      );

      final content = [Content.text(prompt)];
      final responseStream = model.generateContentStream(content);

      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield '\n\n⚠️ Network error or API key issue ($modelId): ${e.toString()}\n\n*AI-generated analysis may contain errors. Verify critical technical decisions.*';
    }
  }

  String _buildSystemContext(IntelligenceCard? card, String? contextTitle) {
    final buffer = StringBuffer();
    buffer.writeln('You are Live Gemini Enterprise Agent in BytePulse AI, a technical intelligence developer app.');
    buffer.writeln('Always deliver concise, highly technical responses tailored for senior engineers.');
    buffer.writeln('Include code snippets where relevant and highlight pros/cons.');

    if (card != null) {
      buffer.writeln('\n[GROUNDED ARTICLE CONTEXT]');
      buffer.writeln('Title: ${card.headline}');
      buffer.writeln('Summary: ${card.summary}');
      buffer.writeln('Source: ${card.source}');
      buffer.writeln('Credibility: ${card.credibilityType.name.toUpperCase()}');
      buffer.writeln('Pros: ${card.pros}');
      buffer.writeln('Cons: ${card.cons}');
    } else if (contextTitle != null && contextTitle.isNotEmpty) {
      buffer.writeln('\n[GROUNDED CONTEXT]: $contextTitle');
    }

    return buffer.toString();
  }

  Stream<String> _streamSimulatedResponse(String prompt, IntelligenceCard? card) async* {
    final lower = prompt.toLowerCase();
    String responseText;
    String? codeSnippet;

    if (lower.contains('code') || lower.contains('script') || lower.contains('python') || lower.contains('example')) {
      responseText = 'Based on the grounded analysis for ${card?.headline ?? "this model"}, here is the recommended PyTorch benchmark script:\n';
      codeSnippet = '''import time
import torch

def benchmark_fp8_linear(batch_size=64, hidden_dim=8192):
    x = torch.randn(batch_size, hidden_dim, device="cuda", dtype=torch.float8_e4m3fn)
    w = torch.randn(hidden_dim, hidden_dim, device="cuda", dtype=torch.float8_e4m3fn)
    
    torch.cuda.synchronize()
    start = time.perf_counter()
    y = torch.matmul(x, w.t())
    torch.cuda.synchronize()
    return (time.perf_counter() - start) * 1000.0

print(f"FP8 Matrix Multiply Latency: {benchmark_fp8_linear():.2f} ms")''';
    } else if (lower.contains('risk') || lower.contains('security')) {
      responseText = 'Key architectural and security risks identified:\n1. Custom vLLM patch requirement introduces potential heap memory fragmentation.\n2. Requires strict CUDA 12.8+ runtime drivers.\n3. Verify critical technical decisions against official documentation.';
    } else {
      responseText = 'Synthesizing technical impact for "${card?.headline ?? prompt}":\n• 3.4x higher FLOPS throughput compared to prior FP16 baselines.\n• 84% reduction in inference VRAM footprint allowing execution on single-node setups.';
    }

    final chunks = responseText.split(' ');
    for (int i = 0; i < chunks.length; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield '${chunks[i]} ';
    }

    if (codeSnippet != null) {
      yield '\n\nCODE_BLOCK_MARKER:$codeSnippet';
    }

    yield '\n\n*AI-generated analysis may contain errors. Verify critical technical decisions.*';
  }
}
