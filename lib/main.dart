import 'dart:async';
import 'dart:developer' as dev;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud_test/audio/cubit/audio_controller_cubit.dart';
import 'package:flutter_soloud_test/audio/data/audio_repository.dart';
import 'package:flutter_soloud_test/audio/model/sfx.dart';

final Completer<void> _mobileAdsInitialized = Completer<void>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  MobileAds.instance.initialize().then((_) => _mobileAdsInitialized.complete());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SoLoud Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BlocProvider(
        create: (context) =>
            AudioControllerCubit(audioRepository: AudioRepository()),
        child: const _MyHomePage(),
      ),
    );
  }
}

class _MyHomePage extends StatelessWidget {
  static final _log = Logger('MyHomePage');

  const _MyHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter SoLoud Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Music'),
                const SizedBox(width: 10),
                Switch(
                  value: context.watch<AudioControllerCubit>().state.musicOn,
                  onChanged: (bool value) =>
                      context.read<AudioControllerCubit>().setMusicOn(value),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sounds (sfx)'),
                const SizedBox(width: 10),
                Switch(
                  value: context.watch<AudioControllerCubit>().state.soundsOn,
                  onChanged: (bool value) =>
                      context.read<AudioControllerCubit>().setSoundsOn(value),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () =>
                  context.read<AudioControllerCubit>().playSfx(Sfx.meleeAttack),
              child: const Text('Play Sfx'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _showAd,
              child: const Text('Show Admob Rewarded Ad'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAd() async {
    await _mobileAdsInitialized.future;
    await RewardedAd.load(
      adUnitId: "ca-app-pub-3940256099942544/1712485313",
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _log.info('Ad was loaded.');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _log.info('Ad showed full screen content.');
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              _log.severe(
                'Ad failed to show full screen content with error: $err',
              );
              ad.dispose();
            },
            onAdDismissedFullScreenContent: (ad) {
              _log.info('Ad was dismissed.');
              ad.dispose();
            },
            onAdImpression: (ad) {
              _log.info('Ad recorded an impression.');
            },
            onAdClicked: (ad) {
              _log.info('Ad was clicked.');
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
              _log.info('Reward amount: ${rewardItem.amount}');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _log.severe('Ad failed to load with error: $error');
        },
      ),
    );
  }
}
