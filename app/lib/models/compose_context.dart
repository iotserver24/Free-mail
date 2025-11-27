class ComposeContext {
  final List<String>? to;
  final List<String>? cc;
  final List<String>? bcc;
  final String? subject;
  final String? body;
  final String? threadId;
  final String? inReplyTo;
  final String? references;

  const ComposeContext({
    this.to,
    this.cc,
    this.bcc,
    this.subject,
    this.body,
    this.threadId,
    this.inReplyTo,
    this.references,
  });

  ComposeContext copyWith({
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    String? subject,
    String? body,
    String? threadId,
    String? inReplyTo,
    String? references,
  }) {
    return ComposeContext(
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      threadId: threadId ?? this.threadId,
      inReplyTo: inReplyTo ?? this.inReplyTo,
      references: references ?? this.references,
    );
  }
}
