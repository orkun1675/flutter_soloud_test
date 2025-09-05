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

  Logger.root.level = Level.ALL;
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

class _MyHomePage extends StatefulWidget {
  const _MyHomePage();

  @override
  State<_MyHomePage> createState() => _MyHomePageState();
}

enum AudioBugWorkaround { none, reInitSoLoud, resetAudioSession }

class _MyHomePageState extends State<_MyHomePage> {
  static final _log = Logger('MyHomePage');

  AudioBugWorkaround _audioHandling = AudioBugWorkaround.none;

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
            const SizedBox(height: 70),
            ElevatedButton(
              onPressed: _showAd,
              child: const Text('Show Admob Rewarded Ad'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Re-init SoLoud after Ad view'),
                const SizedBox(width: 10),
                Switch(
                  value: _audioHandling == AudioBugWorkaround.reInitSoLoud,
                  onChanged: (bool value) => setState(
                    () => _audioHandling = value
                        ? AudioBugWorkaround.reInitSoLoud
                        : AudioBugWorkaround.none,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Reset Audio Session after Ad view'),
                const SizedBox(width: 10),
                Switch(
                  value: _audioHandling == AudioBugWorkaround.resetAudioSession,
                  onChanged: (bool value) => setState(
                    () => _audioHandling = value
                        ? AudioBugWorkaround.resetAudioSession
                        : AudioBugWorkaround.none,
                  ),
                ),
              ],
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
        onAdLoaded: (RewardedAd ad) async {
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
            onAdDismissedFullScreenContent: (ad) async {
              _log.info('Ad was dismissed.');
              ad.dispose();
              switch (_audioHandling) {
                case AudioBugWorkaround.none:
                  break;
                case AudioBugWorkaround.reInitSoLoud:
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!mounted) return;
                  await context.read<AudioControllerCubit>().reinit();
                  _log.info('SoLoud re-initialized.');
                  break;
                case AudioBugWorkaround.resetAudioSession:
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!mounted) return;
                  await context
                      .read<AudioControllerCubit>()
                      .resumeAudioSession();
                  _log.info('Audio session resumed.');
                  break;
              }
            },
            onAdImpression: (ad) {
              _log.info('Ad recorded an impression.');
            },
            onAdClicked: (ad) {
              _log.info('Ad was clicked.');
            },
          );

          if (_audioHandling == AudioBugWorkaround.resetAudioSession) {
            await context.read<AudioControllerCubit>().stopAudioSession();
            _log.info('Audio session stopped.');
          }

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
