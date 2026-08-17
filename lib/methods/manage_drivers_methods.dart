import 'package:flutter_projects/model/online_nearby_drivers.dart';

class ManageDriversMethods
{
  static List<OnlineNearbyDrivers> nearbyOnlineDriversList = [];

  static void removeDriverFromList(String driverID)
  {
    int index = nearbyOnlineDriversList.indexWhere((driver) => driver.uidDriver == driverID);

    // indexWhere returns -1 when the driver is not in the list, and a driver
    // that already went offline is exactly the case this method is called for.
    // Guarding on isNotEmpty checked the wrong thing: with a non-empty list and
    // an absent driver, removeAt(-1) throws RangeError.
    if (index != -1)
      {
        nearbyOnlineDriversList.removeAt(index);
      }
  }
  static void updateOnlineNearbyDriversLocation(OnlineNearbyDrivers nearbyOnlineDriverInformation)
  {
    int index = nearbyOnlineDriversList.indexWhere((driver) => driver.uidDriver == nearbyOnlineDriverInformation.uidDriver);

    // A location update can arrive for a driver who entered the radius before
    // this list was built, so an unknown driver is added rather than dropped —
    // indexing at -1 would have thrown, and ignoring it would have hidden a car
    // that is genuinely nearby.
    if (index == -1)
      {
        nearbyOnlineDriversList.add(nearbyOnlineDriverInformation);
        return;
      }

    nearbyOnlineDriversList[index].latDriver = nearbyOnlineDriverInformation.latDriver;
    nearbyOnlineDriversList[index].lngDriver = nearbyOnlineDriverInformation.lngDriver;

  }
}
