import 'package:flutter/material.dart';

/// Card compacto para mostrar el estado de varios requerimientos
/// (completado, falta o parcial/en progreso) con etiquetas legibles.
class RequirementStatusCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<RequirementStatusItem> items;
  final EdgeInsetsGeometry padding;

  const RequirementStatusCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 8),
          ...items.map(
            (item) => _RequirementRow(
              label: item.label,
              note: item.note,
              state: item.state,
            ),
          ),
        ],
      ),
    );
  }
}

class RequirementStatusItem {
  final String label;
  final RequirementState state;
  final String? note;

  const RequirementStatusItem({
    required this.label,
    required this.state,
    this.note,
  });
}

enum RequirementState { completed, missing, partial }

class _RequirementRow extends StatelessWidget {
  final String label;
  final String? note;
  final RequirementState state;

  const _RequirementRow({
    required this.label,
    required this.state,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    late final Color badgeColor;
    late final Color textColor;
    late final IconData icon;
    late final String text;

    switch (state) {
      case RequirementState.completed:
        badgeColor = colors.primary.withOpacity(0.14);
        textColor = colors.primary;
        icon = Icons.check_rounded;
        text = 'Completado';
        break;
      case RequirementState.partial:
        badgeColor = colors.tertiary.withOpacity(0.14);
        textColor = colors.tertiary;
        icon = Icons.timelapse_rounded;
        text = 'Parcial';
        break;
      case RequirementState.missing:
        badgeColor = Colors.red.withOpacity(0.12);
        textColor = Colors.red.shade600;
        icon = Icons.close_rounded;
        text = 'Falta';
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
