import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../screens/home/home_screen.dart';

class MenuTile extends StatelessWidget {
  final MenuTileData data;

  const MenuTile({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(data.route),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withValues(alpha: 0.08),
                blurRadius: AppSizes.cardShadowBlur,
                offset: const Offset(0, 4),
                spreadRadius: AppSizes.cardShadowSpread,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon in modern colored circle with gradient
                  Container(
                    width: AppSizes.gridTileIconContainerSize,
                    height: AppSizes.gridTileIconContainerSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          data.color.withValues(alpha: 0.15),
                          data.color.withValues(alpha: 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      size: AppSizes.gridTileIconSize,
                      color: data.color,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingS),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingS,
                    ),
                    child: Text(
                      data.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            letterSpacing: 0.1,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Helper text (if provided)
                  if (data.helperText != null) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingXS,
                      ),
                      child: Text(
                        data.helperText!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textLight,
                              fontSize: 9,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              // Badge (if provided)
              if (data.badgeCount != null && data.badgeCount! > 0)
                Positioned(
                  top: AppSizes.paddingS,
                  right: AppSizes.paddingS,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: AppSizes.badgeSize,
                      minHeight: AppSizes.badgeSize,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          data.badgeColor ?? AppColors.error,
                          (data.badgeColor ?? AppColors.error).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
                      boxShadow: [
                        BoxShadow(
                          color: (data.badgeColor ?? AppColors.error)
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      data.badgeCount! > 99 ? '99+' : '${data.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.badgeFontSize,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              // Indicator dot (for important items without count)
              if (data.hasIndicator == true)
                Positioned(
                  top: AppSizes.paddingM,
                  right: AppSizes.paddingM,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: data.badgeColor ?? AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (data.badgeColor ?? AppColors.error)
                              .withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
