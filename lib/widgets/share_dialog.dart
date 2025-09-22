import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/share_service.dart';
import '../utils/constants.dart';

class ShareDialog extends StatefulWidget {
  final ReportModel report;

  const ShareDialog({
    super.key,
    required this.report,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isSharing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: const BoxDecoration(
                color: Color(0xFF7B8AFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                  topRight: Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  const Expanded(
                    child: Text(
                      '리포트 공유',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // 내용
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 리포트 정보
                  _buildReportInfo(),
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // 커스텀 메시지
                  _buildCustomMessage(),
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // 공유 옵션들
                  _buildShareOptions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportInfo() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF7B8AFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.description,
              color: Color(0xFF7B8AFF),
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.report.title.isNotEmpty 
                      ? widget.report.title 
                      : '소음 측정 리포트',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '최대 ${widget.report.recording.noiseData.maxDecibel?.toStringAsFixed(1) ?? '0.0'}dB • '
                  '평균 ${widget.report.recording.noiseData.avgDecibel?.toStringAsFixed(1) ?? '0.0'}dB',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추가 메시지 (선택사항)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '공유할 때 포함할 메시지를 입력하세요...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              borderSide: const BorderSide(color: Color(0xFF7B8AFF)),
            ),
            contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildShareOptions() {
    final shareOptions = ShareService.instance.getShareOptions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공유 방법',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        ...shareOptions.map((option) => _buildShareOptionTile(option)),
      ],
    );
  }

  Widget _buildShareOptionTile(ShareOption option) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSharing ? null : () => _handleShareOption(option),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getOptionColor(option.action).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getOptionIcon(option.action),
                    color: _getOptionColor(option.action),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSharing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getOptionIcon(ShareAction action) {
    switch (action) {
      case ShareAction.text:
        return Icons.text_snippet;
      case ShareAction.email:
        return Icons.email;
      case ShareAction.sms:
        return Icons.sms;
      case ShareAction.system:
        return Icons.share;
    }
  }

  Color _getOptionColor(ShareAction action) {
    switch (action) {
      case ShareAction.text:
        return Colors.blue;
      case ShareAction.email:
        return Colors.red;
      case ShareAction.sms:
        return Colors.green;
      case ShareAction.system:
        return const Color(0xFF7B8AFF);
    }
  }

  Future<void> _handleShareOption(ShareOption option) async {
    setState(() {
      _isSharing = true;
    });

    try {
      final customMessage = _messageController.text.trim();
      
      switch (option.action) {
        case ShareAction.text:
        case ShareAction.system:
          await ShareService.instance.shareReport(
            widget.report,
            customMessage: customMessage.isNotEmpty ? customMessage : null,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('클립보드에 복사되었습니다')),
            );
          }
          break;
          
        case ShareAction.email:
          await _showEmailDialog(customMessage);
          break;
          
        case ShareAction.sms:
          await _showSMSDialog(customMessage);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _showEmailDialog(String customMessage) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('이메일 공유'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '받는 사람 이메일 (선택사항)',
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ShareService.instance.shareReportByEmail(
                    widget.report,
                    recipientEmail: _emailController.text.trim(),
                    customMessage: customMessage.isNotEmpty ? customMessage : null,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('이메일 공유 실패: $e')),
                    );
                  }
                }
              },
              child: const Text('공유'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSMSDialog(String customMessage) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('SMS 공유'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '받는 사람 번호 (선택사항)',
                  hintText: '010-1234-5678',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ShareService.instance.shareReportBySMS(
                    widget.report,
                    phoneNumber: _phoneController.text.trim(),
                    customMessage: customMessage.isNotEmpty ? customMessage : null,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('SMS 공유 실패: $e')),
                    );
                  }
                }
              },
              child: const Text('공유'),
            ),
          ],
        );
      },
    );
  }
}