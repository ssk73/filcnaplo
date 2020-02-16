//Contributed by RedyAu

import 'package:flutter/material.dart';
import 'package:filcnaplo/globals.dart' as globals;
import '../Datas/Lesson.dart';
import '../Utils/StringFormatter.dart';
import '../generated/i18n.dart';

class FilcNowCard extends StatefulWidget {
  List<Lesson> lessons;
  bool isLessonsTomorrow;
  BuildContext context;

  FilcNowCard(
      List<Lesson> lessons, bool isLessonsTomorrow, BuildContext context) {
    this.lessons = lessons;
    this.isLessonsTomorrow = isLessonsTomorrow;
    this.context = context;
  }

  @override
  _FilcNowCardState createState() => _FilcNowCardState();
}

class _FilcNowCardState extends State<FilcNowCard> {
  DateTime now;

  Lesson previousLesson;
  Lesson thisLesson;
  Lesson nextLesson;

  int prevBreakLength;
  int thisBreakLength;
  int minutesUntilNext;
  int minutesLeftOfThis;

  int filcNowState;

  void _filcNowBackend(
      DateTime now, List<Lesson> lessons, bool isLessonsTomorrow) {
    previousLesson = lessons.lastWhere(
        (Lesson lesson) => (lesson.end.isBefore(now)),
        orElse: () => null);
    thisLesson = lessons.lastWhere(
        (Lesson lesson) =>
            (lesson.start.isBefore(now) && lesson.end.isAfter(now)),
        orElse: () => null);
    nextLesson = lessons.firstWhere(
        (Lesson lesson) => (lesson.start.isAfter(now)),
        orElse: () => null);

    //States: Before first / During lesson / During break / After last
    //              0             1               2             3
    if (lessons.first.start.isAfter(now))
      filcNowState = 0;
    else if (thisLesson != null)
      filcNowState = 1;
    /*else if (isLessonsTomorrow)
      filcNowState = 3;*/
    else if (previousLesson.end.isBefore(now) && nextLesson.start.isAfter(now))
      filcNowState = 2;

      print("############ " + filcNowState.toString());

    if (filcNowState == 1) {
      //During a lesson, calculate previous and next break length
      prevBreakLength =
          thisLesson.start.difference(previousLesson.end).inMinutes;
      thisBreakLength = nextLesson.start.difference(thisLesson.end).inMinutes;
      minutesLeftOfThis = thisLesson.end.difference(now).inMinutes;
      minutesUntilNext = nextLesson.start.difference(now).inMinutes;
    } else if (filcNowState == 2) {
      //During a break, calculate its length.
      prevBreakLength = 0;
      thisBreakLength =
          nextLesson.start.difference(previousLesson.end).inMinutes;
      minutesUntilNext = nextLesson.start.difference(now).inMinutes;
    } else {
      //If before or after the school day, don't calculate breaks.
      prevBreakLength = 0;
      thisBreakLength = 0;
      minutesUntilNext = nextLesson.start.difference(now).inMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    now = new DateTime.now();
    _filcNowBackend(now, widget.lessons, widget.isLessonsTomorrow);
    return Container(
      padding: EdgeInsets.all(5),
      child: new Column(
        children: <Widget>[
          (filcNowState > 0)
              ? LessonTile(
                  context,
                  false,
                  I18n.of(context).filcNowPrevious,
                  "",
                  previousLesson.count.toString(),
                  previousLesson.subject,
                  previousLesson.isMissed ? I18n.of(context).substitutionMissed : previousLesson.teacher,
                  (previousLesson.isSubstitution
                      ? 1
                      : previousLesson.isMissed ? 2 : 0),
                  (previousLesson.homework != null) ? true : false,
                  getLessonRangeText(previousLesson),
                  previousLesson.room)
              : Container(),
          (filcNowState == 1) //Only show this lesson card during a lesson
              ? LessonTile(
                  context,
                  true,
                  I18n.of(context).filcNowNow((minutesLeftOfThis + 1).toString()),
                  (prevBreakLength.toString() + " " + I18n.of(context).timeMinute),
                  thisLesson.count.toString(),
                  thisLesson.subject,
                  thisLesson.isMissed ? I18n.of(context).substitutionMissed : thisLesson.teacher,
                  (thisLesson.isSubstitution ? 1 : thisLesson.isMissed ? 2 : 0),
                  (thisLesson.homework != null) ? true : false,
                  getLessonRangeText(thisLesson),
                  thisLesson.room)
              : Container(),
          LessonTile(
              context,
              false,
              I18n.of(context).filcNowNext((minutesUntilNext + 1).toString()),
              (filcNowState == 0) ? "" : (thisBreakLength.toString() + " " + I18n.of(context).timeMinute),
              nextLesson.count.toString(),
              nextLesson.subject,
              nextLesson.isMissed ? I18n.of(context).substitutionMissed : nextLesson.teacher,
              (nextLesson.isSubstitution ? 1 : nextLesson.isMissed ? 2 : 0),
              (nextLesson.homework != null) ? true : false,
              getLessonRangeText(nextLesson),
              nextLesson.room),
        ],
      ),
    );
  }
}

Widget LessonTile(
  //Builder of a single lesson in the 3 or 2 part list
  BuildContext context,
  bool isThis,
  String tabText,
  String breakLength,
  String lessonNumber,
  String lessonSubject,
  String lessonSubtitle,
  int lessonState, //0: normally held, 1: substituted, 2: not held
  bool hasHomework,
  String startTime,
  String room,
) {
  return Container(
    child: new Column(
      children: <Widget>[
        new SizedBox(height: 3),
        new Row(
          children: <Widget>[
            new Flexible(
              child: new Row(
                children: <Widget>[
                  new SizedBox(width: 20),
                  new Container(
                    child: new Text(
                      tabText,
                      style: new TextStyle(
                        color: (isThis != globals.isDark) //Very complicated, don't question it. Explanatory sheet at issue #46
                        ? Colors.white
                        : Colors.black)),
                    padding: EdgeInsets.fromLTRB(8, 1, 8, 0),
                    decoration: new BoxDecoration(
                        color: isThis
                          ? globals.isDark
                            ? Colors.grey[350]
                            : Colors.grey[900]
                          : globals.isDark
                            ? Colors.grey[600]
                            : Colors.grey[400],
                        boxShadow: [
                          new BoxShadow(blurRadius: 3, spreadRadius: -2)
                        ],
                        borderRadius: new BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4))),
                  ),
                ],
              ),
            ),
            Transform.translate(
                offset: Offset(-7, -3), child: new Text(breakLength)),
          ],
        ),
        Container(
          child: new ListTile(
            leading: new Text(lessonNumber,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            title: new Text(capitalize(lessonSubject),
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: new Text(lessonSubtitle),
            trailing: new Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                hasHomework
                    ? new Container(
                        child: new Icon(Icons.home), padding: EdgeInsets.all(5))
                    : new Container(),
                new Column(
                  children: <Widget>[new Text(startTime), new Text(room)],
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
                //new IconButton(icon: Icon(Icons.home), onPressed: null)
              ],
            ),
          ),
          decoration: new BoxDecoration(
              /*color: isThis
              ? Theme.of(context).
              :,*/
              color: isThis
                  ? globals.isDark
                    ? Colors.grey[700]
                    : Colors.grey[350]
                  : globals.isDark
                    ? Colors.grey[800]
                    : Colors.white,
              borderRadius: new BorderRadius.all(Radius.circular(6)),
              boxShadow: [new BoxShadow(blurRadius: 3, spreadRadius: -2)]),
        ),
        new SizedBox(height: 3),
      ],
    ),
  );
}
