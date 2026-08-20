import 'package:flutter/material.dart';


class ConsultantActionCard extends StatelessWidget {
  const ConsultantActionCard({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    final actions = [

      const _ActionItem(
        title: 'بررسی افزایش هزینه شرکت آریا',
        company: 'شرکت بازرگانی آریا',
        status: 'در حال بررسی',
        priority: ActionPriority.high,
      ),


      const _ActionItem(
        title: 'تحلیل کاهش فروش',
        company: 'شرکت تولیدی پارس',
        status: 'جدید',
        priority: ActionPriority.medium,
      ),


      const _ActionItem(
        title: 'بررسی گزارش مالی',
        company: 'شرکت خدماتی نوین',
        status: 'تکمیل شده',
        priority: ActionPriority.done,
      ),

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


      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,


        children: [


          const Text(

            'اقدامات فعال',

            style:
            TextStyle(

              fontSize:
              17,

              fontWeight:
              FontWeight.w900,

              color:
              Color(0xFF17211D),

            ),

          ),


          const SizedBox(
            height: 18,
          ),



          ...actions.map(

                (action) => _ActionRow(
              action: action,
            ),

          ),


        ],

      ),

    );

  }

}




class _ActionRow extends StatelessWidget {

  const _ActionRow({
    required this.action,
  });


  final _ActionItem action;



  @override
  Widget build(BuildContext context) {


    final color =
    _priorityColor(
      action.priority,
    );


    return Container(

      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),


      padding:
      const EdgeInsets.all(14),


      decoration:
      BoxDecoration(

        color:
        const Color(0xFFF8FAF9),


        borderRadius:
        BorderRadius.circular(16),

      ),



      child: Row(

        children: [


          Container(

            width:
            42,

            height:
            42,


            decoration:
            BoxDecoration(

              color:
              color.withOpacity(.12),


              borderRadius:
              BorderRadius.circular(13),

            ),


            child:
            Icon(

              Icons.task_alt_rounded,

              color:
              color,

              size:
              22,

            ),

          ),



          const SizedBox(
            width: 12,
          ),



          Expanded(

            child:
            Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,


              children: [


                Text(

                  action.title,

                  maxLines:
                  1,

                  overflow:
                  TextOverflow.ellipsis,


                  style:
                  const TextStyle(

                    fontSize:
                    13,

                    fontWeight:
                    FontWeight.w800,

                  ),

                ),



                const SizedBox(
                  height: 5,
                ),



                Text(

                  action.company,

                  style:
                  TextStyle(

                    fontSize:
                    11,

                    color:
                    Colors.grey.shade600,

                  ),

                ),


              ],

            ),

          ),



          Container(

            padding:
            const EdgeInsets.symmetric(

              horizontal:
              9,

              vertical:
              5,

            ),


            decoration:
            BoxDecoration(

              color:
              color.withOpacity(.12),


              borderRadius:
              BorderRadius.circular(20),

            ),


            child:
            Text(

              action.status,

              style:
              TextStyle(

                fontSize:
                10,

                color:
                color,

                fontWeight:
                FontWeight.bold,

              ),

            ),

          ),


        ],

      ),

    );

  }



  Color _priorityColor(
      ActionPriority priority,
      ) {

    switch(priority) {

      case ActionPriority.high:
        return Colors.red;

      case ActionPriority.medium:
        return Colors.orange;

      case ActionPriority.done:
        return const Color(0xFF2D6A4F);

    }

  }

}




enum ActionPriority {

  high,

  medium,

  done,

}




class _ActionItem {

  const _ActionItem({

    required this.title,

    required this.company,

    required this.status,

    required this.priority,

  });


  final String title;

  final String company;

  final String status;

  final ActionPriority priority;

}