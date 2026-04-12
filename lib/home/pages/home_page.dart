import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/brahma/pages/brahma_create_page.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/vishnu/bloc/vishnu_feed_bloc.dart';
import 'package:uniun/vishnu/pages/vishnu_feed_page.dart';
import 'package:uniun/shiv/pages/shiv_page.dart';

/// App shell — standard Flutter Scaffold + Drawer + floating pill nav.
///   0 = Vishnu (feed)
///   1 = Brahma (create note)
///   2 = Shiv   (AI assistant)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final VishnuFeedBloc _vishnuFeedBloc;
  late final FollowedNotesCubit _followedNotesCubit;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _vishnuFeedBloc = getIt<VishnuFeedBloc>()..add(const LoadFeedEvent());
    _followedNotesCubit = getIt<FollowedNotesCubit>()..load();
  }

  @override
  void dispose() {
    _vishnuFeedBloc.close();
    _followedNotesCubit.close();
    super.dispose();
  }

  Future<void> _switchTab(int i) async {
    if (i == 0 && _currentIndex != 0) {
      _vishnuFeedBloc.add(const RefreshFeedEvent());
    }
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VishnuFeedBloc>.value(value: _vishnuFeedBloc),
        BlocProvider<FollowedNotesCubit>.value(value: _followedNotesCubit),
      ],
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLowest,
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            VishnuFeedPage(
              currentIndex: _currentIndex,
              onSwitchTab: _switchTab,
            ),
            BrahmaCreatePage(
              currentIndex: _currentIndex,
              onSwitchTab: _switchTab,
              onPublished: () => _switchTab(0),
            ),
            ShivPage(
              currentIndex: _currentIndex,
              onSwitchTab: _switchTab,
            ),
          ],
        ),
      ),
    );
  }
}
