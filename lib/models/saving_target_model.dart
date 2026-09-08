import 'package:cloud_firestore/cloud_firestore.dart';


class SavingTargetModel {

  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String icon;


  SavingTargetModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.icon,
  });



  factory SavingTargetModel.fromMap(
    String id,
    Map<String,dynamic> data,
  ){

    return SavingTargetModel(

      id: id,

      title:
          (data['title'] ?? '')
              .toString(),

      targetAmount:
          (data['targetAmount'] as num?)
              ?.toDouble() ??
              0,


      currentAmount:
          (data['currentAmount'] as num?)
              ?.toDouble() ??
              0,


      deadline:
          data['deadline'] is Timestamp
              ? (data['deadline'] as Timestamp)
                  .toDate()
              : DateTime.now(),


      icon:
          (data['icon'] ?? 'savings')
              .toString(),

    );

  }


}