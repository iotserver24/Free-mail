class ComposeContext {
  final List<String>? to;
  final List<String>? cc;
  final List<String>? bcc;
  final String? subject;
  final String? body;
  final String? threadId;

  const ComposeContext({
    this.to,
    this.cc,
    this.bcc,
    this.subject,
    this.body,
    this.threadId,
  });

  ComposeContext copyWith({
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    String? subject,
    String? body,
    String? threadId,
  }) {
    return ComposeContext(
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      threadId: threadId ?? this.threadId,
    );
  }
}

