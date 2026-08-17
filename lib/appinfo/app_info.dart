import 'package:flutter/cupertino.dart';
import 'package:flutter_projects/model/address_model.dart';

class AppInfo extends ChangeNotifier
{
  AddressModel? pickUpLocation;
  AddressModel? dropOffLocation;

  void updatePickupLocation(AddressModel pickUpModel)
  {
    pickUpLocation = pickUpModel;
    notifyListeners();
  }

  void updateDropOffLocation(AddressModel dropOffModel)
  {
    dropOffLocation = dropOffModel;
    notifyListeners();
  }
}