import 'package:flutter/material.dart';

class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key, this.height = 220});

  final double height;

  static const _titleBlockHeight = 16.0;
  static const _titleGap = 16.0;

  @override
  Widget build(BuildContext context) {
    final compact = height < _titleBlockHeight + _titleGap + _titleBlockHeight + 32;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.all(16);

    return Card(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: padding,
          child: compact
              ? const _ShimmerBox(height: 14)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ShimmerBox(width: 140, height: _titleBlockHeight),
                    const SizedBox(height: _titleGap),
                    const Expanded(child: _ShimmerBox(height: double.infinity)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
