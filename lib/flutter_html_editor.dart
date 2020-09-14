library flutter_html_editor;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'local_server.dart';

class FlutterHtmlEditor extends StatefulWidget {
  final String value;
  final double height;
  final BoxDecoration decoration;
  final String hint;
  final String lang;

  FlutterHtmlEditor(
      {Key key,
      this.value,
      this.height = 300,
      this.decoration,
      this.hint = '',
      this.lang = 'en-US'})
      : super(key: key);

  @override
  FlutterHtmlEditorState createState() => FlutterHtmlEditorState();
}

class FlutterHtmlEditorState extends State<FlutterHtmlEditor> {
  WebViewController _controller;
  String text = "";
  final Key _mapKey = UniqueKey();

  int port = 5321;
  LocalServer localServer;

  @override
  void initState() {
    if (!Platform.isAndroid) {
      initServer();
    }
    super.initState();
  }

  initServer() {
    localServer = LocalServer(port);
    localServer.start(handleRequest);
  }

  void handleRequest(HttpRequest request) {
    try {
      if (request.method == 'GET' &&
          request.uri.queryParameters['query'] == "getRawTeXHTML") {
      } else {}
    } catch (e) {
      print('Exception in handleRequest: $e');
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller = null;
    }
    if (!Platform.isAndroid) {
      localServer.close();
    }
    super.dispose();
  }

  _loadHtmlFromAssets() async {
    final filePath =
        'packages/flutter_html_editor/lib/summernote/summernote.html';
    _controller.loadUrl("http://localhost:$port/$filePath");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: widget.decoration ??
          BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            border: Border.all(color: Color(0xffececec), width: 1),
          ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: WebView(
              key: _mapKey,
              onWebResourceError: (e) {
                print("error ${e.description}");
              },
              onWebViewCreated: (webViewController) {
                _controller = webViewController;

                if (Platform.isAndroid) {
                  final filename =
                      'packages/flutter_html_editor/lib/summernote/summernote.html';
                  _controller.loadUrl(
                      "file:///android_asset/flutter_assets/" + filename);
                } else {
                  _loadHtmlFromAssets();
                }
              },
              javascriptMode: JavascriptMode.unrestricted,
              gestureNavigationEnabled: true,
              gestureRecognizers: [
                Factory(
                    () => VerticalDragGestureRecognizer()..onUpdate = (_) {}),
              ].toSet(),
              javascriptChannels: <JavascriptChannel>[
                getTextJavascriptChannel(context)
              ].toSet(),
              onPageFinished: (String url) {
                initEditor();
                setFullContainer();
                if (widget.value != null) {
                  setText(widget.value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  JavascriptChannel getTextJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'GetTextSummernote',
        onMessageReceived: (JavascriptMessage message) {
          String isi = message.message;
          if (isi.isEmpty ||
              isi == "<p></p>" ||
              isi == "<p><br></p>" ||
              isi == "<p><br/></p>") {
            isi = "";
          }
          setState(() {
            text = isi;
          });
        });
  }

  Future<String> getText() async {
    await _controller.evaluateJavascript(
        "GetTextSummernote.postMessage(document.getElementsByClassName('note-editable')[0].innerHTML);");
    return text;
  }

  setText(String v) async {
    String txtIsi = v
        .replaceAll("'", '\\"')
        .replaceAll('"', '\\"')
        .replaceAll("[", "\\[")
        .replaceAll("]", "\\]")
        .replaceAll("\n", "<br/>")
        .replaceAll("\n\n", "<br/>")
        .replaceAll("\r", " ")
        .replaceAll('\r\n', " ");
    String txt =
        "document.getElementsByClassName('note-editable')[0].innerHTML = '" +
            txtIsi +
            "';";
    _controller.evaluateJavascript(txt);
  }

  setFullContainer() {
    _controller.evaluateJavascript(
        '\$("#summernote").summernote("fullscreen.toggle");');
  }

  setFocus() {
    _controller.evaluateJavascript("\$('#summernote').summernote('focus');");
  }

  setEmpty() {
    _controller.evaluateJavascript("\$('#summernote').summernote('reset');");
  }

  setHint(String text) {
    String hint = '\$(".note-placeholder").html("$text");';
    _controller.evaluateJavascript(hint);
  }

  initEditor() {
    String initString =
        "\$('#summernote').summernote({placeholder: '${widget.hint}', tabsize: 2," +
            "toolbar: [" +
            "['style', ['style']]," +
            "['font', ['bold', 'underline', 'italic', 'clear']]," +
            "['color', ['color']]," +
            "['para', ['ul', 'ol', 'paragraph']]," +
            // "['insert', ['link', 'hr']]," +
            "['view', ['codeview']]," +
            "]," +
            "lang: '${widget.lang}'" +
            "});";
    print(initString);
    _controller.evaluateJavascript(initString);
  }
}
