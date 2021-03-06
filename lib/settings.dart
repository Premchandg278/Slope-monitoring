import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:async';

class _Message {
  int whom;
  String text;
  _Message(this.whom, this.text);
}

class NewSettings extends StatefulWidget {
  final BluetoothDevice server;
  const NewSettings({this.server});
  @override
  _NewSettings createState() => new _NewSettings();
}

class _NewSettings extends State<NewSettings> {
  var customNumber = TextEditingController();
  bool numberValidate = true;
  bool custom = false;
  bool tare = false;
  bool previous = false;
  bool cstart = false;
  bool cstop = false;
  bool towardValid = false;
  bool awayValid = false;
  var away = TextEditingController();
  var toward = TextEditingController();
  static final clientID = 0;
  BluetoothConnection connection;
  List<_Message> messages = [];
  String _messageBuffer = '';
  var awayPoint;
  var towardPoint;
  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting to ' + widget.server.name + '...')
              : isConnected
                  ? Text('Connected to ' + widget.server.name)
                  : Text('Connected to' + widget.server.name))),
      body: ListView(
        children: <Widget>[
          SizedBox(
            height: 10,
          ),
          cstart
              ? Text("Complete calibration first")
              : Card(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(children: [
                        Text(
                          "Away and Toward Point Setting",
                          style: TextStyle(fontSize: 22, color: Colors.blue),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(awayPoint == null
                                    ? "Refresh To get Away point"
                                    : awayPoint.toString()),
                                Text(towardPoint == null
                                    ? "Refresh To get Toward point"
                                    : towardPoint.toString()),
                              ],
                            ),
                            IconButton(
                                onPressed: () async {
                                  EasyLoading.show(status: "Please wait");
                                  _sendMessage("i");
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  _sendMessage("a");
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  _sendMessage("j");
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  _sendMessage("a");
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  EasyLoading.dismiss();
                                },
                                icon: Icon(Icons.refresh))
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black12),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 3, 4, 3),
                            child: TextField(
                              controller: away,
                              decoration: InputDecoration(
                                  errorText: awayValid == false
                                      ? "Value must be greater then 0 and less then 32000"
                                      : null,
                                  disabledBorder: InputBorder.none,
                                  border: InputBorder.none,
                                  hintText: "Enter Away point in mm",
                                  icon: Icon(Icons.engineering)),
                              onChanged: (val) {
                                setState(() {
                                  try {
                                    int x = int.parse(val);
                                    awayValid =
                                        x >= 0 && x <= 32000 ? true : false;
                                  } catch (e) {
                                    print(e.toString());
                                    awayValid = false;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 90 / 100,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black12),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 3, 4, 3),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              controller: toward,
                              decoration: InputDecoration(
                                  errorText: towardValid == false
                                      ? "Value must be less then 0 and greater then -32000"
                                      : null,
                                  disabledBorder: InputBorder.none,
                                  border: InputBorder.none,
                                  hintText: "Enter Toward point in mm",
                                  icon: Icon(Icons.location_city)),
                              onChanged: (value) {
                                setState(() {
                                  try {
                                    int x = int.parse(value);
                                    towardValid =
                                        x <= 0 && x >= -32000 ? true : false;
                                  } catch (e) {
                                    print(e.toString());
                                    towardValid = false;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: CupertinoButton(
                              color: Colors.green,
                              child: Text("Done"),
                              onPressed: () async {
                                if (isConnected) {
                                  EasyLoading.show(status: "Please wait..");
                                  if (awayValid) {
                                    _sendMessage("i");
                                    await Future.delayed(Duration(seconds: 3));
                                    _sendMessage("b");
                                    await Future.delayed(Duration(seconds: 3));
                                    print(" sending : " + away.text + "sent");
                                    _sendInt(away.text);
                                    setState(() {
                                      away.clear();
                                    });
                                  }
                                  if (towardValid) {
                                    await Future.delayed(Duration(seconds: 3));
                                    _sendMessage("j");
                                    await Future.delayed(Duration(seconds: 3));
                                    _sendMessage("b");
                                    await Future.delayed(Duration(seconds: 3));
                                    print(" sending : " + toward.text + "sent");
                                    _sendInt(toward.text);
                                    setState(() {
                                      toward.clear();
                                    });
                                  }
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  EasyLoading.show(status: "Please wait");
                                  _sendMessage("i");
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  _sendMessage("a");
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  _sendMessage("j");
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  _sendMessage("a");
                                  await Future.delayed(
                                      const Duration(seconds: 3), () {});
                                  EasyLoading.dismiss();
                                } else {
                                  EasyLoading.showError("Device not connected");
                                }
                              }),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ])),
                ),
          SizedBox(
            height: 10,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                Text(
                  "Calibration",
                  style: TextStyle(fontSize: 22, color: Colors.blue),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CupertinoButton(
                      color: cstart ? Colors.grey : Colors.green,
                      child: Text("Start"),
                      onPressed: () {
                        if (cstart) {
                          EasyLoading.showError("Calibration already started");
                        } else {
                          setState(() {
                            cstart = true;
                          });
                          _sendMessage("h");
                        }
                      },
                    ),
                    CupertinoButton(
                      color: cstart ? Colors.green : Colors.grey,
                      child: Text("Stop"),
                      onPressed: () {
                        if (cstart) {
                          _sendMessage("t");

                          setState(() {
                            cstart = false;
                          });
                        } else {
                          EasyLoading.showError("First Start callibration");
                        }
                      },
                    ),
                  ],
                )
              ]),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          cstart
              ? Text("Complete calibration first")
              : Card(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Initial Value Setup ",
                        style: TextStyle(fontSize: 22, color: Colors.blue),
                      ),
                      Row(
                        children: [
                          Text("Custom: "),
                          Checkbox(
                              value: custom,
                              onChanged: (val) => setState(() {
                                    custom = val;
                                    tare = false;
                                    previous = false;
                                  })),
                          Text("Tare :"),
                          Checkbox(
                              value: tare,
                              onChanged: (val) => setState(() {
                                    tare = val;
                                    previous = false;
                                    custom = false;
                                  })),
                          Text("Previous: "),
                          Checkbox(
                              value: previous,
                              onChanged: (val) => setState(() {
                                    previous = val;
                                    custom = false;
                                    tare = false;
                                  })),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                      custom
                          ? Container(
                              width:
                                  MediaQuery.of(context).size.width * 90 / 100,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.black12),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 3, 4, 3),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  controller: customNumber,
                                  decoration: InputDecoration(
                                      errorText: numberValidate == false
                                          ? "Value must be an integer"
                                          : null,
                                      disabledBorder: InputBorder.none,
                                      border: InputBorder.none,
                                      hintText: "Enter initial value in mm",
                                      icon: Icon(Icons.dashboard_customize)),
                                  onChanged: (value) {
                                    setState(() {
                                      try {
                                        double x = double.parse(value);
                                        numberValidate = true;
                                        print(x);
                                      } catch (e) {
                                        print(e.toString());
                                        numberValidate = false;
                                      }
                                    });
                                  },
                                ),
                              ),
                            )
                          : Container(),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: CupertinoButton(
                          color: Colors.green,
                          child: Text("Done"),
                          onPressed: () async {
                            if (isConnected) {
                              EasyLoading.show(status: "Please wait...");
                              _sendMessage("e");
                              await Future.delayed(
                                  const Duration(seconds: 2), () {});
                              tare ? _sendMessage("a") : print("Don't send a");
                              previous
                                  ? _sendMessage("b")
                                  : print("Don't send b");
                              custom
                                  ? _sendMessage("c")
                                  : print("Don't send c");
                              await Future.delayed(
                                  const Duration(seconds: 2), () {});
                              custom
                                  ? _sendMessage(customNumber.text)
                                  : print("Don't send custom number");
                              EasyLoading.dismiss();
                            } else {
                              EasyLoading.showError("Device not connected");
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                )
        ],
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        var str = backspacesCounter > 0
            ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
            : _messageBuffer + dataString.substring(0, index);
        print("received data: " + str + " done");
        if (str.contains("Away point is:")) {
          setState(() {
            awayPoint = str;
          });
        } else if (str.contains("Toward point is:")) {
          setState(() {
            towardPoint = str;
          });
        }
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();
    if (text.length > 0) {
      try {
        connection.output.add(ascii.encode(text));
        await connection.output.allSent;
        setState(() {
          messages.add(_Message(clientID, text));
        });
      } catch (e) {
        print(e.toString());
        setState(() {});
      }
    }
  }

  void _sendInt(String text) async {
    print(text);
    textEditingController.clear();
    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text));
        await connection.output.allSent;
        setState(() {
          messages.add(_Message(clientID, text));
        });
      } catch (e) {
        print(e.toString());
        setState(() {});
      }
    }
  }
}
