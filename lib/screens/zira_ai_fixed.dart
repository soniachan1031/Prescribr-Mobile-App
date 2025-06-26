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

enum ConversationState { idle, user_talking, ai_talking, user_typing }

class ZiraAIScreen extends StatefulWidget {
  const ZiraAIScreen({super.key});

  @override
  State<ZiraAIScreen> createState() => _ZiraAIState();
}

class _ZiraAIState extends State<ZiraAIScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  ConversationState _conversationState = ConversationState.idle;
  bool _isVoiceModeActive = false; // false = text mode, true = voice mode
  bool _isAISpeechEnabled = true; // Toggle for AI speech
  bool _isListening = false;
  bool _isLoading = false; // Track loading state during API calls
  bool _isWebDemoMode = false; // Track if we're in web demo mode
  bool _hasError = false; // Track if there's an error
  String _errorMessage = ''; // Error message to display

  // System prompt for Claude API
  final String _systemPrompt =
      "You are an AI assistant named Zira that specializes in providing information about medications."
      "Provide detailed, accurate information about medication uses, side effects, drug interactions, and dosages."
      "Always emphasize that users should consult healthcare professionals for medical advice."
      "Be concise but informative.";

  @override
  void initState() {
    super.initState();

    // Initialize state variables
    _isWebDemoMode = kIsWeb;
    _conversationState = ConversationState.idle;
    _isAISpeechEnabled = true; // Ensure AI speech is enabled by default

    // Initialize TTS and speech recognition
    _initTTS(); // Call the TTS initialization function
    _initializeSpeechRecognition(); // Initialize speech recognition

    // Add welcome message and speak it
    if (_messages.isEmpty) {
      final welcomeMessage =
          'Hi, I\'m Zira, your medication assistant. How can I help you today?';
      setState(() {
        _messages.add({'role': 'assistant', 'content': welcomeMessage});
      });

      // Speak the welcome message after a short delay to allow TTS initialization
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _speak(welcomeMessage);
        }
      });
    }

    // Add a post-frame callback to handle any state changes needed after build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Already added welcome message in initState, no need to do it again here
      }
    });
  }

  // Initialize text-to-speech with proper settings and event handlers
  Future<void> _initTTS() async {
    try {
      debugPrint('Initializing TTS engine...');

      // Get list of available languages for debugging
      try {
        var languages = await _flutterTts.getLanguages;
        debugPrint('Available TTS languages: $languages');
      } catch (e) {
        debugPrint('Error getting TTS languages: $e');
      }

      // Initialize basic engine
      await _flutterTts.awaitSpeakCompletion(true);

      // Base configuration for all platforms
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // Slower rate for better clarity
      await _flutterTts.setVolume(1.0); // Max volume
      await _flutterTts.setPitch(1.0); // Normal pitch

      // Android-specific configuration
      if (!kIsWeb && Platform.isAndroid) {
        debugPrint('Setting up Android-specific TTS options');

        // Get available voices for debugging
        try {
          var voices = await _flutterTts.getVoices;
          debugPrint('Available Android TTS voices: $voices');
        } catch (e) {
          debugPrint('Error getting TTS voices: $e');
        }

        // Get available engines and select Google if possible
        try {
          final engines = await _flutterTts.getEngines;
          debugPrint('Available Android TTS engines: $engines');

          // Specifically select Google engine if available
          if (engines.isNotEmpty) {
            if (engines.contains('com.google.android.tts')) {
              await _flutterTts.setEngine('com.google.android.tts');
              debugPrint('Set TTS engine to Google TTS');
            }
          }
        } catch (e) {
          debugPrint('Error setting TTS engine: $e');
        }
      }

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        setState(() {
          _conversationState = ConversationState.idle;
        });
        // Add small delay before starting to listen again
        Future.delayed(const Duration(milliseconds: 800), () {
          // Double-check we're still in a valid state to start listening
          if (_isVoiceModeActive &&
              _conversationState == ConversationState.idle &&
              !_isListening &&
              mounted) {
            _startListening();
          }
        });
      });

      debugPrint('TTS initialization completed successfully');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize text-to-speech: $e';
      });
    }
  }

  // Toggle between text and voice input modes
  void _toggleInputMode() {
    setState(() {
      _isVoiceModeActive = !_isVoiceModeActive;

      if (_isVoiceModeActive) {
        // Switching to voice mode
        _conversationState = ConversationState.idle;
        // Start listening immediately if in voice mode and idle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_conversationState == ConversationState.idle && mounted) {
            _startListening();
          }
        });
      } else {
        // Switching to text mode
        if (_isListening) {
          _stopListening();
        }
        _conversationState = ConversationState.idle;
      }
    });

    _logState('Input Mode Toggled');
  }

  // Toggle AI speech on/off
  void _toggleAISpeech() {
    setState(() {
      _isAISpeechEnabled = !_isAISpeechEnabled;
    });

    // If disabling speech while AI is talking, stop it
    if (!_isAISpeechEnabled &&
        _conversationState == ConversationState.ai_talking) {
      _flutterTts.stop();
      setState(() {
        _conversationState = ConversationState.idle;
      });
    }

    _logState('AI Speech Toggled');
  }

  // Send message (either typed or spoken)
  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    debugPrint('Sending message: $message');
    _logState('Message Sent');

    // Clear input field if in text mode
    if (!_isVoiceModeActive) {
      _inputController.clear();
    }

    // Add user message to conversation
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
      _conversationState = ConversationState.idle;
      _hasError = false;
      _errorMessage = '';
    });

    _scrollToBottom();

    try {
      // Check if we're in web demo mode or if this is a demo/test scenario
      if (_isWebDemoMode || kIsWeb) {
        await _handleWebDemoMode(message);
        return;
      }

      // Handle real API call for native platforms
      await _handleApiCall(message);
    } catch (e) {
      debugPrint('Exception during message handling: $e');

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error: $e';
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error: $e'
        });
      });
      _scrollToBottom();
    }
  }

  // Handle web demo mode responses
  Future<void> _handleWebDemoMode(String message) async {
    setState(() {
      _isWebDemoMode = true; // Enable demo mode for testing
      _isLoading = false;
      _hasError = false;
      _errorMessage = '';
    });

    // For demo purposes, simulate responses for common questions
    if (message.toLowerCase().contains('hello') ||
        message.toLowerCase().contains('hi')) {
      await _simulateResponse(
          'Hello! I am Zira, your medication assistant. I am currently in test mode to verify speech functionality. What medication would you like to know about?');
      return;
    }

    if (message.toLowerCase().contains('aspirin')) {
      await _simulateResponse(
          'Aspirin is a nonsteroidal anti-inflammatory drug used to reduce pain, fever, and inflammation. It also has antiplatelet effects and is often used in low doses to prevent heart attacks and strokes. Common side effects include stomach irritation and increased risk of bleeding.');
      return;
    } else if (message.toLowerCase().contains('ibuprofen')) {
      await _simulateResponse(
          'Ibuprofen is a nonsteroidal anti-inflammatory drug that reduces pain, fever, and inflammation. It\'s commonly used for headaches, muscle pain, arthritis, and menstrual cramps. Side effects may include stomach pain, heartburn, and increased risk of heart attack and stroke with long-term use.');
      return;
    } else {
      await _simulateResponse(
          'I am currently in test mode with limited medication information. This test message is to verify that text-to-speech is working properly. Please try asking about common medications like aspirin or ibuprofen.');
    }
  }

  // Handle real API calls for native platforms
  Future<void> _handleApiCall(String message) async {
    // Convert message history to Anthropic format
    final List<Map<String, String>> messageHistory = [];
    for (var msg in _messages) {
      if (msg['role'] == 'user') {
        messageHistory.add({'role': 'user', 'content': msg['content'] ?? ''});
      } else if (msg['role'] == 'assistant') {
        messageHistory
            .add({'role': 'assistant', 'content': msg['content'] ?? ''});
      }
    }

    // System prompt for Claude
    final systemPrompt =
        'You are Zira AI, a drug assistant. You only provide information related to drug medications, including uses, dosages, side effects, and interactions. You must not answer any questions or provide information unrelated to drug medications.';

    final apiKey = ApiKeys.anthropicApiKey;
    debugPrint(
        'API Key being used (first 5 chars): ${apiKey.substring(0, math.min(5, apiKey.length))}...');
    debugPrint('Message history length: ${messageHistory.length}');
    debugPrint('Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}');

    // Call Claude API (only reached on native platforms)
    final apiUrl = 'https://api.anthropic.com/v1/messages';
    debugPrint('Calling API: $apiUrl');

    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'Accept': 'application/json',
    };

    final body = {
      'model': 'claude-3-haiku-20240307',
      'max_tokens': 1000,
      'system': systemPrompt,
      'messages': messageHistory,
    };

    debugPrint('Sending API request...');
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    debugPrint('API response status code: ${response.statusCode}');
    debugPrint(
        'API response body: ${response.body.substring(0, math.min<int>(200, response.body.length))}');

    if (response.statusCode == 200) {
      debugPrint('API call successful!');
      final data = jsonDecode(response.body);

      // Handle different response formats
      String reply;
      try {
        if (data['content'] != null &&
            data['content'] is List &&
            data['content'].isNotEmpty) {
          reply = data['content'][0]['text'];
        } else if (data['completion'] != null) {
          // Handle alternate response format
          reply = data['completion'];
        } else if (data['response'] != null) {
          // Another possible format
          reply = data['response'];
        } else {
          // Generic fallback
          reply = data.toString();
          debugPrint('Unexpected response format: $reply');
          reply =
              'I received a response but couldn\'t parse it correctly. Please try again.';
        }
      } catch (e) {
        debugPrint('Error parsing response: $e');
        reply =
            'I received a response but encountered an error parsing it. Please try again.';
      }

      debugPrint(
          'Response received: ${reply.substring(0, math.min<int>(50, reply.length))}...');

      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'content': reply});
        _hasError = false;
        _errorMessage = '';
      });

      _logState('AI Response Received');
      _scrollToBottom();

      // Speak reply if AI speech is enabled (regardless of input mode)
      if (_isAISpeechEnabled) {
        debugPrint('Speaking API response');
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _speak(reply);
          }
        });
      } else {
        debugPrint('Not speaking API response - AI speech disabled');
      }
    } else {
      debugPrint('API Error: ${response.body}');
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'assistant',
          'content':
              'Sorry, I encountered an error. Please try again later. (Error ${response.statusCode})'
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Slight delay to ensure the list is updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          math.max<double>(_scrollController.position.maxScrollExtent, 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    _speech.cancel();
    super.dispose();
  }

  // Initialize speech recognition with proper permission handling
  Future<void> _initializeSpeechRecognition() async {
    debugPrint('Initializing speech recognition...');

    // Request microphone permission
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        setState(() {
          _hasError = true;
          _errorMessage = 'Microphone permission is required for voice input';
        });
        return;
      }
    }

    // Initialize the speech recognition engine
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint('Speech recognition status: $status');
        if (status == 'done' && _isListening) {
          // Stop listening when speech is done
          _stopListening();
        }
      },
      onError: (error) {
        debugPrint('Speech recognition error: $error');
        setState(() {
          _isListening = false;
          _conversationState = ConversationState.idle;
        });
      },
    );

    if (!available) {
      debugPrint('Speech recognition not available');
      setState(() {
        _hasError = true;
        _errorMessage = 'Speech recognition is not available on this device';
      });
    }
  }

  // Start listening for speech input
  void _startListening() async {
    debugPrint('Starting speech recognition...');

    if (!_speech.isAvailable) {
      debugPrint('Speech recognition not available');
      return;
    }

    // Clear any previous errors before starting
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _conversationState = ConversationState.user_talking;
      _isListening = true;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final recognizedText = result.recognizedWords;
            debugPrint('Speech recognized: $recognizedText');

            if (recognizedText.isNotEmpty) {
              // Process the recognized speech
              _sendMessage(recognizedText);
            }

            setState(() {
              _isListening = false;
              _conversationState = ConversationState.idle;
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: 'en_US',
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
        _conversationState = ConversationState.idle;
        _hasError = true;
        _errorMessage = 'Failed to start speech recognition: $e';
      });
    }
  }

  // Stop listening for speech input
  void _stopListening() {
    debugPrint('Stopping speech recognition...');

    _speech.stop();

    setState(() {
      _isListening = false;
      _conversationState = ConversationState.idle;
    });
  }

  // Speak text using TTS
  Future<void> _speak(String text) async {
    debugPrint('Speaking: ${text.substring(0, math.min(50, text.length))}...');

    if (!_isAISpeechEnabled) {
      debugPrint('AI speech is disabled, not speaking');
      return;
    }

    // Stop any ongoing speech first
    await _flutterTts.stop();

    setState(() {
      _conversationState = ConversationState.ai_talking;
    });

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
      setState(() {
        _conversationState = ConversationState.idle;
      });
    }
  }

  // Simulate an AI response for testing/demo purposes
  Future<void> _simulateResponse(String responseText) async {
    // Add small delay to simulate thinking
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _messages.add({'role': 'assistant', 'content': responseText});
    });

    _scrollToBottom();

    // Speak the response if AI speech is enabled
    if (_isAISpeechEnabled) {
      _speak(responseText);
    }
  }

  // Log current app state for debugging
  void _logState(String action) {
    debugPrint('=== STATE CHANGE: $action ===');
    debugPrint('Conversation state: $_conversationState');
    debugPrint('Voice mode active: $_isVoiceModeActive');
    debugPrint('Listening: $_isListening');
    debugPrint('AI speech enabled: $_isAISpeechEnabled');
    debugPrint('Loading: $_isLoading');
    debugPrint('Web demo mode: $_isWebDemoMode');
    debugPrint('Has error: $_hasError');
    debugPrint('Messages count: ${_messages.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zira AI'),
        actions: [
          // Voice/text toggle
          IconButton(
            icon: Icon(_isVoiceModeActive
                ? FontAwesomeIcons.keyboard
                : FontAwesomeIcons.microphone),
            onPressed: _toggleInputMode,
          ),
          // Speaker toggle
          IconButton(
            icon: Icon(_isAISpeechEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleAISpeech,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('About Zira AI'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Zira is your AI drug assistant.'),
                          SizedBox(height: 8),
                          Text('• Ask about medications and their uses'),
                          Text('• Get information about side effects'),
                          Text('• Learn about drug interactions'),
                          Text('• Understand proper dosages'),
                          SizedBox(height: 8),
                          Text(
                              'Zira only answers questions related to medications.'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Close'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleInputMode,
        tooltip:
            _isVoiceModeActive ? 'Switch to text mode' : 'Switch to voice mode',
        child: Icon(_isVoiceModeActive
            ? FontAwesomeIcons.keyboard
            : FontAwesomeIcons.microphone),
      ),
      body: Column(
        children: [
          // Error banner (NEVER shown in web mode)
          if (_hasError && !kIsWeb)
            Container(
              color: Colors.red,
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              width: double.infinity,
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),

          // Message list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FontAwesomeIcons.pills,
                          size: 64,
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask Zira about medications',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_isWebDemoMode)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32.0, vertical: 16.0),
                            child: Text(
                              'Web Demo Mode: Limited functionality due to browser CORS restrictions',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            message['content'] ?? '',
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text('Zira is thinking...',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),

          // Input area
          if (!_isVoiceModeActive)
            // Text Mode UI
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        if (_inputController.text.trim().isNotEmpty &&
                            (_conversationState == ConversationState.idle ||
                                _conversationState ==
                                    ConversationState.user_typing)) {
                          _sendMessage(_inputController.text.trim());
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            // Voice Mode UI
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    _conversationState == ConversationState.ai_talking
                        ? Icons.smart_toy
                        : Icons.mic,
                    size: 30,
                    color: _conversationState == ConversationState.ai_talking
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _conversationState == ConversationState.user_talking
                        ? "Recording... Tap mic to stop"
                        : _conversationState == ConversationState.ai_talking
                            ? "AI is talking"
                            : "Tap the mic icon to start",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: Icon(
                        _conversationState == ConversationState.ai_talking
                            ? Icons.smart_toy
                            : _isListening
                                ? Icons.mic_off
                                : Icons.mic,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (_conversationState ==
                                ConversationState.user_talking &&
                            _isListening) {
                          _stopListening();
                        } else if (_conversationState ==
                            ConversationState.idle) {
                          _startListening();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
