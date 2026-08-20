import 'package:flutter/material.dart';


class CompanyCompareCard extends StatelessWidget {
  const CompanyCompareCard({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

    final companies = [
      const _CompanyData(
        name: 'شرکت بازرگانی آریا',
        value: 0.85,
        status: 'مطلوب',
      ),

      const _CompanyData(
        name: 'شرکت تولیدی پارس',
        value: 0.65,
        status: 'متوسط',
      ),

      const _CompanyData(
        name: 'شرکت خدماتی نوین',
        value: 0.92,
        status: 'عالی',
      ),
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


          const Text(

            'مقایسه عملکرد شرکت‌ها',

            style: TextStyle(

              fontSize: 17,

              fontWeight:
              FontWeight.w900,

              color:
              Color(0xFF17211D),

            ),

          ),


          const SizedBox(height: 6),


          Text(

            'نمای کلی وضعیت شرکت‌های تحت مدیریت',

            style: TextStyle(

              fontSize: 12,

              color:
              Colors.grey.shade600,

            ),

          ),


          const SizedBox(height: 24),



          ...companies.map(
                (company) =>
                _CompanyProgressItem(
                  company: company,
                ),
          ),


        ],

      ),

    );

  }
}




class _CompanyProgressItem extends StatelessWidget {

  const _CompanyProgressItem({

    required this.company,

  });


  final _CompanyData company;



  @override
  Widget build(BuildContext context) {

    return Padding(

      padding:
      const EdgeInsets.only(
        bottom: 18,
      ),


      child: Column(

        children: [


          Row(

            children: [


              Expanded(

                child: Text(

                  company.name,

                  style: const TextStyle(

                    fontSize: 13,

                    fontWeight:
                    FontWeight.w700,

                  ),

                ),

              ),


              Container(

                padding:
                const EdgeInsets.symmetric(

                  horizontal: 10,

                  vertical: 4,

                ),


                decoration:
                BoxDecoration(

                  color:
                  _statusColor(
                    company.value,
                  ).withOpacity(.12),

                  borderRadius:
                  BorderRadius.circular(20),

                ),


                child: Text(

                  company.status,

                  style: TextStyle(

                    fontSize: 10,

                    fontWeight:
                    FontWeight.bold,

                    color:
                    _statusColor(
                      company.value,
                    ),

                  ),

                ),

              ),


            ],

          ),



          const SizedBox(height: 10),



          ClipRRect(

            borderRadius:
            BorderRadius.circular(20),


            child:
            LinearProgressIndicator(

              value:
              company.value,


              minHeight:
              10,


              backgroundColor:
              Colors.grey.shade200,


              valueColor:
              AlwaysStoppedAnimation(

                _statusColor(
                  company.value,
                ),

              ),

            ),

          ),


        ],

      ),

    );

  }



  Color _statusColor(double value) {

    if (value >= .85) {

      return const Color(
        0xFF2D6A4F,
      );

    }


    if (value >= .7) {

      return const Color(
        0xFFE9A23B,
      );

    }


    return Colors.red;

  }

}




class _CompanyData {

  const _CompanyData({

    required this.name,

    required this.value,

    required this.status,

  });


  final String name;

  final double value;

  final String status;

}