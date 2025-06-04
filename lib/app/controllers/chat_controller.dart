import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/chat_models.dart';
import '../services/chat_service.dart';
import 'login_controller.dart';
import '../config/app_config.dart';

typedef StompUnsubscribe = void Function({Map<String, String>? unsubscribeHeaders});

class ChatController extends GetxController {
  final ChatService _chatService = Get.find<ChatService>();
  final LoginController _loginController = Get.find<LoginController>();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isFetchingMore = false.obs;
  final RxBool hasReachedMax = false.obs;
  final RxString errorMessage = ''.obs;
  final ScrollController scrollController = ScrollController();
  final TextEditingController messageInputController = TextEditingController();

  late String _chatPartnerUid;
  String? _chatPartnerNickname;
  String get chatPartnerNickname => _chatPartnerNickname ?? '상대방';

  StompClient? stompClient;
  StompUnsubscribe? _stompSubscription;


  ChatController({required String partnerUid, String? partnerNickname}) {
    _chatPartnerUid = partnerUid;
    _chatPartnerNickname = partnerNickname;
  }


  @override
  void onInit() {
    super.onInit();
    _initializeChat();
    scrollController.addListener(_scrollListener);
  }

  void _initializeChat() {
    if (_loginController.user.id == null || _chatPartnerUid.isEmpty) {
      errorMessage.value = "채팅 상대방 정보가 유효하지 않습니다.";
      isLoading.value = false;
      return;
    }
    fetchInitialMessages();
    _connectToStomp();
  }

  String get _currentUserUid => _loginController.user.id!;

