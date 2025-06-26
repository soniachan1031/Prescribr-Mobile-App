import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/api_keys.dart';

class ZiraAIViewModel extends ChangeNotifier {
  final TextEditingController inputController = TextEditingController();
  final List<Map<String, String>> messages = [];
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  final ScrollController scrollController = ScrollController();

  bool isListening = false;
  bool isLoading = false;
  bool isVoiceMode = false;
  bool isSpeechEnabled = true;
  bool hasError = false;
  bool isWebMode = kIsWeb;
  String errorMessage = '';
  
  // Debug flag
  final bool debugMode = true;

  String get systemPrompt =>
      "You are Zira AI, a drug assistant. You only provide information related to drug medications, including uses, dosages, side effects, and interactions. You must not answer any questions or provide information unrelated to drug medications.";

  ZiraAIViewModel() {
    debugPrint('ZiraAIViewModel initialized');
    _init();
  }

  void _init() async {
    debugPrint('ZiraAIViewModel: Starting initialization');
    await _initTTS();
    await _initSpeech();
    
    // Always add a welcome message when we initialize
    const welcome =
        'Hi, I\'m Zira, your medication assistant. How can I help you today?';
    
    debugPrint('ZiraAIViewModel: Adding welcome message to conversation');
    messages.add({'role': 'assistant', 'content': welcome});
    notifyListeners();
    
    // Wait a moment before speaking to ensure TTS is ready
    await Future.delayed(Duration(milliseconds: 500));
    if (isSpeechEnabled) {
      debugPrint('ZiraAIViewModel: Speaking welcome message');
      await flutterTts.speak(welcome);
    }
    
    debugPrint('ZiraAIViewModel: Initialization complete with ${messages.length} messages');
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _initSpeech() async {
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        hasError = true;
        errorMessage = 'Microphone permission is required.';
        notifyListeners();
        return;
      }
    }
    await speech.initialize();
  }

  void toggleVoiceMode() {
    isVoiceMode = !isVoiceMode;
    if (isVoiceMode)
      startListening();
    else
      stopListening();
    notifyListeners();
  }

  void toggleSpeech() {
    isSpeechEnabled = !isSpeechEnabled;
    notifyListeners();
  }

  Future<void> startListening() async {
    isListening = true;
    notifyListeners();
    await speech.listen(onResult: (result) {
      if (result.finalResult && result.recognizedWords.isNotEmpty) {
        sendMessage(result.recognizedWords);
        isListening = false;
        notifyListeners();
      }
    });
  }

  Future<void> stopListening() async {
    isListening = false;
    await speech.stop();
    notifyListeners();
  }

  Future<void> sendMessage(String msg) async {
    if (msg.trim().isEmpty) return;
    
    debugPrint('ZiraAIViewModel: Sending message: "${msg.trim()}"');
    
    // Add user message to conversation
    messages.add({'role': 'user', 'content': msg});
    inputController.clear();
    isLoading = true;
    hasError = false;
    errorMessage = '';
    notifyListeners();
    
    debugPrint('ZiraAIViewModel: Current message count: ${messages.length}');

    // Scroll to the bottom after adding the user's message
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      // Demo mode or web testing
      if (kIsWeb) {
        debugPrint('ZiraAIViewModel: Using web demo mode');
        await Future.delayed(const Duration(seconds: 2));
        String reply;
        if (msg.toLowerCase().contains('aspirin')) {
          reply = 'Aspirin is a pain reliever that also reduces inflammation and fever. It belongs to a group of medicines called non-steroidal anti-inflammatory drugs (NSAIDs) and can also reduce blood clotting.';
        } else if (msg.toLowerCase().contains('ibuprofen')) {
          reply = 'Ibuprofen is a non-steroidal anti-inflammatory drug (NSAID) used to relieve pain, reduce inflammation, and lower fever. Common brand names include Advil and Motrin.';
        } else {
          reply = 'I can provide information about medications, including uses, side effects, interactions, and proper dosages. What medication would you like to know about?';
        }
        
        debugPrint('ZiraAIViewModel: Adding AI response in web mode');
        messages.add({'role': 'assistant', 'content': reply});
        if (isSpeechEnabled) await flutterTts.speak(reply);
        
        isLoading = false;
        notifyListeners();
        _scrollToBottom();
        return;
      }

      debugPrint('ZiraAIViewModel: Sending API request to Claude');
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiKeys.anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1000,
          'system': systemPrompt,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('ZiraAIViewModel: API response successful');
        final reply = jsonDecode(response.body)['content'][0]['text'] ?? '';
        
        debugPrint('ZiraAIViewModel: Adding AI response to conversation');
        messages.add({'role': 'assistant', 'content': reply});
        
        if (isSpeechEnabled) {
          debugPrint('ZiraAIViewModel: Speaking AI response');
          await flutterTts.speak(reply);
        }
      } else {
        debugPrint('ZiraAIViewModel: API error ${response.statusCode}');
        messages.add({
          'role': 'assistant',
          'content': 'Zira AI failed: ${response.statusCode}',
        });
      }
    } catch (e) {
      debugPrint('ZiraAIViewModel: Exception occurred: $e');
      hasError = true;
      errorMessage = 'Error: $e';
      messages.add({'role': 'assistant', 'content': errorMessage});
    } finally {
      isLoading = false;
      notifyListeners();
      _scrollToBottom();
      
      debugPrint('ZiraAIViewModel: Message processing complete. Total messages: ${messages.length}');
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void disposeResources() {
    inputController.dispose();
    scrollController.dispose();
    flutterTts.stop();
    speech.cancel();
  }
}

