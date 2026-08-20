import 'package:flutter/material.dart';


class ConsultantCompanyCard extends StatelessWidget {

  const ConsultantCompanyCard({
    super.key,
    required this.name,
    required this.industry,
    required this.status,
    required this.lastActivity,
    required this.onTap,
  });


  final String name;
  final String industry;
  final String status;
  final String lastActivity;
  final VoidCallback onTap;



  @override
  Widget build(BuildContext context) {


    final active =
        status == 'فعال';



    return InkWell(

      onTap: onTap,


      borderRadius:
      BorderRadius.circular(22),


      child: Container(

        padding:
        const EdgeInsets.all(18),


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



        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [



            Row(

              children: [


                Container(

                  width:
                  52,

                  height:
                  52,


                  decoration:
                  BoxDecoration(

                    color:
                    const Color(0xFF1B4332)
                        .withOpacity(.10),


                    borderRadius:
                    BorderRadius.circular(16),

                  ),


                  child:
                  const Icon(

                    Icons.business_rounded,

                    color:
                    Color(0xFF1B4332),

                  ),

                ),



                const SizedBox(
                  width: 12,
                ),



                Expanded(

                  child:
                  Text(

                    name,

                    maxLines:
                    1,

                    overflow:
                    TextOverflow.ellipsis,


                    style:
                    const TextStyle(

                      fontSize:
                      15,

                      fontWeight:
                      FontWeight.w900,

                    ),

                  ),

                ),


              ],

            ),




            const SizedBox(
              height: 18,
            ),




            _InfoRow(

              icon:
              Icons.category_outlined,

              text:
              industry,

            ),



            const SizedBox(
              height: 8,
            ),



            _InfoRow(

              icon:
              Icons.access_time_rounded,

              text:
              'آخرین فعالیت: $lastActivity',

            ),



            const Spacer(),



            Container(

              padding:
              const EdgeInsets.symmetric(

                horizontal:
                12,

                vertical:
                6,

              ),


              decoration:
              BoxDecoration(

                color:
                active

                    ? Colors.green.withOpacity(.12)

                    : Colors.grey.withOpacity(.12),


                borderRadius:
                BorderRadius.circular(20),

              ),


              child:
              Text(

                status,


                style:
                TextStyle(

                  fontSize:
                  11,


                  color:
                  active

                      ? Colors.green

                      : Colors.grey,


                  fontWeight:
                  FontWeight.bold,

                ),

              ),

            ),



          ],

        ),

      ),

    );

  }

}



class _InfoRow extends StatelessWidget {


  const _InfoRow({

    required this.icon,

    required this.text,

  });



  final IconData icon;
  final String text;



  @override
  Widget build(BuildContext context) {

    return Row(

      children: [


        Icon(

          icon,

          size:
          17,

          color:
          Colors.grey.shade600,

        ),



        const SizedBox(
          width: 8,
        ),



        Expanded(

          child:
          Text(

            text,

            maxLines:
            1,

            overflow:
            TextOverflow.ellipsis,


            style:
            TextStyle(

              fontSize:
              12,

              color:
              Colors.grey.shade700,

            ),

          ),

        ),


      ],

    );

  }

}