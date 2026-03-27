import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<bool> shareUpdateFile({
    required String filePath,
    required int version,
    required String deviceName,
  }) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: 'Money Loan update from $deviceName. Version $version.',
        subject: 'Money Loan update',
        files: [XFile(filePath)],
        fileNameOverrides: const ['moneyloan_update.mloan'],
      ),
    );

    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.unavailable;
  }
}

