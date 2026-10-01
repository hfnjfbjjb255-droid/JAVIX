/// Result of camera/voice analysis, rendered either as AR overlay text
/// or spoken aloud depending on the user's choice.
class SearchResult {
  final String label;
  final String detail;
  final double? confidence; // 0..1 for AI detections

  const SearchResult({required this.label, required this.detail, this.confidence});
}
