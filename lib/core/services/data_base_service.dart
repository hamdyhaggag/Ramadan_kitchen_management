abstract class DatabaseService {
  Future<void> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  });
  Future<dynamic> getData({
    required String path,
    required String docuementId,
  });
  Future<List<Map<String, dynamic>>> getAllData(String path);
  Future<void> updateData({
    required String path,
    required String documentId,
    required Map<String, dynamic> data,
  });
}
