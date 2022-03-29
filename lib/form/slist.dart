typedef Slist = List<SlistEntry>;

class SlistEntry {
  final String? key, depend;
  final String label;

  const SlistEntry(this.key, this.label, this.depend);
}
