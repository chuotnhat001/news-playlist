import 'package:integration_test/integration_test.dart';

import 'flows/browse_and_play_test.dart' as browse_and_play;
import 'flows/play_all_test.dart' as play_all;
import 'flows/player_controls_test.dart' as player_controls;
import 'flows/settings_test.dart' as settings;
import 'flows/resume_playback_test.dart' as resume;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  browse_and_play.main();
  play_all.main();
  player_controls.main();
  settings.main();
  resume.main();
}
