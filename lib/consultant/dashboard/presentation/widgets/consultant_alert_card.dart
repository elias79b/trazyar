import 'package:flutter/material.dart';


class ConsultantAlertCard extends StatelessWidget {
  const ConsultantAlertCard({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    final alerts = [

      const _AlertItem(
        title: 'افزایش غیرعادی هزینه',
        subtitle: 'شرکت بازرگانی آریا',
        type: AlertType.danger,
      ),


      const _AlertItem(
        title: 'کاهش نقدینگی',
        subtitle: 'شرکت تولیدی پارس',
        type: AlertType.warning,
      ),


      const _AlertItem(
        title: 'گزارش تایید نشده',
        subtitle: 'شرکت خدماتی نوین',
        type: AlertType.info,
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

            'هشدارهای مهم',

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



          ...alerts.map(

                (alert) => _AlertRow(
              item: alert,
            ),

          ),


        ],

      ),

    );

  }

}




class _AlertRow extends StatelessWidget {

  const _AlertRow({
    required this.item,
  });


  final _AlertItem item;


  @override
  Widget build(BuildContext context) {


    final color =
    _alertColor(item.type);



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
        color.withOpacity(.08),


        borderRadius:
        BorderRadius.circular(16),

      ),



      child: Row(

        children: [


          Container(

            width:
            38,

            height:
            38,


            decoration:
            BoxDecoration(

              color:
              color.withOpacity(.15),


              borderRadius:
              BorderRadius.circular(12),

            ),


            child:
            Icon(

              _alertIcon(
                item.type,
              ),

              color:
              color,

              size:
              21,

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

                  item.title,

                  style:
                  const TextStyle(

                    fontSize:
                    13,

                    fontWeight:
                    FontWeight.w800,

                  ),

                ),



                const SizedBox(
                  height: 4,
                ),



                Text(

                  item.subtitle,

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



          const Icon(

            Icons.chevron_left_rounded,

            size:
            22,

            color:
            Colors.grey,

          ),


        ],

      ),

    );

  }



  Color _alertColor(
      AlertType type,
      ) {

    switch(type) {

      case AlertType.danger:
        return Colors.red;

      case AlertType.warning:
        return Colors.orange;

      case AlertType.info:
        return Colors.blue;

    }

  }



  IconData _alertIcon(
      AlertType type,
      ) {

    switch(type) {

      case AlertType.danger:
        return Icons.warning_rounded;

      case AlertType.warning:
        return Icons.trending_down_rounded;

      case AlertType.info:
        return Icons.info_outline_rounded;

    }

  }

}




enum AlertType {

  danger,

  warning,

  info,

}




class _AlertItem {

  const _AlertItem({

    required this.title,

    required this.subtitle,

    required this.type,

  });


  final String title;

  final String subtitle;

  final AlertType type;

}