class ZiraAIScreen extends StatefulWidget {
  const ZiraAIScreen({super.key});
  
  @override
  State<ZiraAIScreen> createState() => _ZiraAIScreenState();
}

class _ZiraAIScreenState extends State<ZiraAIScreen> {
  late ZiraAIViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _viewModel = ZiraAIViewModel();
  }

  @override
  void dispose() {
    _viewModel.disposeResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ZiraAIScreen: Building UI with ${_viewModel.messages.length} messages');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zira AI'),
        actions: [
          // Toggle between voice and text input modes
          IconButton(
            icon: Icon(_viewModel.isVoiceMode ? Icons.keyboard : Icons.mic),
            onPressed: _viewModel.toggleVoiceMode,
            tooltip: _viewModel.isVoiceMode ? 'Switch to text input' : 'Switch to voice input',
          ),
          // Toggle AI speech on/off
          IconButton(
            icon: Icon(_viewModel.isSpeechEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: _viewModel.toggleSpeech,
            tooltip: _viewModel.isSpeechEnabled ? 'Mute AI speech' : 'Enable AI speech',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          debugPrint('ZiraAIScreen: Rebuilding UI, message count: ${_viewModel.messages.length}');
          return Column(
            children: [
              // Error banner
              if (_viewModel.hasError)
                Container(
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  child: Text(
                    _viewModel.errorMessage,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              
              // Chat messages
              Expanded(
                child: _viewModel.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FontAwesomeIcons.pills,
                              size: 64,
                              color: Theme.of(context).primaryColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ask Zira about medications',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _viewModel.scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _viewModel.messages.length,
                        itemBuilder: (context, index) {
                          final message = _viewModel.messages[index];
                          final isUser = message['role'] == 'user';
                          
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.all(12.0),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isUser ? Theme.of(context).primaryColor : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                message['content'] ?? '',
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Loading indicator
              if (_viewModel.isLoading)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 12),
                      Text('Processing...', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              
              // Voice mode UI
              if (_viewModel.isVoiceMode)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _viewModel.isListening ? Icons.mic : Icons.mic_none,
                        size: 30,
                        color: _viewModel.isListening ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _viewModel.isListening 
                            ? 'Listening... Tap to stop' 
                            : 'Tap the microphone to speak',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _viewModel.isListening 
                            ? _viewModel.stopListening 
                            : _viewModel.startListening,
                        child: Icon(_viewModel.isListening ? Icons.stop : Icons.mic),
                      ),
                    ],
                  ),
                )
              // Text input UI
              else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _viewModel.inputController,
                          decoration: InputDecoration(
                            hintText: 'Ask about medications...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) {
                              _viewModel.sendMessage(text);
                              // Reset focus after submission
                              FocusScope.of(context).requestFocus(FocusNode());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      FloatingActionButton(
                        onPressed: () {
                          final text = _viewModel.inputController.text;
                          if (text.trim().isNotEmpty) {
                            _viewModel.sendMessage(text);
                            // Ensure focus is maintained on the text field after sending
                            FocusScope.of(context).requestFocus(FocusNode());
                          }
                        },
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
