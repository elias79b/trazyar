import 'package:flutter/material.dart';


class CompanySearchBox extends StatelessWidget {

  const CompanySearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });


  final TextEditingController controller;
  final ValueChanged<String> onChanged;


  @override
  Widget build(BuildContext context) {

    return TextField(

      controller: controller,

      onChanged: onChanged,


      decoration: InputDecoration(

        hintText:
        'جستجوی شرکت...',


        prefixIcon:
        const Icon(
          Icons.search_rounded,
        ),


        filled:
        true,


        fillColor:
        Colors.white,


        border:
        OutlineInputBorder(

          borderRadius:
          BorderRadius.circular(18),


          borderSide:
          BorderSide.none,

        ),


        enabledBorder:
        OutlineInputBorder(

          borderRadius:
          BorderRadius.circular(18),


          borderSide:
          BorderSide(
            color:
            Colors.grey.shade200,
          ),

        ),


      ),

    );

  }

}