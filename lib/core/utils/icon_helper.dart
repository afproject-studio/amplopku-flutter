import 'package:flutter/material.dart';


class IconHelper {

  const IconHelper._();



  // ==========================================================
  // DETECT ICON UNTUK TRANSAKSI
  // ==========================================================


  static String detectIconName(
    String input, {
    bool isIncome = false,
  }) {


    final String text =
        input.toLowerCase().trim();



    if (isIncome) {


      if (_containsAny(text, const [
        'gaji',
        'salary',
        'upah',
        'honor',
        'payroll',
      ])) {

        return 'salary';

      }


      if (_containsAny(text, const [
        'bonus',
        'komisi',
        'reward',
        'hadiah',
      ])) {

        return 'bonus';

      }


      if (_containsAny(text, const [
        'jualan',
        'penjualan',
        'usaha',
        'bisnis',
        'dagang',
        'profit',
      ])) {

        return 'business';

      }


      if (_containsAny(text, const [
        'investasi',
        'dividen',
        'saham',
        'deposito',
        'bunga',
      ])) {

        return 'investment';

      }


      return 'income';

    }






    if (_containsAny(text, const [
      'makan',
      'makanan',
      'minum',
      'kopi',
      'cafe',
      'restoran',
      'warung',
      'ayam',
      'bakso',
    ])) {

      return 'food';

    }




    if (_containsAny(text, const [
      'motor',
      'mobil',
      'bensin',
      'transport',
      'grab',
      'gojek',
      'parkir',
    ])) {

      return 'transport';

    }





    if (_containsAny(text, const [
      'listrik',
      'wifi',
      'internet',
      'tagihan',
      'pulsa',
    ])) {

      return 'bill';

    }





    if (_containsAny(text, const [
      'belanja',
      'baju',
      'sepatu',
      'shopping',
    ])) {

      return 'shopping';

    }





    if (_containsAny(text, const [
      'rumah',
      'kos',
      'sewa',
      'apartemen',
    ])) {

      return 'home';

    }





    if (_containsAny(text, const [
      'sekolah',
      'kuliah',
      'pendidikan',
    ])) {

      return 'education';

    }




    return 'wallet';

  }







  // ==========================================================
  // DETECT ICON UNTUK TARGET TABUNGAN
  // ==========================================================


  static String detectTargetIconName(
    String input,
  ) {


    final String text =
        input.toLowerCase().trim();




    if (_containsAny(text, const [

      'laptop',
      'komputer',
      'pc',
      'macbook',

    ])) {

      return 'laptop';

    }





    if (_containsAny(text, const [

      'hp',
      'handphone',
      'iphone',
      'smartphone',

    ])) {

      return 'phone';

    }





    if (_containsAny(text, const [

      'motor',
      'motorcycle',
      'sepeda',

    ])) {

      return 'motorcycle';

    }





    if (_containsAny(text, const [

      'mobil',
      'car',

    ])) {

      return 'car';

    }





    if (_containsAny(text, const [

      'rumah',
      'apartemen',

    ])) {

      return 'home';

    }





    if (_containsAny(text, const [

      'liburan',
      'travel',
      'wisata',
      'jalan',

    ])) {

      return 'flight';

    }





    if (_containsAny(text, const [

      'nikah',
      'pernikahan',
      'kawin',

    ])) {

      return 'favorite';

    }





    if (_containsAny(text, const [

      'kamera',
      'camera',
      'foto',

    ])) {

      return 'camera';

    }





    if (_containsAny(text, const [

      'gaming',
      'game',
      'playstation',

    ])) {

      return 'game';

    }





    if (_containsAny(text, const [

      'kuliah',
      'pendidikan',
      'sekolah',

    ])) {

      return 'education';

    }





    return 'saving';

  }







  // ==========================================================
  // CONVERT STRING → ICON FLUTTER
  // ==========================================================


  static IconData getIcon(
    String? iconName,
  ) {


    switch(iconName) {


      case 'laptop':
        return Icons.laptop_rounded;


      case 'phone':
        return Icons.phone_android_rounded;


      case 'motorcycle':
        return Icons.motorcycle_rounded;


      case 'car':
        return Icons.directions_car_rounded;


      case 'flight':
        return Icons.flight_takeoff_rounded;


      case 'favorite':
        return Icons.favorite_rounded;


      case 'camera':
        return Icons.camera_alt_rounded;


      case 'game':
        return Icons.sports_esports_rounded;


      case 'food':
        return Icons.restaurant_rounded;


      case 'transport':
        return Icons.directions_car_rounded;


      case 'bill':
        return Icons.receipt_long_rounded;


      case 'shopping':
        return Icons.shopping_bag_rounded;


      case 'home':
        return Icons.home_rounded;


      case 'education':
        return Icons.school_rounded;


      case 'health':
        return Icons.health_and_safety_rounded;


      case 'entertainment':
        return Icons.movie_rounded;


      case 'saving':
        return Icons.savings_rounded;


      case 'investment':
        return Icons.trending_up_rounded;


      case 'salary':
        return Icons.payments_rounded;


      case 'bonus':
        return Icons.card_giftcard_rounded;


      case 'business':
        return Icons.storefront_rounded;


      case 'income':
        return Icons.arrow_downward_rounded;


      case 'wallet':
      default:
        return Icons.account_balance_wallet_rounded;

    }

  }







  static bool _containsAny(
    String text,
    List<String> keywords,
  ) {


    for(final keyword in keywords) {


      if(text.contains(keyword)) {

        return true;

      }


    }


    return false;

  }


}