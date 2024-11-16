import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import "package:flex_color_picker/flex_color_picker.dart";
import 'package:http/http.dart' as http;
import "dart:convert";

Binarikea bk = Binarikea(address: "binarikea.local");

void main() async {
  print("Starting app");
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      ColorScheme lightColorScheme;
      ColorScheme darkColorScheme;

      if (lightDynamic != null && darkDynamic != null) {
        // On Android S+ devices, use the provided dynamic color scheme.
        // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
        lightColorScheme = lightDynamic.harmonized();
        darkColorScheme = darkDynamic.harmonized();
      } else {
        // Otherwise, use fallback schemes.
        lightColorScheme = ColorScheme.fromSeed(
          seedColor: Colors.blue[600]!,
        );
        darkColorScheme = ColorScheme.fromSeed(
          seedColor: Colors.blue[600]!,
          brightness: Brightness.dark,
        );
      }

      return MaterialApp(
        theme: ThemeData(
          colorScheme: lightColorScheme,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Color dialogPickerColor = Colors.red;
  Color fgColor = Color.fromRGBO(0, 187, 255, 1);
  Color bgColor = Color.fromRGBO(0, 0, 0, 1);
  int timerDuration = 30 * 60;
  double _brightness = 50;
  int brightness = 50;
  bool connected = false;
  bool tried = false;
  @override
  Widget build(BuildContext context) {
    if (!connected && !tried) {
      print('Connecting to binarikea...');
      tried = true;
      bk.connect().then((value) {
        setState(() {
          connected = value;
        });
      });
      return Scaffold(
        appBar: AppBar(title: const Text('Binarikea Companion')),
        body: Center(
            child: Column(children: [
          Text('Connecting to hardware...'),
          CircularProgressIndicator()
        ])),
      );
    } else if (!connected && tried) {
      return Scaffold(
        appBar: AppBar(title: const Text('Binarikea Companion')),
        body: Center(child: Text('Could not connect to hardware')),
      );
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Binarikea Companion')),
        body: SingleChildScrollView(
            child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('Foreground Color: ', style: TextStyle(fontSize: 20)),
                  Expanded(child: Container()),
                  FilledButton.tonal(
                    child: Text('Pick Color'),
                    onPressed: () async {
                      dialogPickerColor = fgColor;
                      await colorPickerDialog();
                      fgColor = dialogPickerColor;
                      setState(() {});
                      await bk.setFgColor(fgColor);
                    },
                  ),
                  const Padding(padding: EdgeInsets.all(5)),
                  Container(
                    width: 40,
                    height: 40,
                    color: fgColor,
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('Background Color: ', style: TextStyle(fontSize: 20)),
                  Expanded(child: Container()),
                  FilledButton.tonal(
                    child: Text('Pick Color'),
                    onPressed: () async {
                      dialogPickerColor = bgColor;
                      await colorPickerDialog();
                      bgColor = dialogPickerColor;
                      setState(() {});
                      await bk.setBgColor(bgColor);
                    },
                  ),
                  const Padding(padding: EdgeInsets.all(5)),
                  Container(
                    width: 40,
                    height: 40,
                    color: bgColor,
                  ),
                ],
              ),
            ),
            Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text("Brightness: ", style: TextStyle(fontSize: 20)),
                      Slider(
                        value: _brightness.toDouble(),
                        max: 150,
                        //min: 6,
                        divisions: 25,
                        label: _brightness.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _brightness = value;
                            brightness = value.round();
                          });
                        },
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          await bk.brightness(brightness);
                        },
                        child: Text('Apply'),
                      ),
                    ])),
            Divider(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20)
                  .copyWith(bottom: 0),
              child: Text('Timer',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Row(
                children: <Widget>[
                  Text(
                      'Timer Duration: ${printDuration(Duration(seconds: timerDuration))}',
                      style: TextStyle(fontSize: 20)),
                  Expanded(child: Container()),
                  FilledButton.tonal(
                      child: Text('Pick Duration'),
                      onPressed: () async {
                        timerDuration = (await showDialog<Duration>(
                              context: context,
                              builder: (BuildContext context) {
                                TextEditingController seconds =
                                    TextEditingController(
                                        text: (Duration(seconds: timerDuration)
                                                    .inSeconds %
                                                60)
                                            .toString());
                                TextEditingController minutes =
                                    TextEditingController(
                                        text: Duration(seconds: timerDuration)
                                            .inMinutes
                                            .toString());
                                return AlertDialog(
                                  title: const Text('Timer Duration'),
                                  content: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller: minutes,
                                          decoration: const InputDecoration(
                                              labelText: 'Minutes',
                                              border: OutlineInputBorder()),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          controller: seconds,
                                          decoration: const InputDecoration(
                                              labelText: 'Seconds',
                                              border: OutlineInputBorder()),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      child: const Text('Dismiss'),
                                      onPressed: () {
                                        Navigator.of(context).pop(
                                            Duration(seconds: timerDuration));
                                      },
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      child: const Text('Set'),
                                      onPressed: () {
                                        Navigator.of(context).pop(Duration(
                                            minutes: int.parse(minutes.text),
                                            seconds: int.parse(seconds.text)));
                                      },
                                    ),
                                  ],
                                );
                              },
                            ))
                                ?.inSeconds ??
                            0;
                        setState(() {});
                        await bk.timerDuration(timerDuration);
                      }),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: FilledButton(
                onPressed: () async {
                  await bk.stopTimer();
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Stop timer",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white)),
              ),
            ),
          ],
        )));
  }

  Future<bool> colorPickerDialog() async {
    return ColorPicker(
      // Use the dialogPickerColor as start and active color.
      color: dialogPickerColor,
      // Update the dialogPickerColor using the callback.
      onColorChanged: (Color color) =>
          setState(() => dialogPickerColor = color),
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subheading: Text(
        'Select color shade',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      wheelSubheading: Text(
        'Selected color and its shades',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
    ).showPickerDialog(
      context,
      constraints:
          const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
    );
  }
}

String printDuration(Duration duration) {
  String negativeSign = duration.isNegative ? '-' : '';
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

class Binarikea {
  String address;
  Binarikea({required this.address});
  Future<bool> connect() async {
    try {
      http.Response response = await http.get(Uri.parse('http://$address'));
      if (response.statusCode == 200) {
        print('Connected to $address');
        return true;
      } else {
        print('Could not connect to $address');
        return false;
      }
    } catch (e) {
      print("Error connecting to $address");
      print(e.toString());
      return false;
    }
  }

  Future<bool> stopTimer() async {
    http.Response response = await sendRequest("/stopTimer");
    if (response.statusCode == 200) {
      print('stopped timer');
      return true;
    } else {
      print('Could not stop timer');
      return false;
    }
  }

  Future<bool> timerDuration(int duration) async {
    http.Response response =
        await sendRequest("/timerDuration?time=${duration}");
    if (response.statusCode == 200) {
      print('set timer duration');
      return true;
    } else {
      print('Could not set timer duration');
      return false;
    }
  }

  Future<bool> setFgColor(Color color) async {
    http.Response response = await sendRequest(
        "/fgColor?red=${color.red}&green=${color.green}&blue=${color.blue}");
    if (response.statusCode == 200) {
      print('Set fg color');
      return true;
    } else {
      print('Could not set fg color');
      return false;
    }
  }

  Future<bool> setBgColor(Color color) async {
    http.Response response = await sendRequest(
        "/bgColor?red=${color.red}&green=${color.green}&blue=${color.blue}");
    var body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      print('Set bg color');
      return true;
    } else {
      print('Could not set bg color');
      return false;
    }
  }

  Future<bool> brightness(int brightness) async {
    http.Response response =
        await sendRequest("/brightness?brightness=$brightness");
    if (response.statusCode == 200) {
      print('set brightness');
      return true;
    } else {
      print('Could not set brightness');
      return false;
    }
  }

  Future<http.Response> sendRequest(String url) {
    return http.get(Uri.parse('http://$address$url'));
  }
}
