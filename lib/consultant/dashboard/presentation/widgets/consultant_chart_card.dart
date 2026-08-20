import 'package:flutter/material.dart';


class ConsultantChartCard extends StatelessWidget {
  const ConsultantChartCard({
    super.key,
    required this.title,
    required this.subtitle,
  });


  final String title;
  final String subtitle;


  @override
  Widget build(BuildContext context) {

    final values = [
      0.35,
      0.48,
      0.42,
      0.68,
      0.75,
      0.82,
    ];


    return Container(

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(22),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

      ),


      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,


        children: [


          Text(

            title,

            style: const TextStyle(

              fontSize: 17,

              fontWeight:
              FontWeight.w900,

              color:
              Color(0xFF17211D),

            ),

          ),



          const SizedBox(height: 5),



          Text(

            subtitle,

            style: TextStyle(

              fontSize: 12,

              color:
              Colors.grey.shade600,

            ),

          ),



          const SizedBox(height: 28),



          SizedBox(

            height: 190,

            child: Row(

              crossAxisAlignment:
              CrossAxisAlignment.end,


              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,


              children: List.generate(

                values.length,


                    (index) {


                  return Column(

                    mainAxisAlignment:
                    MainAxisAlignment.end,


                    children: [


                      Expanded(

                        child: Align(

                          alignment:
                          Alignment.bottomCenter,


                          child:
                          Container(

                            width: 28,


                            height:
                            150 *
                                values[index],


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

                          ),

                        ),

                      ),



                      const SizedBox(height: 8),



                      Text(

                        _month(index),

                        style: TextStyle(

                          fontSize: 10,

                          color:
                          Colors.grey.shade600,

                        ),

                      ),


                    ],

                  );

                },

              ),

            ),

          ),



        ],

      ),

    );

  }



  String _month(int index) {

    const months = [

      'فر',

      'ار',

      'خر',

      'تی',

      'مر',

      'شه',

    ];


    return months[index];

  }

}