import 'package:flutter/material.dart';

class HorizontalScrollableTable extends StatefulWidget {
  final Widget child;

  const HorizontalScrollableTable({super.key, required this.child});

  @override
  State<HorizontalScrollableTable> createState() =>
      _HorizontalScrollableTableState();
}

class _HorizontalScrollableTableState extends State<HorizontalScrollableTable> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0), // Give room so scrollbar doesn't cover table row details
          child: widget.child,
        ),
      ),
    );
  }
}
