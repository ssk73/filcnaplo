import 'dart:async';

import 'package:filcnaplo/Dialog/ChooseLessonDialog.dart';
import 'package:filcnaplo/Helpers/RequestHelper.dart';
import 'package:filcnaplo/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';

import 'package:filcnaplo/Datas/Homework.dart';
import 'package:filcnaplo/Datas/User.dart';
import 'package:filcnaplo/Dialog/TimeSelectDialog.dart';
import 'package:filcnaplo/GlobalDrawer.dart';
import 'package:filcnaplo/Helpers/HomeworkHelper.dart';
import 'package:filcnaplo/Utils/StringFormatter.dart';
import 'package:filcnaplo/globals.dart' as globals;

void main() {
  runApp(MaterialApp(home: HomeworkScreen()));
}

class HomeworkScreen extends StatefulWidget {
  @override
  HomeworkScreenState createState() => HomeworkScreenState();
}

class HomeworkScreenState extends State<HomeworkScreen> {
  List<User> users;

  bool hasLoaded = true;
  bool hasOfflineLoaded = false;

  List<Homework> homeworksNew = List();
  List<Homework> selectedHomework = List();

  @override
  void initState() {
    super.initState();
    _onRefreshOffline();
    _onRefresh(showErrors: false);
  }

  void refHomework() {
    setState(() {
      selectedHomework.clear();
    });

    for (Homework n in homeworksNew) {
      if (n.owner.id == globals.selectedUser.id) {
        setState(() {
          selectedHomework.add(n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    globals.context = context;
    return WillPopScope(
        onWillPop: () {
          globals.screen = 0;
          Navigator.pushReplacementNamed(context, "/main");
        },
        child: Scaffold(
            drawer: GDrawer(),
            appBar: AppBar(
              title: Text(capitalize(I18n.of(context).homeworkTitle)),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () {
                    timeDialog().then((b) {
                      _onRefreshOffline();
                      refHomework();
                      _onRefresh();
                      refHomework();
                    });
                  },
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _openChooser,
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
              tooltip: "Házi hozzáadása",//TODO: I18n
            ),
            body: Container(
                child: hasOfflineLoaded
                    ? Column(children: <Widget>[
                        !hasLoaded
                            ? Container(
                                child: LinearProgressIndicator(
                                  value: null,
                                ),
                                height: 3,
                              )
                            : Container(
                                height: 3,
                              ),
                        Expanded(
                            child: RefreshIndicator(
                                child: ListView.builder(
                                  itemBuilder: _itemBuilder,
                                  itemCount: selectedHomework.length,
                                ),
                                onRefresh: _onRefresh)),
                      ])
                    : Center(child: CircularProgressIndicator()))));
  }

  Future<bool> _openChooser() {
    return showDialog(
      barrierDismissible: true,
      context: context,
      builder: (BuildContext context) {
        return ChooseLessonDialog();
      }
    );
  }

  Future<bool> timeDialog() {
    return showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            return TimeSelectDialog();
          },
        ) ??
        false;
  }

  Future<Null> homeworksDialog(Homework homework) async {
    if (homework.deletedBy > 0) {
      homework.text = "<strike>${homework.text}</strike>";
    }

    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(homework.subject + " " + I18n.of(context).homework),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                homework.deadline != null
                    ? Text(capitalize(I18n.of(context).homeworkDeadline) +
                        ": " +
                        homework.deadline)
                    : Container(),
                Text(capitalize(I18n.of(context).homeworkSubject) +
                    ": " +
                    homework.subject),
                Text(capitalize(I18n.of(context).homeworkUploadUser) +
                    ": " +
                    homework.uploader),
                Text(capitalize(I18n.of(context).homeworkUploadTime) +
                    ": " +
                    homework.uploadDate
                        .substring(0, 11)
                        .replaceAll("-", '. ')
                        .replaceAll("T", ". ")),
                Divider(
                  height: 4.0,
                ),
                Container(
                  padding: EdgeInsets.only(top: 10),
                ),
                Html(data: HtmlUnescape().convert(homework.text)),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Icon(Icons.delete),
              onPressed: () {
                RequestHelper()
                    .deleteHomework(homework.id, globals.selectedUser);
              },
            ),
            FlatButton(
              child: Text(I18n.of(context).dialogOk.toUpperCase()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Null> _onRefresh({bool showErrors = true}) async {
    setState(() {
      hasLoaded = false;
    });
    Completer<Null> completer = Completer<Null>();
    List<Homework> homeworksNew = await HomeworkHelper().getHomeworks(
        globals.timeData[globals.selectedTimeForHomework], showErrors);
    if (homeworksNew.length > homeworksNew.length) homeworksNew = homeworksNew;
    homeworksNew
        .sort((Homework a, Homework b) => b.uploadDate.compareTo(a.uploadDate));
    if (mounted)
      setState(() {
        refHomework();
        hasLoaded = true;
        hasOfflineLoaded = true;
        completer.complete();
      });
    return completer.future;
  }

  Future<Null> _onRefreshOffline() async {
    setState(() {
      hasOfflineLoaded = false;
    });
    Completer<Null> completer = Completer<Null>();
    homeworksNew = await HomeworkHelper()
        .getHomeworksOffline(globals.timeData[globals.selectedTimeForHomework]);
    homeworksNew
        .sort((Homework a, Homework b) => b.uploadDate.compareTo(a.uploadDate));
    if (mounted)
      setState(() {
        refHomework();
        hasOfflineLoaded = true;
        completer.complete();
      });
    return completer.future;
  }

  Widget _itemBuilder(BuildContext context, int index) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            selectedHomework[index].uploadDate.substring(0, 10) +
                " " +
                dateToWeekDay(
                    DateTime.parse(selectedHomework[index].uploadDate),
                    context) +
                (selectedHomework[index].subject == null
                    ? ""
                    : (" - " + selectedHomework[index].subject)),
            style: TextStyle(fontSize: 20.0),
          ),
          subtitle: Html(
              data: HtmlUnescape().convert(selectedHomework[index].text)),
          isThreeLine: true,
          onTap: () {
            homeworksDialog(selectedHomework[index]);
          },
        ),
        Divider(
          height: 5.0,
        ),
      ],
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    selectedHomework.clear();
    super.dispose();
  }
}
