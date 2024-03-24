import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import 'package:apidash/utils/utils.dart';
import 'package:apidash/widgets/widgets.dart';
import 'package:apidash/models/models.dart';
import 'package:apidash/consts.dart';

class NotSentWidget extends StatelessWidget {
  const NotSentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.north_east_rounded,
            size: 40,
            color: color,
          ),
          Text(
            'Not Sent',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class SendingWidget extends StatefulWidget {
  final DateTime? startSendingTime;
  final bool isTest;
  const SendingWidget({super.key, required this.startSendingTime, this.isTest=false});

  @override
  State<SendingWidget> createState() => _SendingWidgetState();
}

class _SendingWidgetState extends State<SendingWidget> {
  int _millisecondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.startSendingTime != null) {
      _millisecondsElapsed = widget.isTest ? 0 :
          DateTime.now().difference(widget.startSendingTime!).inMilliseconds;
      _timer = Timer.periodic(const Duration(milliseconds: 100), _updateTimer);
    }
  }

  void _updateTimer(Timer timer) {
    setState(() {
      _millisecondsElapsed += 100;
    });
  }

  @override
  void dispose() {
    if (_timer != null && _timer!.isActive) _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Lottie.asset(kAssetSendingLottie),
        ),
        Padding(
          padding: kPh20t40,
          child: Visibility(
            visible: _millisecondsElapsed >= 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alarm),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  'Time elapsed: ${humanizeDuration(Duration(milliseconds: _millisecondsElapsed))}',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: kTextStyleButton,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class ResponsePaneHeader extends StatelessWidget {
  const ResponsePaneHeader({
    super.key,
    this.responseStatus,
    this.message,
    this.time,
    this.onClearResponse,
  });

  final int? responseStatus;
  final String? message;
  final Duration? time;
  final VoidCallback? onClearResponse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kPh20v10,
      child: SizedBox(
        height: kHeaderHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: "Response (",
                  ),
                  TextSpan(
                    text: "$responseStatus",
                    style: TextStyle(
                      color: getResponseStatusCodeColor(
                        responseStatus,
                        brightness: Theme.of(context).brightness,
                      ),
                      fontFamily: kCodeStyle.fontFamily,
                    ),
                  ),
                  const TextSpan(
                    text: ")",
                  ),
                ],
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            kHSpacer20,
            Expanded(
              child: Text(
                message ?? "",
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontFamily: kCodeStyle.fontFamily,
                      color: getResponseStatusCodeColor(
                        responseStatus,
                        brightness: Theme.of(context).brightness,
                      ),
                    ),
              ),
            ),
            kHSpacer20,
            Text(
              humanizeDuration(time),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontFamily: kCodeStyle.fontFamily,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            kHSpacer10,
            ClearResponseButton(
              onPressed: onClearResponse,
            )
          ],
        ),
      ),
    );
  }
}

class ResponseTabView extends StatefulWidget {
  const ResponseTabView({
    super.key,
    this.selectedId,
    required this.children,
  });

  final String? selectedId;
  final List<Widget> children;
  @override
  State<ResponseTabView> createState() => _ResponseTabViewState();
}

class _ResponseTabViewState extends State<ResponseTabView>
    with TickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: 2,
      animationDuration: kTabAnimationDuration,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          key: Key(widget.selectedId!),
          controller: _controller,
          overlayColor: kColorTransparentState,
          onTap: (index) {},
          tabs: const [
            SizedBox(
              height: kTabHeight,
              child: Center(
                child: Text(
                  'Body',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: kTextStyleButton,
                ),
              ),
            ),
            SizedBox(
              height: kTabHeight,
              child: Center(
                child: Text(
                  'Headers',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: kTextStyleButton,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: widget.children,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ResponseHeadersHeader extends StatelessWidget {
  const ResponseHeadersHeader({
    super.key,
    required this.map,
    required this.name,
  });

  final Map map;
  final String name;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kHeaderHeight,
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$name (${map.length} items)",
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (map.isNotEmpty)
            CopyButton(
              toCopy: kEncoder.convert(map),
            ),
        ],
      ),
    );
  }
}

const kHeaderRow = ["Header Name", "Header Value"];

class ResponseHeaders extends StatelessWidget {
  const ResponseHeaders({
    super.key,
    required this.responseHeaders,
    required this.requestHeaders,
  });

  final Map responseHeaders;
  final Map requestHeaders;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kPh20v5,
      child: ListView(
        children: [
          ResponseHeadersHeader(
            map: responseHeaders,
            name: "Response Headers",
          ),
          if (responseHeaders.isNotEmpty) kVSpacer5,
          if (responseHeaders.isNotEmpty)
            MapTable(
              map: responseHeaders,
              colNames: kHeaderRow,
              firstColumnHeaderCase: true,
            ),
          kVSpacer10,
          ResponseHeadersHeader(
            map: requestHeaders,
            name: "Request Headers",
          ),
          if (requestHeaders.isNotEmpty) kVSpacer5,
          if (requestHeaders.isNotEmpty)
            MapTable(
              map: requestHeaders,
              colNames: kHeaderRow,
              firstColumnHeaderCase: true,
            ),
        ],
      ),
    );
  }
}

class ResponseBody extends StatelessWidget {
  const ResponseBody({
    super.key,
    this.selectedRequestModel,
  });

