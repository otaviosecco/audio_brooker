import 'package:flutter/foundation.dart';

class YtdlNotifier extends ChangeNotifier{

  YtdlNotifier();
  
  void update(){
    notifyListeners();
  }
}