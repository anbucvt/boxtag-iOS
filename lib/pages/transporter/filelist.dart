import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FileList extends StatefulWidget {
  final List<XFile> files;
  final ValueChanged<XFile> onOpenedFile;

  const FileList({Key? key, required this.files, required this.onOpenedFile})
      : super(key: key);

  @override
  _FileListState createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  @override
  Widget build(BuildContext context) {
     var file_len=widget.files.length;
    if (widget.files.length>5){
      file_len=5;
       Fluttertoast.showToast(  
        msg: 'Only 5 files can be uploaded !',  
        toastLength: Toast.LENGTH_SHORT,  
        gravity: ToastGravity.BOTTOM,  
        timeInSecForIosWeb: 1,  
        backgroundColor: Colors.red,  
        textColor: Colors.yellow  
    );  
      }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Selected Files'),
      ),
      body: ListView.builder(
          itemCount: file_len,
          itemBuilder: (context, index) {
            final file = widget.files[index];

            return buildFile(file);
          }),
    );
  }

  Widget buildFile(XFile file) {
    // final kb = file.size / 1024;
    // final mb = kb / 1024;
    // final size = (mb >= 1)
    //     ? '${mb.toStringAsFixed(2)} MB'
    //     : '${kb.toStringAsFixed(2)} KB';
    return InkWell(
      onTap: () => widget.onOpenedFile(file),
      child: ListTile(
        // leading: (file.extension == 'jpg' || file.extension == 'png')
        //     ? Image.file(
        //         File(file.path.toString()),
        //         width: 80,
        //         height: 80,
        //       )
        //     : Container(
        //         width: 80,
        //         height: 80,
        //       ),
        leading:  Image.file(
                File(file.path.toString()),
                width: 80,
                height: 80,
              ),
        title: Text('${file.name}'),
        // subtitle: Text('${file.extension}'),
        // trailing: Text(
        //   '$size',
        //   style: TextStyle(fontWeight: FontWeight.w700),
        // ),
      ),
    );
  }
}