import 'package:amplopku/models/user_model.dart';
import 'package:amplopku/core/utils/icon_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService{

  final FirebaseFirestore _firestore =
  FirebaseFirestore.instance;


  CollectionReference<Map<String,dynamic>> get users{

    return _firestore.collection('users');

  }



  // ==========================================================
  // USER
  // ==========================================================


  Future<void> createUser({

    required String uid,

    required String nama,

    required String email,

  }) async{


    await users.doc(uid).set({

      'uid':
      uid,

      'nama':
      nama,

      'email':
      email,

      'photoUrl':
      '',

      'setupCompleted':
      false,

      'createdAt':
      FieldValue.serverTimestamp(),

      'updatedAt':
      FieldValue.serverTimestamp(),

    });


  }




  Future<UserModel> getUser(
    String uid,
  ) async{


    final snapshot=
    await users.doc(uid).get();


    final data=
    snapshot.data();


    if(data==null){

      throw Exception(
        'Data pengguna tidak ditemukan',
      );

    }


    return UserModel.fromMap(data);


  }




  Stream<DocumentSnapshot<Map<String,dynamic>>> userStream(
    String uid,
  ){

    return users
        .doc(uid)
        .snapshots();

  }




  Future<void> updateProfile({
    required String uid,
    required String nama,
  }) async {
    await users.doc(uid).set(
      {
        'nama': nama.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Menyamakan email pada dokumen Firestore dengan email Firebase Auth.
  /// Pemanggilan ini dilakukan setelah perubahan email telah diverifikasi.
  Future<void> updateUserEmail({
    required String uid,
    required String email,
  }) async {
    await users.doc(uid).set(
      {
        'email': email.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }





  // ==========================================================
  // FINANCE SETTINGS
  // ==========================================================



Future<void> saveIncome({
  required String uid,
  required double income,
  required DateTime incomeDate,
}) async {

  await users
      .doc(uid)
      .collection('settings')
      .doc('finance')
      .set({

    'income':
    income,

    'incomeDate':
    Timestamp.fromDate(
      incomeDate,
    ),

    'currency':
    'IDR',

    'updatedAt':
    FieldValue.serverTimestamp(),

  });

}



  Future<DocumentSnapshot<Map<String,dynamic>>> getFinance(
    String uid,
  ){

    return users

        .doc(uid)

        .collection('settings')

        .doc('finance')

        .get();

  }



  Stream<DocumentSnapshot<Map<String,dynamic>>> financeStream(
    String uid,
  ){

    return users

        .doc(uid)

        .collection('settings')

        .doc('finance')

        .snapshots();

  }
    // ==========================================================
  // ENVELOPE
  // ==========================================================


  Future<void> saveEnvelope({

    required String uid,

    required String nama,

    required double percentage,

    required double budget,

    required int color,

    required String icon,

  }) async{


    if(nama.trim().isEmpty){

      throw Exception(
        'Nama amplop wajib diisi',
      );

    }



    await users

        .doc(uid)

        .collection('envelopes')

        .add({

      'nama':
      nama.trim(),


      'percentage':
      percentage,


      'budget':
      budget,


      'balance':
      budget,


      'spent':
      0.0,


      'color':
      color,


      'icon':
      icon,


      'createdAt':
      FieldValue.serverTimestamp(),


      'updatedAt':
      FieldValue.serverTimestamp(),


    });


  }




  Stream<QuerySnapshot<Map<String,dynamic>>> getEnvelopes(
    String uid,
  ){


    return users

        .doc(uid)

        .collection('envelopes')

        .orderBy(
          'createdAt',
        )

        .snapshots();


  }





  Future<void> updateEnvelope({

    required String uid,

    required String envelopeId,

    required String nama,

    required double percentage,

    required double budget,

    required int color,

    required String icon,

  }) async{


    final ref =
    users

        .doc(uid)

        .collection('envelopes')

        .doc(envelopeId);



    final snapshot=
    await ref.get();



    if(!snapshot.exists){

      throw Exception(
        'Amplop tidak ditemukan',
      );

    }



    final data=
    snapshot.data();



    final spent=
    (data?['spent'] as num?)
        ?.toDouble() ?? 0;



    if(budget < spent){

      throw Exception(
        'Budget tidak boleh lebih kecil dari pengeluaran',
      );

    }



    await ref.update({

      'nama':
      nama.trim(),


      'percentage':
      percentage,


      'budget':
      budget,


      'balance':
      budget-spent,


      'color':
      color,


      'icon':
      icon,


      'updatedAt':
      FieldValue.serverTimestamp(),


    });


  }





  Future<void> deleteEnvelope({

    required String uid,

    required String envelopeId,

  }) async{


    final check=
    await users

        .doc(uid)

        .collection('transactions')

        .where(
      'envelopeId',
      isEqualTo:
      envelopeId,
    )

        .limit(1)

        .get();



    if(check.docs.isNotEmpty){

      throw Exception(
        'Amplop memiliki transaksi',
      );

    }



    await users

        .doc(uid)

        .collection('envelopes')

        .doc(envelopeId)

        .delete();


  }





  // ==========================================================
  // TRANSACTION
  // ==========================================================
    Future<void> addTransaction({

    required String uid,

    required String title,

    required String description,

    required double amount,

    required String type,

    required String envelopeId,

    required String icon,

    required DateTime date,

  }) async{


    if(title.trim().isEmpty){

      throw Exception(
        'Nama transaksi wajib diisi',
      );

    }


    if(amount<=0){

      throw Exception(
        'Nominal transaksi harus lebih dari 0',
      );

    }


    if(type!='income' && type!='expense'){

      throw Exception(
        'Jenis transaksi tidak valid',
      );

    }


    final userRef=
    users.doc(uid);



    final transactionRef=
    userRef
        .collection('transactions')
        .doc();



    await _firestore.runTransaction(
          (transaction) async{


        if(
        type=='expense' &&
            envelopeId.isNotEmpty
        ){


          final envelopeRef=
          userRef

              .collection('envelopes')

              .doc(envelopeId);



          final envelopeSnapshot=
          await transaction.get(
            envelopeRef,
          );



          if(!envelopeSnapshot.exists){

            throw Exception(
              'Amplop tidak ditemukan',
            );

          }



          final data=
          envelopeSnapshot.data()!;



          final oldSpent=
          (data['spent'] as num?)
              ?.toDouble() ?? 0.0;



          final oldBalance=
          (data['balance'] as num?)
              ?.toDouble() ?? 0.0;



          final envelopeName=
          (data['nama'] ?? 'Amplop')
              .toString();



          // Jangan izinkan pengeluaran jika budget sudah habis.
          if(oldBalance<=0){

            throw Exception(
              'Budget $envelopeName sudah habis. Pilih amplop lain atau Tanpa amplop.',
            );

          }



          // Jangan izinkan nominal lebih besar daripada sisa budget.
          if(amount>oldBalance){

            throw Exception(
              'Nominal melebihi sisa budget $envelopeName. Sisa budget: Rp ${oldBalance.toStringAsFixed(0)}',
            );

          }



          final newSpent=
          oldSpent+amount;



          final calculatedBalance=
          oldBalance-amount;



          // Melindungi dari nilai minus sangat kecil akibat perhitungan desimal.
          final newBalance=
          calculatedBalance<0
              ? 0.0
              : calculatedBalance;



          transaction.update(

            envelopeRef,

            {

              'spent':
              newSpent,


              'balance':
              newBalance,


              'updatedAt':
              FieldValue.serverTimestamp(),

            },

          );


        }




        transaction.set(

          transactionRef,

          {

            'title':
            title.trim(),


            'description':
            description.trim(),


            'amount':
            amount,


            'type':
            type,


            'envelopeId':
            envelopeId,


            'icon':
            icon,


            'date':
            Timestamp.fromDate(
              date,
            ),


            'createdAt':
            FieldValue.serverTimestamp(),


            'updatedAt':
            FieldValue.serverTimestamp(),


          },

        );


      },


    );


  }





  Stream<QuerySnapshot<Map<String,dynamic>>> getTransactions(
    String uid,
  ){

    return users

        .doc(uid)

        .collection('transactions')

        .orderBy(
      'date',
      descending:true,
    )

        .snapshots();


  }





  Future<void> deleteTransaction({

    required String uid,

    required String transactionId,

  }) async{


    await users

        .doc(uid)

        .collection('transactions')

        .doc(transactionId)

        .delete();


  }




  // ==========================================================
  // SAVING TARGET
  // ==========================================================


  Future<void> addSavingTarget({

    required String uid,

    required String title,

    required double targetAmount,

    required double currentAmount,

    required DateTime deadline,

  }) async{


    if(title.trim().isEmpty){

      throw Exception(
        'Nama target wajib diisi',
      );

    }



    if(targetAmount<=0){

      throw Exception(
        'Target harus lebih dari 0',
      );

    }



    await users

        .doc(uid)

        .collection('savingTargets')

        .add({

      'title':
      title.trim(),


      'targetAmount':
      targetAmount,


      'currentAmount':
      currentAmount,


      'deadline':
      Timestamp.fromDate(
        deadline,
      ),


      'icon':
      IconHelper.detectTargetIconName(
        title,
      ),


      'createdAt':
      FieldValue.serverTimestamp(),


      'updatedAt':
      FieldValue.serverTimestamp(),


    });


  }




  Stream<QuerySnapshot<Map<String,dynamic>>> getSavingTargets(
    String uid,
  ){

    return users

        .doc(uid)

        .collection('savingTargets')

        .orderBy(
      'createdAt',
      descending:true,
    )

        .snapshots();


  }




  Future<void> updateSavingTarget({

    required String uid,

    required String targetId,

    required String title,

    required double targetAmount,

    required double currentAmount,

    required DateTime deadline,

  }) async{


    await users

        .doc(uid)

        .collection('savingTargets')

        .doc(targetId)

        .update({

      'title':
      title.trim(),


      'targetAmount':
      targetAmount,


      'currentAmount':
      currentAmount,


      'deadline':
      Timestamp.fromDate(
        deadline,
      ),


      'icon':
      IconHelper.detectTargetIconName(
        title,
      ),


      'updatedAt':
      FieldValue.serverTimestamp(),

    });


  }




  Future<void> addSavingAmount({

    required String uid,

    required String targetId,

    required double amount,

  }) async{


    final ref=
    users

        .doc(uid)

        .collection('savingTargets')

        .doc(targetId);



    final snapshot=
    await ref.get();



    if(!snapshot.exists){

      throw Exception(
        'Target tidak ditemukan',
      );

    }



    final data=
    snapshot.data();



    final current=
    (data?['currentAmount'] as num?)
        ?.toDouble() ?? 0;



    await ref.update({

      'currentAmount':
      current+amount,


      'updatedAt':
      FieldValue.serverTimestamp(),

    });


  }





  Future<void> deleteSavingTarget({

    required String uid,

    required String targetId,

  }) async{


    await users

        .doc(uid)

        .collection('savingTargets')

        .doc(targetId)

        .delete();


  }




  Future<void> finishSetup(
    String uid,
  ) async{


    await users

        .doc(uid)

        .update({

      'setupCompleted':
      true,


      'updatedAt':
      FieldValue.serverTimestamp(),


    });


  }


}