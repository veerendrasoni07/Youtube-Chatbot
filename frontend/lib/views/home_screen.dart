import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/controller/langchain_controller.dart';
import 'package:frontend/model/message.dart';
import 'package:frontend/provider/message_provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
  }

  String? sessionId;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        Focus.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: Text(
            "Youtube ChatBot",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
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
            TextField(
              controller: linkController,
              style: GoogleFonts.boldonse(
                fontSize: 24,
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "Paste Link Here...",
                fillColor: Colors.red,
                filled: true,
                hintStyle: GoogleFonts.boldonse(
                  fontSize: 26,
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
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

              child: Text(
                "Submit",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
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
        SizedBox(
          height: size.height * 0.3,
          child: YoutubePlayer(controller: youtubePlayerController),
        ),

        // Chat list
        Expanded(
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
                        ? Colors.blue.withOpacity(0.3)
                        : const Color.fromARGB(
                            255,
                            255,
                            132,
                            132,
                          ).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isMe
                      ? Text(message.message)
                      : MarkdownBody(
                          data: message.message,
                          styleSheet: MarkdownStyleSheet(
                            h1: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            h2: TextStyle(color: Colors.white70),
                          ),
                        ),
                ),
              );
            },
          ),
        ),

        // Input
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onSubmitted: (value) {
              _handleSubmit(value);
            },
            controller: chatController,
            decoration: InputDecoration(
              hintText: "Ask something about the video...",
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _handleSubmit(chatController.text);
                  chatController.clear();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit(String value) async {
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
