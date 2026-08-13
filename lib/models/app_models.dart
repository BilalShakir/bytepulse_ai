enum CredibilityType { official, verified, analysis, speculation }

class IntelligenceCard {
  final String id;
  final String headline;
  final String summary;
  final CredibilityType credibilityType;
  final String source;
  final String readTime;
  final String transparencyReason;
  final String pros;
  final String cons;
  final String channelId;
  final String? userFeedback; // 'liked', 'disliked', or null
  final String groundedContext;
  final String url;
  final List<String> takeaways;

  IntelligenceCard({
    required this.id,
    required this.headline,
    required this.summary,
    required this.credibilityType,
    required this.source,
    required this.readTime,
    required this.transparencyReason,
    required this.pros,
    required this.cons,
    required this.channelId,
    this.userFeedback,
    required this.groundedContext,
    this.url = 'https://news.ycombinator.com',
    this.takeaways = const [
      'Distilled 14B and 32B models achieve 94% reasoning benchmark parity with 700B proprietary models.',
      'Significant reduction in inference VRAM cost enables high-throughput single-node deployment.',
      'Requires custom vLLM 0.6.2 runtime compilation patch for optimal tensor parallelism.',
    ],
  });

  IntelligenceCard copyWith({
    String? userFeedback,
  }) {
    return IntelligenceCard(
      id: id,
      headline: headline,
      summary: summary,
      credibilityType: credibilityType,
      source: source,
      readTime: readTime,
      transparencyReason: transparencyReason,
      pros: pros,
      cons: cons,
      channelId: channelId,
      userFeedback: userFeedback,
      groundedContext: groundedContext,
      url: url,
      takeaways: takeaways,
    );
  }
}

class Channel {
  final String id;
  final String name;
  final String followers;
  final String tag;
  final bool isFollowed;
  final String trending;

  Channel({
    required this.id,
    required this.name,
    required this.followers,
    required this.tag,
    required this.isFollowed,
    required this.trending,
  });
}

class AlertItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final String source;
  final String severity; // 'critical', 'high', 'info'

  AlertItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.source,
    required this.severity,
  });
}

class ChatMessage {
  final String id;
  final String sender; // 'user' or 'assistant'
  final String text;
  final String confidence;
  final List<String> citations;
  final String? codeSnippet;
  final bool saved;
  final String? suggestedTopic;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.confidence = '99.4%',
    this.citations = const [],
    this.codeSnippet,
    this.saved = false,
    this.suggestedTopic,
  });

  ChatMessage copyWith({bool? saved, String? suggestedTopic}) {
    return ChatMessage(
      id: id,
      sender: sender,
      text: text,
      confidence: confidence,
      citations: citations,
      codeSnippet: codeSnippet,
      saved: saved ?? this.saved,
      suggestedTopic: suggestedTopic ?? this.suggestedTopic,
    );
  }
}

class SavedItem {
  final String id;
  final String type; // 'gemini_answer' or 'article'
  final String title;
  final String snippet;
  final String? codeSnippet;
  final String savedAt;
  final String source;

  SavedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.snippet,
    this.codeSnippet,
    required this.savedAt,
    required this.source,
  });
}

class CustomTopic {
  final String id;
  final String name;
  final List<String> keywords;
  final String? rssUrl;
  final String addedAt;

  CustomTopic({
    required this.id,
    required this.name,
    required this.keywords,
    this.rssUrl,
    required this.addedAt,
  });
}

