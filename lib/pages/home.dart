import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfcflipcard/controller/app_controller.dart';

class HomePage extends GetView<AppController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: NfcManager.instance.isAvailable(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          if (snapshot.hasData) {
            if (snapshot.data == false) {
              return const Center(child: Text('NFC is disable'));
            } else {
              return Flex(
                direction: Axis.vertical,
                children: [
                  Flexible(
                    child: Center(
                      child: Obx(() => Text(
                            controller.tagData.value,
                            style: Theme.of(context).textTheme.displayMedium,
                          )),
                    ),
                  ),
                  GridView(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    shrinkWrap: true,
                    children: [
                      // read
                      ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ))),
                        onPressed: () {
                          // read tag
                          readTag(controller: controller, context: context);
                        },
                        child: const Text('Read'),
                      ),

                      // write
                      ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ))),
                        onPressed: () {
                          // write tag
                          writeTag(context: context);
                        },
                        child: const Text('Write'),
                      )
                    ],
                  ),
                ],
              );
            }
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  readTag({required AppController controller, required BuildContext context}) {
    controller.tagData.value = '';

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      // show snack bar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 500),
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: const Text('Discovered'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // show ndef
      log('nDef = ${tag.data}');

      // get cached message
      final message = tag.data['ndef']['cachedMessage'];
      log('cachedMessage = $message');

      if (message != null) {
        // get payload
        Iterable<int>? payload = message['records'][0]['payload'];

        if ((payload != null) && (payload.isNotEmpty)) {
          // text
          if (payload.first == 0x02) {
            final payloadData = payload.skip(1).toList();
            final value = utf8.decode(payloadData);
            controller.tagData.value = value;
          } else {
            final payloadData = payload.toList();
            final value = utf8.decode(payloadData);
            controller.tagData.value = value;
          }
        } else {
          controller.tagData.value = 'no data';
        }
      } else {
        controller.tagData.value = 'no data';
      }

      NfcManager.instance.stopSession();
    });
  }

  writeTag({required BuildContext context}) {
    controller.tagData.value = '';
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      // show snack bar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 500),
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: const Text('Discovered'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      var ndef = Ndef.from(tag);
      // is ndef support
      if (ndef != null) {
        // is wriable
        if (ndef.isWritable) {
          final record = NdefRecord.createText('HelloWorld');
          // final record = NdefRecord.createUri(Uri.parse('https://google.com'));
          final message = NdefMessage([record]);
          ndef.write(message).then((value) {
            // show snack bar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 800),
                backgroundColor: Theme.of(context).colorScheme.primary,
                content: const Text('Write complete'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }).catchError((error) {
            // show snack bar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).colorScheme.error,
                content: const Text('Write error'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        } else {
          // show snack bar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content: const Text('Tag cannot write'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      NfcManager.instance.stopSession();
    });
  }
}
