/// Which chapter media blocks the Reader shows. Hidden media is still parsed
/// and kept on the chapter model.
///
/// Audio and video have no renderer yet; turning them on also needs one in
/// `RichTextBlockRenderer`.
class ReaderContentFeatures {
  const ReaderContentFeatures({
    this.readerImageSupport = true,
    this.readerAudioSupport = false,
    this.readerVideoSupport = false,
  });

  static const ReaderContentFeatures current = ReaderContentFeatures();

  final bool readerImageSupport;
  final bool readerAudioSupport;
  final bool readerVideoSupport;
}
