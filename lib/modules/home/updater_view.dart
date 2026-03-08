import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/api/update_info_model.dart';
import 'package:oasx/api/api_client.dart';

import 'package:oasx/translation/i18n_content.dart';

class UpdaterView extends StatelessWidget {
  const UpdaterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UpdateInfoModel>(
        future: ApiClient().getUpdateInfo(),
        builder:
            (BuildContext context, AsyncSnapshot<UpdateInfoModel> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            UpdateInfoModel data = snapshot.data!;
            return SingleChildScrollView(
              child: content(data, context).paddingAll(20),
            );
          }
        });
  }

  Widget content(UpdateInfoModel data, BuildContext context) {
    Widget title = <Widget>[
      data.isUpdate!
          ? const Icon(Icons.cloud_download)
          : const Icon(
              Icons.cloud_off,
              color: Colors.green,
            ),
      data.isUpdate!
          ? Text(I18n.findOasNewVersion.tr,
              style: Theme.of(context).textTheme.titleMedium)
          : Text(I18n.oasLatestVersion.tr,
              style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(
        width: 20,
      ),
      Text('${I18n.currentBranch.tr}: ${data.branch}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center)
          .constrained(height: 26),
      TextButton(
          onPressed: () {
            ApiClient().getExecuteUpdate();
          },
          child: Text(
            I18n.executeUpdate.tr,
          )),
    ].toRow(
        crossAxisAlignment: CrossAxisAlignment.center,
        separator: const SizedBox(width: 10));
    Table differTable = Table(
      border: tableBorder,
      textBaseline: TextBaseline.alphabetic,
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        differHead(context),
        genTableRow(data.currentCommit!, differ: true, localRepo: true),
        genTableRow(data.latestCommit!, differ: true)
      ],
    );
    Widget scrollableTitle = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: title,
    );
    Widget scrollableDifferTable = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: differTable,
    );
    Table submitHistory = Table(
      border: tableBorder,
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: submitHistoryData(data, context),
    );
    Widget scrollableSubmitHistory = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: submitHistory,
    );
    return <Widget>[
      scrollableTitle,
      scrollableDifferTable,
      Text(I18n.detailedSubmissionHistory.tr,
          style: Theme.of(context).textTheme.titleMedium),
      scrollableSubmitHistory
    ].toColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        separator: const SizedBox(
          height: 10,
        ));
  }

  String sha1(String data) {
    return data.substring(0, 7);
  }

  TableRow genTableRow(List<String> data,
      {bool differ = false, bool localRepo = false}) {
    return TableRow(children: [
      Text(sha1(data[0])).paddingAll(10),
      Text(data[1]).paddingAll(10),
      Text(data[2], overflow: TextOverflow.ellipsis, maxLines: 2)
          .paddingAll(10),
      Text(data[3], overflow: TextOverflow.ellipsis, maxLines: 2)
          .paddingAll(10),
      if (differ)
        localRepo
            ? Text(I18n.localRepo.tr).paddingAll(10)
            : Text(I18n.remoteRepo.tr).paddingAll(10)
    ]);
  }

  TableBorder get tableBorder =>
      TableBorder.all(color: Colors.grey, width: 1, style: BorderStyle.solid);

  Map<int, TableColumnWidth> get columnWidths => const {
        0: FixedColumnWidth(80.0),
        1: FixedColumnWidth(80.0),
        2: FixedColumnWidth(130.0),
        3: FixedColumnWidth(200.0),
        4: FixedColumnWidth(80.0)
      };

  TableRow differHead(BuildContext context) => TableRow(children: [
        Text('SHA1', style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
        Text(I18n.author.tr, style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
        Text(I18n.submitTime.tr,
                style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
        Text(I18n.submitInfo.tr,
                style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
        Text('Repo', style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
      ]);

  TableRow historyHead(BuildContext context) => TableRow(children: [
        Text('SHA1', style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
        Text(I18n.author.tr, style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
        Text(I18n.submitTime.tr,
                style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
        Text(I18n.submitInfo.tr,
                style: Theme.of(context).textTheme.titleMedium)
            .paddingAll(10),
      ]);

  List<TableRow> submitHistoryData(data, BuildContext context) {
    List<TableRow> result =
        data.commit!.map((e) => genTableRow(e)).toList().cast<TableRow>();
    result.insert(0, historyHead(context));
    return result;
  }
}

