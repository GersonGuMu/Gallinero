import 'package:flutter/material.dart';

class ReguladorButton extends StatefulWidget {
  final double min;
  final double max;
  final double step;
  final double initialValue;
  final ValueChanged<double> onChanged;

  const ReguladorButton({
    Key? key,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.initialValue = 0,
    required this.onChanged,
  }) : super(key: key);

  @override
  _ReguladorButtonState createState() => _ReguladorButtonState();
}

class _ReguladorButtonState extends State<ReguladorButton> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  void _increment() {
    setState(() {
      _currentValue = (_currentValue + widget.step).clamp(widget.min, widget.max);
      widget.onChanged(_currentValue);
    });
  }

  void _decrement() {
    setState(() {
      _currentValue = (_currentValue - widget.step).clamp(widget.min, widget.max);
      widget.onChanged(_currentValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón -
          IconButton(
            onPressed: _decrement,
            icon: Icon(Icons.remove, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),

          // Valor actual
          Container(
            width: 50,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _currentValue.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Botón +
          IconButton(
            onPressed: _increment,
            icon: Icon(Icons.add, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}