import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:syncfusion_flutter_datagrid/datagrid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? directory;

  bool isWebOrDesktop = true;
  List<(File file, String name)> files = [];
  List<(Map<String, String> content, String name)> filesContent = [];

  var scrollController = DataGridController();

  /// Determine the editing action on [SfDataGrid]
  EditingGestureType editingGestureType = EditingGestureType.tap;

  MyDataGridSource? editingDataGridSource;

  var searchETC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): () {
          print('Save');
          save();
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): () {
          print('Reload');
          onFileClicked(lDirectory: directory);
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO): () {
          print('open');
          onFileClicked();
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD): () {
          print('open');
          scrollController.scrollToRow(editingDataGridSource!.rows.length - 1,
              canAnimate: true);
        },
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA): () {
          print('add');
          addNewRow();
        },
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              IconButton(
                onPressed: () {
                  addNewRow();
                },
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              Expanded(
                child: SearchBar(
                  controller: searchETC,
                  onChanged: (value) {
                    editingDataGridSource?.search(value);
                  },
                  trailing: [
                    IconButton(
                      onPressed: () {
                        searchETC.clear();
                        editingDataGridSource?.clearSearch(context);
                      },
                      icon: Icon(Icons.clear),
                    )
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: 'flutter pub run slang'));
                },
                icon: Icon(
                  Icons.copy,
                )),
            IconButton(
                onPressed: () {
                  if (directory != null) {
                    onFileClicked(lDirectory: directory);
                  }
                },
                icon: Icon(
                  Icons.restore_outlined,
                )),
            ElevatedButton(
                onPressed: () {
                  scrollController.scrollToRow(
                      editingDataGridSource!.rows.length - 1,
                      canAnimate: true);
                },
                child: Icon(
                  Icons.downhill_skiing_outlined,
                )),
            ElevatedButton(
                onPressed: () {
                  onFileClicked();
                },
                child: Icon(
                  Icons.folder_open_rounded,
                )),
            ElevatedButton(
                onPressed: () {
                  save();
                },
                child: Icon(
                  Icons.save_alt,
                )),
          ],
        ),
        body: editingDataGridSource == null
            ? Container()
            : SfDataGrid(
                controller: scrollController,
                isScrollbarAlwaysShown: true,
                source: editingDataGridSource!,
                allowEditing: true,
                navigationMode: GridNavigationMode.cell,
                selectionMode: SelectionMode.single,
                editingGestureType: editingGestureType,
                allowColumnsResizing: true,
                columnWidthMode: isWebOrDesktop
                    ? ColumnWidthMode.none
                    : ColumnWidthMode.fill,
                columns: <GridColumn>[
                  GridColumn(
                      columnName: 'key',
                      columnWidthMode: ColumnWidthMode.fill,
                      label: Container(
                        padding: const EdgeInsets.all(8.0),
                        alignment: Alignment.centerRight,
                        child: const Text(
                          'Product No',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                  for (var i = 0; i < filesContent.length; i++)
                    GridColumn(
                        columnName: 'value$i',
                        columnWidthMode: ColumnWidthMode.fill,
                        label: Container(
                          padding: const EdgeInsets.all(8.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            filesContent[i]
                                .$2
                                .split(Platform.isMacOS ? '/' : '\\')
                                .last
                                .replaceAll('.i18n.json', ''),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                ],
              ),
      ),
    );
  }

  void onFileClicked({String? lDirectory}) async {
    //here we will select folder directory
    // then we will read all .json files from that folder

    directory = lDirectory ?? await pickFolder();
    if (directory != null) {
      var tFiles = await readFolderFiles(directory!);
      files = tFiles.map((e) => (e as File, e.path)).toList();
      // filesContent = tFiles.map((e) => ((e as File).readAsString(), e.path)).toList();;

      filesContent = [];
      for (var file in files) {
        var content = await file.$1.readAsString();
        var jsonFile = jsonDecode(content);
        var keys = jsonFile.keys.toList();
        var values = jsonFile.values.toList();
        var fileContent = <String, String>{};
        for (var i = 0; i < keys.length; i++) {
          var key = keys[i];
          var value = values[i];
          fileContent[key] = value;
        }
        filesContent.add((fileContent, file.$2));
      }
    }

    /* 
    [
      {
        "key1": "value1",
        "key2": "value2",
        "key3": "value3",
      },
      {
        "key1": "value1",
        "key2": "value2",
        "key3": "value3",
      },
      {
        "key1": "value1",
        "key2": "value2",
        "key3": "value3",
      },
    ]
    
     */

    //get the file with name strings.i18n.json
    // minemam columnt are 2 the first is the key and the second is the value of the key in first file, there are N+1 Columns N is the number of files
    // the first column is the key and the other columns are the values of the key in each file

    var numberOfFiles = filesContent.length;
    var numberOfColumns = numberOfFiles + 1;
    var numberOfKeys = filesContent
        .where((element) => element.$2.contains('strings.i18n.json'))
        .first
        .$1
        .keys
        .length;
    var numberOfRows = numberOfKeys;

    var data = List.generate(numberOfRows, (index) {
      var row = List.generate(numberOfColumns, (index) {
        return '';
      });
      return row;
    });

    var listOfKeys = filesContent
        .where((element) => element.$2.contains('strings.i18n.json'))
        .first
        .$1
        .keys
        .toList();

    // listOfKeys.sort((a, b) => a.compareTo(b));

    for (var i = 0; i < numberOfFiles; i++) {
      var fileContent = filesContent[i];
      var content = fileContent.$1;
      for (var j = 0; j < listOfKeys.length; j++) {
        var key = listOfKeys[j];
        var value = content[key] ?? "";
        if (i == 0) {
          data[j][0] = listOfKeys[j];
        }
        if (value == '') {
          print('${key} in $i');
        }
        data[j][i + 1] = value;
      }
    }

    editingDataGridSource = MyDataGridSource(
      filesContent: data,
    );

    showDialog(
        context: context,
        builder: (context) {
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) Navigator.pop(context);
          });
          return AlertDialog(
            title: const Text('Statistics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Number of files: $numberOfFiles'),
                Text('Number of keys: $numberOfKeys'),
              ],
            ),
          );
        });

    setState(() {});
  }

  Future<String?> pickFolder() async {
    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a folder',
    );
    return directory;
  }

  Future<List<FileSystemEntity>> readFolderFiles(String folderPath) async {
    final directory = Directory(folderPath);
    final entries = directory.listSync();
    var files = <FileSystemEntity>[];
    for (FileSystemEntity entry in entries) {
      if (entry is File) {
        if (entry.path.endsWith('.i18n.json')) {
          files.add(entry);
        }
      }
    }
    return files;
  }

  void save() {
    var data = editingDataGridSource!.getAllData();

    // there are 4 columns [key, value1, value2, value3]
    // convert to [key, value1], [key, value2], [key, value3]

    var english = <String, String>{};
    var arabic = <String, String>{};
    var kurdish = <String, String>{};
    var kurdishSr = <String, String>{};

    // var csvFileData = "id,english,arabic,badini,sorani\n";

    for (var i = 0; i < data.length; i++) {
      var row = data[i];
      var key = row[0];
      var value1 = row[1];
      var value2 = row[2];
      var value3 = row[3];

      // csvFileData += "$key,${value1 ?? ''},$value2,$value3,$value3\n";

      // for (var j = 0; j < data[i].length; j++) {
      //   var value = data[i][j];
      //   if (value == null) {
      //     data[i][j] = '';
      //   }
      // }

      // if ("$key,$value1,$value2,$value3".toLowerCase().contains('fastday')) {
      //   continue;
      // }
      // csvFileData +=
      //     "${"$key,$value1,$value2,$value3".replaceAll('\n', 'NNLL')}\n";

      english[key] = value1;
      arabic[key] = value2;
      kurdish[key] = value3;
      if (filesContent.length == 4) {
        var value4 = row[4];
        kurdishSr[key] = value4;
      }
    }

    var englishJson = jsonEncode(english);
    var arabicJson = jsonEncode(arabic);
    var kurdishJson = jsonEncode(kurdish);

    //save in new files with prefix new_
    File newEnglishFile = File(filesContent[0].$2);
    File newArabicFile = File(filesContent[1].$2);
    File newKurdishFile = File(filesContent[2].$2);

    newEnglishFile.writeAsStringSync(englishJson);
    newArabicFile.writeAsStringSync(arabicJson);
    newKurdishFile.writeAsStringSync(kurdishJson);
    if (filesContent.length == 4) {
      var kurdishSrJson = jsonEncode(kurdishSr);
      File newKurdishSrFile;
      newKurdishSrFile = File(filesContent[3].$2);
      newKurdishSrFile.writeAsStringSync(kurdishSrJson);
    }

    //save in csv file
    // File csvFile = File('${directory}/strings.csv');
    // csvFile.writeAsStringSync(csvFileData);
  }

  void addNewRow() async {
    //show dialog to enter new key
    var key = '';
    bool submit = false;
    var keyTEC = TextEditingController();
    var focusNode = FocusNode();
    focusNode.requestFocus();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter new key'),
          content: TextField(
            controller: keyTEC,
            focusNode: focusNode,
            onSubmitted: (value) {
              submit = true;
              Navigator.pop(context, key);
            },
            onChanged: (value) {
              key = value;
              // first character should be a letter
              //  [a-zA-Z_][a-zA-Z0-9_]

              if (value.isEmpty) {
                return;
              }

              if (value[0].contains(RegExp(r'[a-zA-Z_]'))) {
                return;
              }

              keyTEC.text = key;
            },
          ),
          actions: [
            ElevatedButton(
                onPressed: () {
                  key = '';
                  Navigator.pop(context);
                },
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  submit = true;
                  Navigator.pop(context, key);
                },
                child: const Text('Add')),
          ],
        );
      },
    );

    if (key.isEmpty || !submit) {
      return;
    }

    //check if the key is already exists in the data

    var data = editingDataGridSource!.getAllData();
    var keys = data.map((e) => e[0]).toList();
    if (keys.contains(key)) {
      return;
    }

    var newRow = List.generate(data[0].length, (index) {
      if (index == 0) return key;
      return '';
    });
    data.add(newRow);
    editingDataGridSource = MyDataGridSource(
      filesContent: data,
    );
    Future.delayed(Duration(milliseconds: 100), () {
      scrollController.scrollToRow(data.length - 1, canAnimate: true);
    });
    setState(() {});
  }

  void reLoadDataFromDisk() {
    editingDataGridSource = MyDataGridSource(
      filesContent: editingDataGridSource!.filesContentOriginal,
    );
  }
}