  final RequestModel? selectedRequestModel;

  @override
  Widget build(BuildContext context) {
    final responseModel = selectedRequestModel?.responseModel;
    if (responseModel == null) {
      return const ErrorMessage(
          message:
              'Error: Response data does not exist. $kUnexpectedRaiseIssue');
    }

    var body = responseModel.body;
    var formattedBody = responseModel.formattedBody;
    if (body == null) {
      return const ErrorMessage(
          message: 'Response body is missing (null). $kUnexpectedRaiseIssue');
    }
    if (body.isEmpty) {
      return const ErrorMessage(
        message: 'No content',
        showIcon: false,
        showIssueButton: false,
      );
    }

    var mediaType = responseModel.mediaType;
    if (mediaType == null) {
      return ErrorMessage(
          message:
              'Unknown Response Content-Type - ${responseModel.contentType}. $kUnexpectedRaiseIssue');
    }

    var responseBodyView = getResponseBodyViewOptions(mediaType);
    var options = responseBodyView.$1;
    var highlightLanguage = responseBodyView.$2;

    if (formattedBody == null) {
      options = [...options];
      options.remove(ResponseBodyView.code);
    }

    return BodySuccess(
      key: Key("${selectedRequestModel!.id}-response"),
      mediaType: mediaType,
      options: options,
      bytes: responseModel.bodyBytes!,
      body: body,
      formattedBody: formattedBody,
      highlightLanguage: highlightLanguage,
    );
  }
}

class BodySuccess extends StatefulWidget {
  const BodySuccess(
      {super.key,
      required this.mediaType,
      required this.body,
      required this.options,
      required this.bytes,
      this.formattedBody,
      this.highlightLanguage});
  final MediaType mediaType;
  final List<ResponseBodyView> options;
  final String body;
  final Uint8List bytes;
  final String? formattedBody;
  final String? highlightLanguage;
  @override
  State<BodySuccess> createState() => _BodySuccessState();
}

class _BodySuccessState extends State<BodySuccess> {
  int segmentIdx = 0;

  @override
  Widget build(BuildContext context) {
    var currentSeg = widget.options[segmentIdx];
    var codeTheme = Theme.of(context).brightness == Brightness.light
        ? kLightCodeTheme
        : kDarkCodeTheme;
    final textContainerdecoration = BoxDecoration(
      color: Color.alphaBlend(
          (Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.primaryContainer)
              .withOpacity(kForegroundOpacity),
          Theme.of(context).colorScheme.surface),
      border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
      borderRadius: kBorderRadius8,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var showLabel = showButtonLabelsInBodySuccess(
          widget.options.length,
          constraints.maxWidth,
        );
        return Padding(
          padding: kP10,
          child: Column(
            children: [
              Row(
                children: [
                  (widget.options == kRawBodyViewOptions)
                      ? const SizedBox()
                      : SegmentedButton<ResponseBodyView>(
                          style: const ButtonStyle(
                            padding: MaterialStatePropertyAll(
                              EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                          selectedIcon: Icon(currentSeg.icon),
                          segments: widget.options
                              .map<ButtonSegment<ResponseBodyView>>(
                                (e) => ButtonSegment<ResponseBodyView>(
                                  value: e,
                                  label: Text(e.label),
                                  icon: Icon(e.icon),
                                ),
                              )
                              .toList(),
                          selected: {currentSeg},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              segmentIdx =
                                  widget.options.indexOf(newSelection.first);
                            });
                          },
                        ),
                  const Spacer(),
                  kCodeRawBodyViewOptions.contains(currentSeg)
                      ? CopyButton(
                          toCopy: widget.formattedBody ?? widget.body,
                          showLabel: showLabel,
                        )
                      : const SizedBox(),
                  SaveInDownloadsButton(
                    content: widget.bytes,
                    mimeType: widget.mediaType.mimeType,
                    showLabel: showLabel,
                  ),
                ],
              ),
              kVSpacer10,
              switch (currentSeg) {
                ResponseBodyView.preview || ResponseBodyView.none => Expanded(
                    child: Container(
                      width: double.maxFinite,
                      padding: kP8,
                      decoration: textContainerdecoration,
                      child: Previewer(
                        bytes: widget.bytes,
                        body: widget.body,
                        type: widget.mediaType.type,
                        subtype: widget.mediaType.subtype,
                        hasRaw: widget.options.contains(ResponseBodyView.raw),
                      ),
                    ),
                  ),
                ResponseBodyView.code => Expanded(
                    child: Container(
                      width: double.maxFinite,
                      padding: kP8,
                      decoration: textContainerdecoration,
                      child: CodePreviewer(
                        code: widget.formattedBody ?? widget.body,
                        theme: codeTheme,
                        language: widget.highlightLanguage,
                        textStyle: kCodeStyle,
                      ),
                    ),
                  ),
                ResponseBodyView.raw => Expanded(
                    child: Container(
                      width: double.maxFinite,
                      padding: kP8,
                      decoration: textContainerdecoration,
                      child: SingleChildScrollView(
                        child: SelectableText(
                          widget.formattedBody ?? widget.body,
                          style: kCodeStyle,
                        ),
                      ),
                    ),
                  ),
              }
            ],
          ),
        );
      },
    );
  }
}
