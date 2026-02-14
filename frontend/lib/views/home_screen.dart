import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/controller/langchain_controller.dart';
import 'package:frontend/model/message.dart';
import 'package:frontend/provider/message_provider.dart';
import 'package:frontend/provider/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController linkController = TextEditingController();
  final TextEditingController chatController = TextEditingController();
  late YoutubePlayerController youtubePlayerController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  String? sessionId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Focus.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: Row(
            spacing: 10,
            children: [
              ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(10),
                child: Image.asset(
                  'assets/images/cognitube.png',
                  height: 30,
                  width: 30,
                  fit: BoxFit.cover,
                ),
              ),
              Text(
                "Cognitube",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            Switch(
              value: ref.watch(themeProvider) == ThemeMode.dark,
              focusColor: Colors.white10,
              activeThumbColor: Colors.black,
              activeTrackColor: Colors.white.withOpacity(0.5),
              inactiveTrackColor: Colors.white.withOpacity(0.5),
              inactiveThumbColor: Colors.white,
              activeColor: Colors.white,
              hoverColor: Colors.white10,
              onChanged: (val) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
            if (sessionId != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    sessionId = null;
                    linkController.clear();
                    ref.read(messageProvider.notifier).clearMessages();
                  });
                },
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 350),
            child: sessionId == null ? _buildInputScreen() : _buildChatScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildInputScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animation/Cute bear dancing.json',
              height: 80,
              width: 80,
            ),

            TextField(
              controller: linkController,
              style: GoogleFonts.boldonse(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Paste Link Here...",
                fillColor: Theme.of(context).colorScheme.surface,
                filled: true,

                hintStyle: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!linkController.text.contains('https://www.youtube.com/') &&
                    !linkController.text.contains('https://youtu.be/')) {
                  Fluttertoast.showToast(
                    msg: "Please Paste a Valid YouTube Link",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.TOP,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.blue,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16.0,
                  );
                  return;
                }
                if (linkController.text.isEmpty) {
                  Fluttertoast.showToast(
                    msg: "Please Paste Link First",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.TOP,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.blue,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16.0,
                  );
                  return;
                }
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return AlertDialog(
                      content: Row(
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text("Please Wait..."),
                        ],
                      ),
                    );
                  },
                );
                final sId = await LangchainController().generateTranscript(
                  ytUrl: linkController.text,
                );

                final videoId = YoutubePlayer.convertUrlToId(
                  linkController.text,
                );
                Navigator.pop(context);
                if (videoId != null) {
                  setState(() {
                    youtubePlayerController = YoutubePlayerController(
                      initialVideoId: videoId,
                      flags: const YoutubePlayerFlags(autoPlay: false),
                    );
                    sessionId = sId;
                  });
                }

                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              child: Text(
                "Submit",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatScreen() {
    final messages = ref.watch(messageProvider);
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // Video
        Flexible(
          flex: 3,
          child: YoutubePlayer(controller: youtubePlayerController),
        ),

        // Chat list
        Flexible(
          flex: 6,
          child: ListView.builder(
            reverse: true,
            itemCount: messages.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              final message = messages[messages.length - 1 - index];
              final isMe = message.isUser;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.blue.withOpacity(0.8)
                        : const Color.fromARGB(
                            255,
                            255,
                            132,
                            132,
                          ).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isMe
                      ? Text(
                          message.message,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : MarkdownBody(
                          data: message.message,
                          selectable: true,
                          softLineBreak: true,
                          styleSheet: MarkdownStyleSheet(
                            h1: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            h2: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        if (isLoading)
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Lottie.asset(
                  'assets/animation/Cute bear dancing.json',
                  height: 80,
                  width: 80,
                ),
              ],
            ),
          ),

        // Input
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onSubmitted: isLoading
                ? null
                : (value) async {
                    if (value.trim().isEmpty) return;
                    setState(() {
                      isLoading = true;
                    });
                    await _handleSubmit(value);
                    setState(() {
                      isLoading = false;
                    });
                  },
            controller: chatController,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
            cursorColor: Theme.of(context).colorScheme.onPrimary,
            decoration: InputDecoration(
              hintText: "Ask something about the video...",
              hintStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.1),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (chatController.text.trim().isEmpty) return;
                        setState(() {
                          isLoading = true;
                        });
                        await _handleSubmit(chatController.text);
                        setState(() {
                          isLoading = false;
                        });
                        chatController.clear();
                      },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(String value) async {
    if (sessionId == null) return;
    ref
        .read(messageProvider.notifier)
        .addMessage(
          Message(message: value, sessionId: sessionId!, isUser: true),
        );
    final response = await LangchainController().chatWithVideo(
      message: value,
      sessionId: sessionId!,
    );
    ref
        .read(messageProvider.notifier)
        .addMessage(
          Message(message: response, sessionId: sessionId!, isUser: false),
        );
  } // Add user message ref.read(messageProvider.notifier).addMessage( Message( message: value, sessionId: sessionId!, isUser: true, ), ); // Get bot response final response = await LangchainController().chatWithVideo( message: value, sessionId: sessionId!, ); // Add bot message ref.read(messageProvider.notifier).addMessage( Message( message: response, sessionId: sessionId!, isUser: false, ), ); }
}