class MyDataGridSource extends DataGridSource {
  /// Collection of [DataGridRow].
  late List<DataGridRow> dataGridRows;

  /// Help to control the editable text in [TextField] widget.
  TextEditingController editingController = TextEditingController();

  /// Helps to hold the new value of all editable widget.
  /// Based on the new value we will commit the new value into the corresponding
  /// [DataGridCell] on [onSubmitCell] method.
  dynamic newCellValue;

  MyDataGridSource({required this.filesContent}) {
    buildDataGridRow();
  }

  //MARK: Orginal file
  List<List<String>> filesContentOriginal = [];
  List<List<String>> filesContent = [];

  void buildDataGridRow() {
    filesContent = fixTheKeyValues(filesContent);
    filesContentOriginal = filesContent.map((e) => e).toList();

    dataGridRows = filesContent.map((element) {
      var cells = element.map((e) {
        return DataGridCell<String>(
          columnName: e.toString(),
          value: e,
        );
      }).toList();
      return DataGridRow(cells: cells);
    }).toList();
  }

  List<List<String>> getAllData() {
    return filesContent;
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        return Builder(builder: (context) {
          return GestureDetector(
            onSecondaryTapDown: (details) {
              //show menu to delete the row
              var offcet = details.globalPosition;
              showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                      offcet.dx, offcet.dy, offcet.dx, offcet.dy),
                  items: [
                    PopupMenuItem(
                      child: Text('Copy'),
                      value: 'copy',
                      mouseCursor: SystemMouseCursors.click,
                    ),
                    PopupMenuItem(
                      child: Text('Delete "${e.value}"'),
                      value: 'delete',
                      mouseCursor: SystemMouseCursors.click,
                    ),
                  ]).then((value) {
                if (value == 'delete') {
                  deleteRow(row);
                } else if (value == 'copy') {
                  Clipboard.setData(ClipboardData(text: e.value.toString()));
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: e.value.toString().isEmpty ? Colors.red : null,
                border: Border(
                  right: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              padding: const EdgeInsets.all(2.0),
              alignment: e.value.toString().contains(RegExp(r'[\u0600-\u06FF]'))
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                e.value.toString(),
                textDirection:
                    e.value.toString().contains(RegExp(r'[\u0600-\u06FF]'))
                        ? TextDirection.rtl
                        : TextDirection.ltr,
              ),
            ),
          );
        });
      }).toList(),
    );
  }

  @override
  Widget? buildEditWidget(DataGridRow dataGridRow,
      RowColumnIndex rowColumnIndex, GridColumn column, CellSubmit submitCell) {
    var cell = dataGridRow.getCells()[rowColumnIndex.columnIndex];
    var cellValue = cell.value;

    if (cellValue is String) {
      return _buildTextFieldWidget(cellValue, column, submitCell);
    }
    return null;
  }

  Widget _buildTextFieldWidget(
      String displayText, GridColumn column, CellSubmit submitCell) {
    final bool isEn = column.columnName.contains('ar') ||
        column.columnName.contains('ku') ||
        column.columnName.contains('ks');

    return Container(
      padding: const EdgeInsets.all(8.0),
      alignment: isEn
          ? Alignment.centerLeft
          : Alignment.centerRight, //Alignment.center
      child: TextField(
        controller: editingController..text = displayText,
        textAlign: isEn ? TextAlign.left : TextAlign.right,
        textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
        decoration: const InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 16.0),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red))),
        cursorColor: Colors.green,
        keyboardType: TextInputType.text,
        onChanged: (String value) {
          if (value.isNotEmpty) {
            newCellValue = value;
          } else {
            newCellValue = null;
          }
        },
        onSubmitted: (String value) {
          /// Call [CellSubmit] callback to fire the canSubmitCell and
          /// onCellSubmit to commit the new value in single place.
          submitCell();
        },
      ),
    );
  }

  @override
  Future<void> onCellSubmit(DataGridRow dataGridRow,
      RowColumnIndex rowColumnIndex, GridColumn column) async {
    var cell = dataGridRow.getCells()[rowColumnIndex.columnIndex];
    var oldValue = cell.value;

    if (oldValue is String && newCellValue is String) {
      final int dataRowIndex = dataGridRows.indexOf(dataGridRow);
      // print('dataRowIndex: $dataRowIndex');

      // final int dataRowIndex = dataGridRows.indexOf(dataGridRow);

      // if (newCellValue == null || oldValue == newCellValue) {
      //   return;
      // }

      var columnIndex = rowColumnIndex.columnIndex;
      // print('Column Index: $columnIndex ');

      // print(
      //     "${filesContent[dataRowIndex][0]}: ${filesContent[dataRowIndex][columnIndex]}");

      var keyName = filesContent[dataRowIndex][0];

      //get the key name index from the fileContentOriginal
      var keyIndex =
          filesContentOriginal.indexWhere((element) => element[0] == keyName);

      filesContentOriginal[keyIndex][columnIndex] = newCellValue;

      var rowIndex = rowColumnIndex.rowIndex;
      filesContent[rowIndex][columnIndex] = newCellValue;
      dataGridRows[rowIndex].getCells()[columnIndex] = DataGridCell<String>(
          columnName: column.columnName, value: newCellValue);

      // print('${column.columnName} : $columnIndex $rowIndex');

      // filesContentOriginal = filesContent.map((e) => e).toList();

      // dataGridRows[dataRowIndex].getCells()[rowColumnIndex.columnIndex] =
      //     DataGridCell<String>(
      //         columnName: column.columnName, value: newCellValue);
      print(
          "$keyIndex:: ${filesContentOriginal[keyIndex][0]}: ${filesContentOriginal[keyIndex][columnIndex]} :::::::: $newCellValue ||| $rowIndex:$columnIndex");

      newCellValue = null;
      return;
    }
  }

  List<List<String>> fixTheKeyValues(List<List<String>> data) {
    // key is the first column
    //Lower the first letter of the key
    //check if the key is snake case then convert it to camel case

    var newData = data.map((e) => e.first).toList();

    for (var i = 0; i < newData.length; i++) {
      var key = newData[i];
      if (key.isEmpty) {
        print('Error: Key at index $i is null or empty.');
        newData[i] = key;
        continue;
      }

      var newKey = key;
      if (newKey.contains('_')) {
        var parts = newKey.split('_');
        var newParts = parts.map((e) {
          if (e.isEmpty) {
            print('Error: Part of key at index $i is empty.');
            return '';
          }
          return e[0].toUpperCase() + e.substring(1);
        }).toList();
        newKey = newParts.join('');
      }
      newData[i] = newKey[0].toLowerCase() + newKey.substring(1);
    }

    for (var i = 0; i < data.length; i++) {
      data[i][0] = newData[i];
    }

    return data;
  }

  search(String text) {
    filesContent = filesContentOriginal.where((element) {
      var key = '';
      for (var i = 0; i < element.length; i++) {
        key += element[i];
      }
      return key.toLowerCase().contains(text.toLowerCase());
    }).toList();

    // Update dataGridRows based on the updated filesContent
    dataGridRows = filesContent.map((element) {
      var cells = element.map((e) {
        return DataGridCell<String>(
          columnName: e.toString(),
          value: e,
        );
      }).toList();
      return DataGridRow(cells: cells);
    }).toList();

    notifyListeners();
  }

  clearSearch(context) {
    FocusScope.of(context).unfocus();
    filesContent = filesContentOriginal.map((e) => e).toList();
    dataGridRows = filesContent.map((element) {
      var cells = element.map((e) {
        return DataGridCell<String>(
          columnName: e.toString(),
          value: e,
        );
      }).toList();
      return DataGridRow(cells: cells);
    }).toList();
    notifyListeners();
    filesContent = filesContentOriginal.map((e) => e).toList();
    dataGridRows = filesContent.map((element) {
      var cells = element.map((e) {
        return DataGridCell<String>(
          columnName: e.toString(),
          value: e,
        );
      }).toList();
      return DataGridRow(cells: cells);
    }).toList();
    notifyListeners();
  }

  void deleteRow(DataGridRow row) {
    //print row content
    var cells = row.getCells();
    var rowContent = cells.map((e) => e.value).toList();
    print(rowContent);

    var index = dataGridRows.indexOf(row);
    dataGridRows.removeAt(index);
    filesContent.removeAt(index);
    notifyListeners();
  }
}
