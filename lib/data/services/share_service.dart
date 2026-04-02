import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<bool> shareUpdateFile({
    required String filePath,
    required int version,
    required String deviceName,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: 'Money Loan Sync update from $deviceName. Data version $version.',
        subject: 'Money Loan Sync Update',
        files: [XFile(filePath)],
        fileNameOverrides: const ['moneyloan_update.mloan'],
      ),
    );

    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.unavailable;
  }
}
