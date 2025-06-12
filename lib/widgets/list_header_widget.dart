import 'package:flutter/material.dart';

class ListHeaderWidget extends StatelessWidget {
  final double total;
  final bool isOverBudget;
  final double? budgetLimit;
  final double remainingBudget;

  const ListHeaderWidget({
    super.key,
    required this.total,
    required this.isOverBudget,
    this.budgetLimit,
    required this.remainingBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTotalInfo(context),
              if (budgetLimit != null) _buildBudgetInfo(context),
            ],
          ),
          if (budgetLimit != null) ...[
            const SizedBox(height: 16),
            _buildProgressBar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total da Lista',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'R\$ ${total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isOverBudget ? Colors.red.shade300 : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Disponível',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'R\$ ${remainingBudget.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isOverBudget ? Colors.red.shade300 : Colors.green.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: total / budgetLimit!,
        backgroundColor: Colors.grey.shade800,
        valueColor: AlwaysStoppedAnimation(
          isOverBudget ? Colors.red.shade300 : Colors.green.shade300,
        ),
        minHeight: 8,
      ),
    );
  }
}
