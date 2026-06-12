// ignore_file: file_names

import 'package:flutter/material.dart';

import '../widgets/ChatNavigationRail.dart';
import '../widgets/ChatListPanel.dart';
import '../widgets/MainChatArea.dart';
import '../widgets/WelcomeScreen.dart';
import '../../settings/SettingsScreen.dart';
import '../../contacts/ContactsScreen.dart';
import '../../timeline/TimelineScreen.dart';
import '../../notifications/NotificationsScreen.dart';
import '../../profile/ProfileController.dart';
import '../../../core/theme/theme_controller.dart';
import '../../settings/settings_controller.dart';
import '../../auth/AuthController.dart';
import '../../profile/FriendProfileScreen.dart';
import '../../contacts/ContactsController.dart';
import '../../../core/services/signalr_service.dart';
import '../../call/CallScreen.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, dynamic>?> _searchedUser = ValueNotifier(null);
  final ValueNotifier<Map<String, dynamic>?> _activeChatUser = ValueNotifier(null);

  final ContactsController _globalContactsController = ContactsController();
  final SignalRService _signalR = SignalRService();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _loadUserTheme();

    _signalR.startConnection().then((_) {
      _signalR.webRTCSignal.addListener(_globalCallListener);
    });

    _pages = [
      _buildChatTab(),
      ContactsScreen(
        controller: _globalContactsController,
        onStartChat: (String userId) {
          _activeChatUser.value = {
            'id': userId,
            'name': 'Người dùng',
            'avatarUrl': '',
            'bio': '',
          };

          _searchedUser.value = null;
          _selectedIndex.value = 0;
        },
      ),
      const TimelineScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];
  }

  // Lắng nghe tín hiệu cuộc gọi đến từ SignalR và mở màn hình nhận cuộc gọi
  void _globalCallListener() {
    final msg = _signalR.webRTCSignal.value;

    if (msg == null) {
      return;
    }

    final type = (msg['type'] ?? '').toString();
    final content = (msg['content'] ?? '').toString();
    final conversationId = (msg['conversationId'] ?? '').toString();

    final callerName = (msg['callerName'] ?? 'Người gọi').toString();

    String callerAvatar = (msg['callerAvatar'] ?? '').toString();

    if (callerAvatar.isEmpty || callerAvatar == 'null') {
      callerAvatar = "https://i.pravatar.cc/150";
    }

    AuthController().getCurrentUserId().then((currentUserId) {
      if (type == 'offer_video' || type == 'offer_voice') {
        final isVideo = type == 'offer_video';

        globalNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              isVideoCall: isVideo,
              userName: callerName,
              avatarUrl: callerAvatar,
              conversationId: conversationId,
              isCaller: false,
              initialOfferPayload: content,
              onCallEndedLog: (callType, logContent) {
                _signalR.sendMessage(conversationId, logContent, callType);
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    _searchedUser.dispose();
    _activeChatUser.dispose();
    _globalContactsController.dispose();

    _signalR.webRTCSignal.removeListener(_globalCallListener);

    super.dispose();
  }

  // Tải theme, setting và profile của người dùng hiện tại
  Future<void> _loadUserTheme() async {
    final authController = AuthController();
    final settingsController = SettingsController();

    String userId = await authController.getCurrentUserId();

    await settingsController.loadSettingsForUser(userId);

    themeController.changePrimaryColor(
      Color(settingsController.primaryColorValue),
    );
    themeController.toggleDarkMode(settingsController.isDarkMode);

    await ProfileController().loadUserProfile(userId);
  }

  // Tạo tab chat gồm danh sách chat bên trái và vùng nội dung bên phải
  Widget _buildChatTab() {
    return ListenableBuilder(
      listenable: Listenable.merge([_searchedUser, _activeChatUser]),
      builder: (context, _) {
        final searchedUser = _searchedUser.value;
        final activeChatUser = _activeChatUser.value;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: ChatListPanel(
                controller: _globalContactsController,
                onChatSelected: (userMap) {
                  _activeChatUser.value = userMap;
                  _searchedUser.value = null;
                },
                onGlobalSearchFound: (user) {
                  _searchedUser.value = user;
                  _activeChatUser.value = null;
                },
              ),
            ),
            Expanded(
              child: searchedUser != null
                  ? FriendProfileScreen(
                      key: ValueKey('profile_${searchedUser['id']}'),
                      userId: searchedUser['id'],
                      userName: searchedUser['fullName'] ?? 'Người dùng',
                      avatarUrl: searchedUser['avatarUrl'] ?? '',
                      coverImageUrl: searchedUser['coverUrl'] ?? '',
                      bio: searchedUser['bio'] ?? '',
                      initialRelationStatus:
                          searchedUser['relationStatus'] ?? 'none',
                      contactController: _globalContactsController,
                    )
                  : activeChatUser != null
                      ? MainChatArea(
                          key: ValueKey('chat_${activeChatUser['id']}'),
                          chatId: activeChatUser['id'],
                          chatName: activeChatUser['fullName'] ??
                              activeChatUser['name'] ??
                              'Người dùng',
                          chatAvatar: activeChatUser['avatarUrl'] ??
                              activeChatUser['groupAvatarUrl'] ??
                              '',
                          chatCover: activeChatUser['coverUrl'] ?? '',
                          chatBio: activeChatUser['bio'] ?? '',
                          relationStatus:
                              activeChatUser['relationStatus'] ?? 'friend',
                          isGroup: activeChatUser['isGroup'] ?? false,
                        )
                      : const WelcomeScreen(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: globalNavigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _selectedIndex,
                  builder: (context, index, child) {
                    return ChatNavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: (int newIndex) {
                        if (_selectedIndex.value == newIndex) {
                          return;
                        }

                        _selectedIndex.value = newIndex;
                      },
                    );
                  },
                ),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _selectedIndex,
                    builder: (context, index, child) {
                      return _SmoothIndexedStack(
                        index: index,
                        children: _pages,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Giữ state các tab và tạo hiệu ứng chuyển trang mượt
class _SmoothIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _SmoothIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<_SmoothIndexedStack> createState() => _SmoothIndexedStackState();
}

class _SmoothIndexedStackState extends State<_SmoothIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _fadeOutAnimation;
  late final Animation<Offset> _slideInAnimation;

  int? _previousIndex;
  late int _currentIndex;
  bool _isAnimating = false;

  static const _fullOpacity = AlwaysStoppedAnimation<double>(1.0);
  static const _zeroOpacity = AlwaysStoppedAnimation<double>(0.0);
  static const _zeroOffset = AlwaysStoppedAnimation<Offset>(Offset.zero);

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.index;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideInAnimation = Tween<Offset>(
      begin: const Offset(0.02, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.value = 1.0;

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _previousIndex = null;
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SmoothIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.index != _currentIndex) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = widget.index;
        _isAnimating = true;
      });

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (index) {
        final bool isCurrent = index == _currentIndex;
        final bool isPrevious = index == _previousIndex;
        final bool isActive = isCurrent || isPrevious;

        Animation<double> opacity;
        Animation<Offset> offset;

        if (_isAnimating) {
          if (isCurrent) {
            opacity = _fadeInAnimation;
            offset = _slideInAnimation;
          } else if (isPrevious) {
            opacity = _fadeOutAnimation;
            offset = _zeroOffset;
          } else {
            opacity = _zeroOpacity;
            offset = _zeroOffset;
          }
        } else {
          opacity = isCurrent ? _fullOpacity : _zeroOpacity;
          offset = _zeroOffset;
        }

        return Offstage(
          offstage: !isActive,
          child: IgnorePointer(
            ignoring: !isCurrent,
            child: TickerMode(
              enabled: isCurrent,
              child: FadeTransition(
                opacity: opacity,
                child: SlideTransition(
                  position: offset,
                  child: RepaintBoundary(
                    child: widget.children[index],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}