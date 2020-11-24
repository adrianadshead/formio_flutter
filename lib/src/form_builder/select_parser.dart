import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:formio_flutter/formio_flutter.dart';
import 'package:formio_flutter/src/abstraction/abstraction.dart';
import 'package:formio_flutter/src/models/models.dart';
import 'package:formio_flutter/src/providers/providers.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

/// Extends the abstract class [WidgetParser]
class SelectParser extends WidgetParser {
  /// Returns a [Widget] of type [DropDown/Selector]
  @override
  Widget parse(Component map, BuildContext context, ClickListener listener) {
    return SelectParserWidget(map: map);
  }

  /// [widgetName] => "select"
  @override
  String get widgetName => "select";
}

// ignore: must_be_immutable
class SelectParserWidget extends StatefulWidget implements Manager {
  final Component map;
  Value selected;
  WidgetProvider widgetProvider;

  SelectParserWidget({this.map});

  @override
  _SelectParserWidgetState createState() => _SelectParserWidgetState();

  /// Returns a [String] with the value contained inside [Component.key]
  @override
  String keyValue() => map.key ?? "selectField";

  /// Current value of the [Widget]
  @override
  get data => selected.value ?? "";
}

class _SelectParserWidgetState extends State<SelectParserWidget> {
  List<DropdownMenuItem<Value>> _values;
  Future<List<Value>> _futureValues;
  final Map<String, dynamic> _mapper = new Map();

  /// When the [url] isn't null or empty then the data is prefetched for the [Select] widget.
  Future<List<Value>> _makeRequest() async {
    var client = http.Client();
    final response = await client.get(widget.map.data.url);
    final result = Value().valuesFromJson(response.body);
    if (result.isNotEmpty) setupDropDown(result);
    if (result.isNotEmpty) _mapper[widget.map.key] = result.first.value;
    return result;
  }

  /// Setup all the functionlity for the dropDown widget.
  setupDropDown(List<Value> values) {
    _values = buildDropDownItems(values);
    widget.selected = _values[0].value;
  }

  @override
  void initState() {
    super.initState();
    if (widget.map.data.url.isEmpty &&
        widget.map.data.values.first.value != null) {
      setupDropDown(widget.map.data.values);
      _mapper[widget.map.key] = _values[0].value;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<DropdownMenuItem<Value>> buildDropDownItems(List listItems) {
    List<DropdownMenuItem<Value>> items = List();
    if (listItems == null ||
        listItems[0] == null ||
        (listItems[0] as Value).value == null) {
      items.add(DropdownMenuItem(
        child: Text('Empty'),
        value: null,
      ));
    } else {
      for (Value listItem in listItems) {
        items.add(
          DropdownMenuItem(
            child: Text(listItem.label),
            value: listItem,
          ),
        );
      }
    }
    return items;
  }

  @override
  void didChangeDependencies() {
    /// Declared [WidgetProvider] to consume the [Map<String, dynamic>] created from it.
    widget.widgetProvider = Provider.of<WidgetProvider>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.map.data.url.isNotEmpty) _futureValues ??= _makeRequest();
    bool isVisible = true;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: StreamBuilder(
        stream: widget.widgetProvider.widgetBloc.widgetsStream,
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (widget.map.conditional != null)
            isVisible = (widget.map.conditional != null &&
                    snapshot.data != null)
                ? (snapshot.data.containsKey(widget.map.conditional.when) &&
                        snapshot.data[widget.map.conditional.when].toString() ==
                            widget.map.conditional.eq)
                    ? widget.map.conditional.show
                    : true
                : true;
          return (!isVisible)
              ? Container()
              : Neumorphic(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Flex(
                    direction: Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NeumorphicText(
                        (widget.map.label == null || widget.map.label.isEmpty)
                            ? ""
                            : widget.map.label,
                        textStyle: NeumorphicTextStyle(
                            fontSize: 17.0, fontWeight: FontWeight.w500),
                        style: NeumorphicStyle(
                            depth: 13.0, intensity: 0.90, color: Colors.black),
                      ),
                      (widget.map.data.url.isNotEmpty)
                          ? FutureBuilder(
                              future: _futureValues,
                              builder: (context,
                                  AsyncSnapshot<List<Value>> snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.done:
                                    if (snapshot.hasData)
                                      _values =
                                          buildDropDownItems(snapshot.data);
                                    return DropdownButton<Value>(
                                      hint: NeumorphicText(
                                        widget.map.label,
                                        style: NeumorphicStyle(
                                            depth: 13.0,
                                            intensity: 0.90,
                                            color: Colors.black),
                                      ),
                                      isExpanded: true,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                      value: widget.selected,
                                      items: _values,
                                      onChanged: !widget.map.disabled
                                          ? (value) {
                                              _mapper.update(widget.map.key,
                                                  (nVal) => value);
                                              widget.widgetProvider.widgetBloc
                                                  .registerMap(_mapper);
                                              setState(() =>
                                                  widget.selected = value);
                                            }
                                          : null,
                                    );
                                    break;
                                  default:
                                    return CircularProgressIndicator();
                                    break;
                                }
                              },
                            )
                          : (widget.map.data.values.first.value != null)
                              ? DropdownButton<Value>(
                                  hint: NeumorphicText(
                                    widget.map.label,
                                    style: NeumorphicStyle(
                                        depth: 13.0,
                                        intensity: 0.90,
                                        color: Colors.black),
                                  ),
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                  value: widget.selected,
                                  items: _values,
                                  onChanged: !widget.map.disabled
                                      ? (value) {
                                          print("VALUE: ${value.value}");
                                          _mapper.update(widget.map.key,
                                              (nVal) => value.value);
                                          widget.widgetProvider.widgetBloc
                                              .registerMap(_mapper);
                                          setState(
                                              () => widget.selected = value);
                                        }
                                      : null,
                                )
                              : DropdownButton<Value>(
                                  hint: NeumorphicText(
                                    widget.map.label,
                                    style: NeumorphicStyle(
                                        depth: 13.0,
                                        intensity: 0.90,
                                        color: Colors.black),
                                  ),
                                  isExpanded: true,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                  value: widget.selected,
                                  items: _values,
                                  onChanged: !widget.map.disabled
                                      ? (value) {
                                          _mapper.update(widget.map.key,
                                              (nVal) => value.value);
                                          widget.widgetProvider.widgetBloc
                                              .registerMap(_mapper);
                                          setState(
                                              () => widget.selected = value);
                                        }
                                      : null,
                                ),
                    ],
                  ),
                );
        },
      ),
    );
  }
}
