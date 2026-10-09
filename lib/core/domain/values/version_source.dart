/// Cross-cutting version-source classification shared by Domain and
/// application ports.
///
/// Part of the Foundation Domain: infrastructure-free.
library;

/// Which side produced a record version.
enum VersionSource { local, remote }
