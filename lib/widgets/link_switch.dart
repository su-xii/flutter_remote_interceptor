import 'package:flutter/material.dart';


class LinkSwitch extends StatelessWidget {
  final bool isLink;
  final double size;
  final ValueChanged<bool> onChanged;
  const LinkSwitch({super.key,required this.isLink,this.size = 40.0,required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=> onChanged.call(!isLink),
      child: Container(
        height: size,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isLink ? Colors.blue : Colors.grey,
        ),
        child: Row(
          spacing: 4,
          children: isLink ? _() : _().reversed.toList(),
        ),
      ),
    );
  }

  List<Widget> _(){
    return [Center(child: Text(isLink ? "编辑模式" : "mock模式")),
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Icon(Icons.ac_unit),
      )];
  }
}
