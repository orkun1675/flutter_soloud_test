import 'dart:developer' as dev;
import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud_test/audio/cubit/audio_controller_cubit.dart';
import 'package:flutter_soloud_test/audio/data/audio_repository.dart';
import 'package:flutter_soloud_test/audio/model/sfx.dart';

void main() {
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
          ],
        ),
      ),
    );
  }
}
