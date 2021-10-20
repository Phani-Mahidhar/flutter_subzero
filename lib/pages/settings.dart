import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:subzero/constants.dart';

class SettingPage extends StatefulWidget {
  SettingPage(
      {Key? key,
      required this.title,
      required this.setTempPreset,
      required this.setHumidPreset,
      required this.initTempPreset,
      required this.initHumidPreset,
      required this.setTempRanges,
      required this.setHumidRanges,
      required this.toggleGpio,
      required this.gpioDisabled,
      required this.sensorHealthStatus})
      : super(key: key);
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final void Function(double) setTempPreset;
  final void Function(double) setHumidPreset;
  final void Function(double, double) setTempRanges;
  final void Function(double, double) setHumidRanges;
  final void Function(bool) toggleGpio;
  final double initTempPreset;
  final double initHumidPreset;
  final String title;
  final bool gpioDisabled;
  final String? sensorHealthStatus;
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  double tempMinValue = 0;
  double tempMaxValue = 100;
  double humidMinValue = 0;
  double humidMaxValue = 100;

  bool gpioState = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // developer.log("here");
    gpioState = !widget.gpioDisabled;

    _prefs.then((prefs) {
      developer.log("here");

      String s = prefs.getString("tempRanges") ?? "[0, 100]";
      List<dynamic> tempRanges = jsonDecode(s);
      setState(() {
        tempMinValue = tempRanges[0];
        tempMaxValue = tempRanges[1];
      });

      s = prefs.getString("humidRanges") ?? "[0, 100]";
      List<dynamic> humidRanges = jsonDecode(s);
      setState(() {
        humidMinValue = humidRanges[0];
        humidMaxValue = humidRanges[1];
      });
    });
  }

  void homePageOpen() {
    Navigator.pop(context);
  }

  TextEditingController tempController = TextEditingController();
  TextEditingController humidController = TextEditingController();
  TextEditingController tempMinController = TextEditingController();
  TextEditingController tempMaxController = TextEditingController();
  TextEditingController humidMinController = TextEditingController();
  TextEditingController humidMaxController = TextEditingController();
  toggleConnectButton() {}

  void powerOffDevice() {}

  void gpioToggle(bool val) {
    setState(() {
      gpioState = val;
    });
    widget.toggleGpio(val);
  }

  @override
  Widget build(BuildContext context) {
    tempController.text = widget.initTempPreset.toString();
    humidController.text = widget.initHumidPreset.toString();

    tempMinController.text = tempMinValue.toString();
    tempMaxController.text = tempMaxValue.toString();

    humidMinController.text = humidMinValue.toString();
    humidMaxController.text = humidMaxValue.toString();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: powerOffDevice,
          icon: const Icon(Icons.power_settings_new),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.home,
            ),
            onPressed: homePageOpen,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Enable GPIOs:",
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                  ),
                  Switch(value: gpioState, onChanged: gpioToggle)
                ],
              ),
            ),
            const SizedBox(child: Divider(height: 20)),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Sensor Presets:",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: TextFormField(
                      // initialValue: widget.initTempPreset.toString(),
                      controller: tempController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "Temperature preset",
                        suffixIcon: IconButton(
                          onPressed: () {
                            widget.setTempPreset(
                                double.parse(tempController.text.toString()));
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: TextFormField(
                      // initialValue: widget.initHumidPreset.toString(),
                      controller: humidController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "Humidity preset",
                        suffixIcon: IconButton(
                          onPressed: () {
                            widget.setHumidPreset(
                                double.parse(humidController.text.toString()));
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(child: Divider(height: 5)),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Column(
                verticalDirection: VerticalDirection.down,
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Sensor Ranges:",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 2, 5),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Temperature:",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          fit: FlexFit.tight,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: tempMinController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "min",
                              contentPadding: EdgeInsets.all(8),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        // const SizedBox(width: 10),
                        const Text(" to ",
                            style: TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 15)),
                        // const SizedBox(width: 10),
                        Flexible(
                          fit: FlexFit.tight,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: tempMaxController,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(10),
                              border: OutlineInputBorder(),
                              labelText: "max",
                              // hintText: "100 \u2103",
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            widget.setTempRanges(
                                double.parse(tempMinController.text.toString()),
                                double.parse(
                                    tempMaxController.text.toString()));
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 2, 5),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Humidity:",
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 16),
                        ),
                        const SizedBox(width: 37),
                        Flexible(
                          fit: FlexFit.tight,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: humidMinController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "min",
                              contentPadding: EdgeInsets.all(8),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        // const SizedBox(width: 10),
                        const Text(" to ",
                            style: TextStyle(
                                fontWeight: FontWeight.w400, fontSize: 15)),
                        // const SizedBox(width: 10),
                        Flexible(
                          fit: FlexFit.tight,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            controller: humidMaxController,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(10),
                              border: OutlineInputBorder(),
                              labelText: "max",
                              // hintText: "100 \u2103",
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            widget.setHumidRanges(
                                double.parse(
                                    humidMinController.text.toString()),
                                double.parse(
                                    humidMaxController.text.toString()));
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
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
                      "Sensor Health: ",
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    alignment: Alignment.center,
                    // color: Colors.grey.withOpacity(0.5),
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 80),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: ((widget.sensorHealthStatus ==
                                  HEALTH_STATUS_MESSAGES["OK"])
                              ? Colors.green
                              : Colors.orange)
                          .withOpacity(0.5),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Text(
                        widget.sensorHealthStatus ?? "HEALTHY",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
