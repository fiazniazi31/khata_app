import "package:flutter/cupertino.dart";

class CustomerProvider extends ChangeNotifier {
  double? totle;

  void getTotle(double giveAmount, double takeAmount) {
    totle = giveAmount - takeAmount;
    notifyListeners();
  }
}
