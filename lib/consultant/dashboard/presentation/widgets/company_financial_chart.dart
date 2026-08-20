import 'package:flutter/material.dart';


class CompanyFinancialChart extends StatelessWidget {

  const CompanyFinancialChart({
    super.key,
  });



  @override
  Widget build(BuildContext context) {


    final data = [

      0.3,
      0.45,
      0.55,
      0.4,
      0.75,
      0.9,

    ];



    return Container(

      padding:
      const EdgeInsets.all(22),


      decoration:
      BoxDecoration(

        color:
        Colors.white,


        borderRadius:
        BorderRadius.circular(22),


        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),

      ),


      child:
      Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,


        children: [


          const Text(

            'روند مالی شرکت',

            style:
            TextStyle(

              fontSize:
              17,

              fontWeight:
              FontWeight.w900,

            ),

          ),



          const SizedBox(
            height: 25,
          ),



          SizedBox(

            height:
            180,


            child:
            Row(

              crossAxisAlignment:
              CrossAxisAlignment.end,


              mainAxisAlignment:
              MainAxisAlignment.spaceAround,


              children:

              List.generate(

                data.length,


                    (index) {

                  return Container(

                    width:
                    28,


                    height:
                    150 *
                        data[index],


                    decoration:
                    BoxDecoration(

                      color:
                      const Color(
                        0xFF2D6A4F,
                      ),


                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),

                    ),

                  );

                },

              ),

            ),

          ),


        ],

      ),

    );

  }

}