import 'package:signalr_core/signalr_core.dart';

class DriverService {
  late HubConnection hubConnection;

  DriverService(String rideId) {
    hubConnection =
        HubConnectionBuilder()
            .withUrl('https://yourbackend.com/hubs/driver?rideId=$rideId')
            .build();
  }

  Future<void> startConnection(Function onDriverAssigned) async {
    hubConnection.on('DriverAssigned', (arguments) {
      onDriverAssigned();
    });

    await hubConnection.start();
  }

  Future<void> stopConnection() async {
    await hubConnection.stop();
  }
}
