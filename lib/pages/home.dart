import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import './settings.dart';

import 'dart:developer' as developer;
import '../custom/display.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  final String bleDeviceName = "SubZero-D2";
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  bool connectedState = false;
  double humidityValue = 0;
  double tempValue = 0;
  String relayState = "DISABLED";
  Color relayColor = Colors.grey;
  double tempPreset = 0.0;
  double humidityPreset = 0.0;
  bool systemOn = true;
  double tempMinValue = 0;
  double tempMaxValue = 100;
  double humidMinValue = 0;
  double humidMaxValue = 100;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  List<bool> gpioStates = [false, false, false, false];
  bool gpioDisabled = true;
  String? sensorHealth = HEALTH_STATUS_MESSAGES["OK"];
  var rxCharacteristic;

  @override
  void initState() {
    super.initState();
    _prefs.then((prefs) {
      String s = prefs.getString("tempRanges") ?? "[0, 100]";
      List<dynamic> tempRanges = jsonDecode(s);
      tempMinValue = tempRanges[0];
      tempMaxValue = tempRanges[1];
      prefs.setString("tempRanges", s);

      s = prefs.getString("humidRanges") ?? "[0, 100]";
      List<dynamic> humidRanges = jsonDecode(s);
      humidMinValue = humidRanges[0];
      humidMaxValue = humidRanges[1];
      prefs.setString("humidRanges", s);
    });
  }

  void settingsOpen() {
    refreshDevice();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingPage(
          title: widget.title,
          setTempPreset: setTemperaturePreset,
          setHumidPreset: setHumidityPreset,
          setTempRanges: setTempRanges,
          setHumidRanges: setHumidRanges,
          initTempPreset: tempPreset,
          initHumidPreset: humidityPreset,
          toggleGpio: toggleGpio,
          gpioDisabled: gpioDisabled,
          sensorHealthStatus: sensorHealth,
        ),
      ),
    );
    // Future.delayed(const Duration(milliseconds: 100), () {

    // });
  }

  void disconnectDevice() async {
    FlutterBlue flutterBlue = FlutterBlue.instance;
    List<BluetoothDevice> listDevices = await flutterBlue.connectedDevices;
    for (final device in listDevices) {
      if (device.name == widget.bleDeviceName) {
        device.disconnect();
        setState(() {
          connectedState = false;
          rxCharacteristic = null;
        });
        return;
      }
    }
    setState(() {
      connectedState = false;
      rxCharacteristic = null;
    });
  }

  void connectDevice() {
    developer.log("Connecting....", name: "debug.out");
    FlutterBlue flutterBlue = FlutterBlue.instance;
    flutterBlue.connectedDevices.then((listDevices) {
      for (final device in listDevices) {
        developer.log(device.toString(), name: "debug.out");
        if (device.name == widget.bleDeviceName) {
          setState(() {
            connectedState = true;
          });
          return;
        }
      }
      setState(() {
        connectedState = false;
      });
    });
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
    flutterBlue.scanResults.listen(
      (results) {
        developer.log("Scanning....", name: "debug.out");

        for (ScanResult r in results) {
          developer.log(r.toString(), name: "debug.out");

          if (r.device.name == widget.bleDeviceName) {
            r.device.connect().then((value) {
              flutterBlue.connectedDevices.then((listDevices) {
                for (final device in listDevices) {
                  developer.log(device.toString(), name: "debug.out");
                  if (device.name == widget.bleDeviceName) {
                    setState(() {
                      connectedState = true;
                    });
                    device.discoverServices().then((services) {
                      for (var service in services) {
                        for (var characteristic in service.characteristics) {
                          // developer.log(characteristic.uuid.toString(),
                          //     name: "debug.out");
                          if (characteristic.uuid.toString() ==
                              "6e400003-b5a3-f393-e0a9-e50e24dcca9e") {
                            characteristic.setNotifyValue(true);
                            characteristic.value.listen((rawData) {
                              // developer.log(rawData.toString(),
                              //     name: "debug.out");
                              List<String> data =
                                  String.fromCharCodes(rawData).split("_");
                              // List<String> data = rawData.toString().split("_");
                              developer.log(data.toString(), name: "debug.out");
                              if (rawData.isNotEmpty) {
                                if (data[0] == "TV") {
                                  setState(() {
                                    tempValue = double.parse(data[1]);
                                  });
                                } else if (data[0] == "HV") {
                                  setState(() {
                                    humidityValue = double.parse(data[1]);
                                  });
                                } else if (data[0] == "RLY") {
                                  if (data[1].trim() == "ON") {
                                    setState(() {
                                      relayState = "ENABLED";
                                      relayColor = Colors.lightGreen;
                                    });
                                  } else {
                                    setState(() {
                                      relayState = "DISABLED";
                                      relayColor = Colors.grey;
                                    });
                                  }
                                } else if (data[0].trim() == "SYS") {
                                  // developer.log("received a sys command");
                                  // developer.log(data[1]);
                                  // developer.log(data[2]);

                                  if (data[1].trim() == "OFF" &&
                                      data[2].trim() == "OK") {
                                    setState(() {
                                      systemOn = false;
                                    });
                                  }
                                  if (data[1].trim() == "ON" &&
                                      data[2].trim() == "OK") {
                                    setState(() {
                                      systemOn = true;
                                    });
                                  }
                                } else if (data[0].trim() == "TP") {
                                  setState(() {
                                    tempPreset = double.parse(data[1]);
                                  });
                                } else if (data[0].trim() == "HP") {
                                  setState(() {
                                    humidityPreset = double.parse(data[1]);
                                  });
                                } else if (data[0].contains("GP")) {
                                  developer.log(data.toString());
                                  bool state =
                                      data[1].trim() == "ON" ? true : false;
                                  if (data[0] == "GP1") {
                                    setState(() {
                                      gpioStates[0] = state;
                                    });
                                  } else if (data[0] == "GP2") {
                                    setState(() {
                                      gpioStates[1] = state;
                                    });
                                  } else if (data[0] == "GP3") {
                                    setState(() {
                                      gpioStates[2] = state;
                                    });
                                  } else if (data[0] == "GP4") {
                                    setState(() {
                                      gpioStates[3] = state;
                                    });
                                  }
                                } else if (data[0].trim() == "SN") {
                                  developer.log(data[1], name: "sensor");
                                  sensorHealth =
                                      HEALTH_STATUS_MESSAGES[data[1].trim()];
                                  developer.log(sensorHealth ?? "HEALTHY",
                                      name: "sensor");

                                  // if (data[2]) {

                                  // }
                                }
                              }
                            });
                          } else if (characteristic.uuid.toString() ==
                              "6e400002-b5a3-f393-e0a9-e50e24dcca9e") {
                            rxCharacteristic = characteristic;
                            refreshDevice();
                          }
                        }
                      }
                    });
                    return;
                  }
                }
                setState(() {
                  connectedState = false;
                });
              });
            });
            // flutterBlue.stopScan();
          }
        }
      },
    );
    // });
  }

  void setTemperaturePreset(double preset) {
    developer.log(preset.toString());
    if (connectedState && rxCharacteristic != null) {
      String presetString = "PRST_TEMP_$preset";
      developer.log(presetString);
      rxCharacteristic.write(presetString.codeUnits);
    }
  }

  void setHumidityPreset(double preset) {
    developer.log(systemOn.toString());
    if (connectedState && rxCharacteristic != null) {
      String presetString = "PRST_HUMD_$preset";
      developer.log(presetString);
      rxCharacteristic.write(presetString.codeUnits);
    }
  }

  void refreshDevice() {
    if (connectedState && (rxCharacteristic != null)) {
      String presetString = "ACK";
      rxCharacteristic.write(presetString.codeUnits);
    }
  }

  void powerToggleDevice() {
    if (connectedState && (rxCharacteristic != null)) {
      if (systemOn) {
        String presetString = "SYS_OFF";
        rxCharacteristic.write(presetString.codeUnits);
      } else {
        String presetString = "SYS_ON";
        rxCharacteristic.write(presetString.codeUnits);
      }
    }
  }

  void gpioClick(int gpio) {
    if (connectedState && (rxCharacteristic != null)) {
      String gpCmd = "GP${gpio}_${gpioStates[gpio - 1] ? 'OFF' : 'ON'}";
      // gpioStates[gpio - 1]=
      developer.log(gpCmd);
      rxCharacteristic.write(gpCmd.codeUnits);
    }
  }

  void setTempRanges(double minValue, double maxValue) {
    String tempRanges = "[$minValue, $maxValue]";
    developer.log(tempRanges);
    _prefs.then((prefs) {
      prefs.setString("tempRanges", tempRanges);
    });
    setState(() {
      tempMinValue = minValue;
      tempMaxValue = maxValue;
    });
  }

  void setHumidRanges(double minValue, double maxValue) {
    String humidRanges = "[$minValue, $maxValue]";
    _prefs.then((prefs) {
      prefs.setString("humidRanges", humidRanges);
    });
    setState(() {
      humidMinValue = minValue;
      humidMaxValue = maxValue;
    });
  }

  void toggleGpio(bool val) {
    setState(() {
      gpioDisabled = !val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: Container(
          // margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          margin: const EdgeInsets.fromLTRB(6, 8, 0, 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            image: DecorationImage(
              image: AssetImage("assets/app-icon.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: settingsOpen,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                connectedState
                    ? Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          child: const Text(
                            "DISCONNECT",
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: disconnectDevice,
                        ))
                    : Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          child: const Text(
                            "CONNECT",
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: connectDevice,
                        ),
                      ),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: !connectedState ? null : powerToggleDevice,
                    style: ElevatedButton.styleFrom(
                      primary:
                          systemOn ? Colors.red.shade900 : Colors.red.shade600,
                      shape: const CircleBorder(),
                      elevation: systemOn ? 3.0 : 10.0,
                    ),
                    child: const Icon(Icons.power_settings_new),
                  ),
                )
              ],
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Temperature Measurement:",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  Display(
                      minValue: tempMinValue,
                      maxValue: tempMaxValue,
                      currentValue: tempValue,
                      units: "\u2103"),
                ],
              ),
            ),
            const SizedBox(child: Divider(height: 20)),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Humidity Measurement: ",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  Display(
                      minValue: humidMinValue,
                      maxValue: humidMaxValue,
                      currentValue: humidityValue,
                      units: "%"),
                ],
              ),
            ),
            const SizedBox(child: Divider(height: 20)),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Relay Status: ",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    alignment: Alignment.center,
                    // color: Colors.grey.withOpacity(0.5),
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 80),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: relayColor.withOpacity(0.4),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Text(
                        relayState,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ButtonBar(alignment: MainAxisAlignment.spaceBetween, children: [
                  ElevatedButton(
                    onPressed: gpioDisabled
                        ? null
                        : () {
                            gpioClick(1);
                          },
                    child: const Text("1"),
                    style: ElevatedButton.styleFrom(
                        primary: gpioStates[0] ? Colors.green : Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: gpioDisabled
                        ? null
                        : () {
                            gpioClick(2);
                          },
                    child: const Text("2"),
                    style: ElevatedButton.styleFrom(
                        primary: gpioStates[1] ? Colors.green : Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: gpioDisabled
                        ? null
                        : () {
                            gpioClick(3);
                          },
                    child: const Text("3"),
                    style: ElevatedButton.styleFrom(
                        primary: gpioStates[2] ? Colors.green : Colors.red),
                  ),
                  ElevatedButton(
                    onPressed: gpioDisabled
                        ? null
                        : () {
                            gpioClick(4);
                          },
                    child: const Text("4"),
                    style: ElevatedButton.styleFrom(
                        primary: gpioStates[3] ? Colors.green : Colors.red),
                  )
                ])
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