  void _connectToStomp() {
    final String? baseApiUrl = AppConfig.apiUrl;
    if (baseApiUrl == null) {
      errorMessage.value = "STOMP 연결을 위한 API URL을 찾을 수 없습니다.";
      return;
    }

    String stompUrl = baseApiUrl.replaceFirst(RegExp(r'^http'), 'ws') + "/ws";

    if (kDebugMode) {
      print('[ChatController] Attempting to connect to STOMP: $stompUrl');
    }

    final String? token = _loginController.user.safeAccessToken;
    if (token == null) {
      errorMessage.value = "STOMP 연결을 위한 인증 토큰이 없습니다.";
      return;
    }

    stompClient = StompClient(
      config: StompConfig(
        url: stompUrl,
        onConnect: _onStompConnected,
        onWebSocketError: (dynamic error) {
          if (kDebugMode) {
            print('[ChatController] STOMP WebSocket Error: $error');
          }
          errorMessage.value = '채팅 서버 연결 오류: ${error.toString()}';
        },
        onStompError: (StompFrame frame) {
          if (kDebugMode) {
            print('[ChatController] STOMP Error: ${frame.body}');
          }
          errorMessage.value = '채팅 프로토콜 오류: ${frame.body}';
        },
        onDisconnect: (StompFrame frame) {
          if (kDebugMode) {
            print('[ChatController] STOMP Disconnected.');
          }
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );

    try {
      stompClient?.activate();
    } catch (e) {
      if (kDebugMode) {
        print('[ChatController] STOMP activation error: $e');
      }
      errorMessage.value = "STOMP 클라이언트 활성화 중 오류가 발생했습니다.";
    }
  }

  void _onStompConnected(StompFrame frame) {
    if (kDebugMode) {
      print('[ChatController] STOMP Connected.');
    }
    // 백엔드 설명에 따르면 수신자와 발신자 모두 개인 큐로 메시지를 받습니다.
    // 이 경로는 Spring STOMP에서 '/user/queue/private'와 같이 사용될 때,
    // 현재 인증된 사용자의 고유 세션에 매핑되는 개인 큐를 의미합니다.
    final String subscriptionDestination = '/user/queue/private';

    _stompSubscription = stompClient?.subscribe(
      destination: subscriptionDestination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          if (kDebugMode) {
            print('[ChatController] STOMP Message Received: ${frame.body}');
          }
          try {
            final Map<String, dynamic> jsonMessage = json.decode(frame.body!);
            final ChatMessage receivedMessage = ChatMessage.fromJson(jsonMessage);

            // 수신된 메시지가 현재 채팅방과 관련된 메시지인지 확인
            // (내가 보낸 메시지의 에코이거나, 상대방이 나에게 보낸 메시지여야 함)
            bool isMyEchoMessage = receivedMessage.senderUid == _currentUserUid &&
                receivedMessage.receiverUid == _chatPartnerUid;
            bool isPartnerOriginatedMessage = receivedMessage.senderUid == _chatPartnerUid &&
                receivedMessage.receiverUid == _currentUserUid;

            if (isMyEchoMessage || isPartnerOriginatedMessage) {
              // 서버에서 ID가 부여된 메시지이므로, ID 기반으로 중복 체크
              if (receivedMessage.id != null && !messages.any((m) => m.id == receivedMessage.id)) {
                messages.insert(0, receivedMessage); // 새 메시지를 맨 앞에 추가 (UI는 역순)
                messages.refresh();
                if (kDebugMode) {
                  print('[ChatController] Added message to UI: ${receivedMessage.id}');
                }
                // TODO: 상대방이 보낸 메시지이고, 현재 채팅창이 활성화되어 있다면 읽음 처리 로직 추가
              } else if (receivedMessage.id == null && kDebugMode) {
                // 서버에서 받은 메시지에 ID가 없는 경우 (비정상적이지만 로그로 남김)
                print('[ChatController] Warning: Received STOMP message without an ID. Message: $receivedMessage');
                // ID가 없는 메시지를 임시로 추가할지 여부 결정 (보통은 ID가 있어야 함)
                // messages.insert(0, receivedMessage);
                // messages.refresh();
              } else if (messages.any((m) => m.id == receivedMessage.id)) {
                if (kDebugMode) {
                  print('[ChatController] Duplicate message received or already processed (ID: ${receivedMessage.id}). Skipping add.');
                }
              }
            } else {
              if (kDebugMode) {
                print('[ChatController] Irrelevant message received. CurrentUser: $_currentUserUid, Partner: $_chatPartnerUid, Received: ${receivedMessage.senderUid} -> ${receivedMessage.receiverUid}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('[ChatController] Error processing STOMP message: $e');
              print('[ChatController] Received raw STOMP message body: ${frame.body}');
            }
          }
        }
      },
    );
  }


  Future<void> fetchInitialMessages() async {
    if (_chatPartnerUid.isEmpty) {
      errorMessage.value = "상대방 정보가 없어 메시지를 조회할 수 없습니다.";
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';
    hasReachedMax.value = false;
    try {
      final response = await _chatService.getChatMessages(
          otherUserUid: _chatPartnerUid, size: 20);
      messages.assignAll(response.messages.reversed.toList());
      hasReachedMax.value = !response.hasNextPage;
      if (kDebugMode && messages.isNotEmpty) {
        print('[ChatController] Fetched initial ${messages.length} messages. Oldest: ${messages.first.timestamp}, Newest: ${messages.last.timestamp}');
      }
    } catch (e) {
      errorMessage.value = "메시지 로딩 중 오류: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMoreMessages() async {
    if (isFetchingMore.value || hasReachedMax.value || messages.isEmpty) return;

    isFetchingMore.value = true;
    try {
      final lastTimestamp = messages.first.timestamp;
      final response = await _chatService.getChatMessages(
        otherUserUid: _chatPartnerUid,
        beforeTimestamp: lastTimestamp,
        size: 20,
      );
      if (response.messages.isNotEmpty) {
        messages.insertAll(0, response.messages.reversed.toList());
        if (kDebugMode) {
          print('[ChatController] Fetched ${response.messages.length} more messages. Oldest in current batch: ${response.messages.last.timestamp}');
        }
      }
      hasReachedMax.value = !response.hasNextPage;
      if (kDebugMode && hasReachedMax.value) {
        print('[ChatController] Reached end of message history.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatController] Fetch more messages error: $e');
      }
    } finally {
      isFetchingMore.value = false;
    }
  }

  void sendMessage() {
    final String content = messageInputController.text.trim();
    if (content.isEmpty) {
      return;
    }
    if (stompClient == null || !stompClient!.connected) {
      Get.snackbar("전송 실패", "채팅 서버에 연결되어 있지 않습니다. 잠시 후 다시 시도해주세요.");
      if(stompClient?.isActive == false) {
        _connectToStomp();
      }
      return;
    }

    final currentUser = _loginController.user;
    if (currentUser.id == null ) {
      Get.snackbar("전송 실패", "사용자 정보를 찾을 수 없습니다. 앱을 재시작해주세요.");
      return;
    }

    // 서버로 전송할 메시지 페이로드 구성
    // 'timestamp'는 서버에서 최종적으로 설정하거나 클라이언트 시간을 참고할 수 있습니다.
    // 'id'는 서버에서 생성하므로 클라이언트에서는 보내지 않습니다.
    final messageToSendPayload = {
      'type': MessageType.CHAT.name, // 서버 ChatMessageDto의 type 필드와 일치해야 함
      'content': content,
      'senderUid': _currentUserUid,
      'receiverUid': _chatPartnerUid,
      // 'timestamp'를 보내는 것은 선택사항. 서버에서 생성하는 것이 일반적.
      // 필요하다면 클라이언트의 현재 시간을 참고용으로 보낼 수 있음.
      // 'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    if (kDebugMode) {
      print('[ChatController] Sending message payload: ${json.encode(messageToSendPayload)}');
    }

    try {
      stompClient?.send(
        destination: '/app/chat.sendMessage', // 서버의 STOMP 메시지 처리 엔드포인트
        body: json.encode(messageToSendPayload),
        headers: {'Authorization': 'Bearer ${_loginController.user.safeAccessToken}'},
      );
      messageInputController.clear();
      // 낙관적 UI 업데이트를 제거. 서버에서 보내주는 에코 메시지를 기다려서 UI에 반영.
    } catch (e) {
      if (kDebugMode) {
        print('[ChatController] Error sending STOMP message: $e');
      }
      Get.snackbar("전송 실패", "메시지 전송 중 오류가 발생했습니다.");
    }
  }

  void _scrollListener() {
    if (scrollController.position.pixels <= scrollController.position.minScrollExtent + 50 &&
        !isFetchingMore.value &&
        !hasReachedMax.value) {
      fetchMoreMessages();
    }
  }

  @override
  void onClose() {
    if (kDebugMode) {
      print('[ChatController] onClose called. Deactivating STOMP client and disposing resources.');
    }
    _stompSubscription?.call();
    _stompSubscription = null;

    if (stompClient?.connected == true) {
      stompClient?.deactivate();
    }
    stompClient = null;

    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    messageInputController.dispose();
    super.onClose();
  }
}