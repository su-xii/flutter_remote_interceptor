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
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isLink ? const Color(0xFF00BCD4).withOpacity(0.15) : Colors.grey.withOpacity(0.15),
          border: Border.all(
            color: isLink ? const Color(0xFF00BCD4).withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLink)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "Mock模式",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Container(
              width: size - 6,
              height: size - 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isLink ? const Color(0xFF00BCD4) : const Color(0xFF00BCD4),
                boxShadow: [
                  BoxShadow(
                    color: (isLink ? const Color(0xFF00BCD4) : const Color(0xFF00BCD4)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isLink ? Icons.edit_square : Icons.rule,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (isLink)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "编辑模式",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
