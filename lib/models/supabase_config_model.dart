class SupabaseConfigModel {
  String projectUrl;
  String anonKey;
  bool isConnected;

  SupabaseConfigModel({
    this.projectUrl = 'https://xyzcompany.supabase.co',
    this.anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    this.isConnected = true,
  });
}
