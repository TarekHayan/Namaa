/// Supabase client factory entry point.
///
/// Kept as a separate surface so composition wires clients only through the
/// validated environment boundary (contracts/supabase-security.md).
library;

export 'package:namma_project/core/data/cloud/supabase/supabase_environment.dart';
