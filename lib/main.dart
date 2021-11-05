import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _checkController = TextEditingController();

  List _checkList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    _readData().then((data) {
      setState(() {
        _checkList = json.decode(data);
      });
    });
    super.initState();
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _checkList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  //função de adicionar tarefas
  void _addToDo() {
    setState(() {
      Map<String, dynamic> newCheck = Map();
      newCheck["Title"] = _checkController.text;
      _checkController.text = "";
      newCheck["ok"] = false;
      _checkList.add(newCheck);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CheckList"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 17.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: TextField(
                        controller: _checkController,
                        decoration: InputDecoration(
                            labelText: "Nova Tarefa",
                            labelStyle: TextStyle(color: Colors.blueAccent))),
                  ),
                ),
                ElevatedButton(
                  child: Text("Add"),
                  onPressed: _addToDo,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _checkList.length,
                itemBuilder: buildItem),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    //Função de remover o item
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_checkList[index]["Title"]),
        value: _checkList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_checkList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _checkList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_checkList[index]);
          _lastRemovedPos = index;
          _checkList.removeAt(index);
        });
        _saveData();
        final snack = SnackBar(
          content: Text("\"${_lastRemoved["Title"]}\" Task Removed!"),
          action: SnackBarAction(
            label: "Desfazer",
            onPressed: () {
              setState(() {
                _checkList.insert(_lastRemovedPos, _lastRemoved);
                _saveData();
              });
            },
          ),
          duration: Duration(seconds: 2),
        );
        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      },
    );
  }

  Future<File> _getFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/dados.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_checkList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
