
import '../../ui/tokens/palette.dart';

/// Legacy palette facade. Every member is deprecated: screens migrate to
/// `context.colors.<role>` (see `lib/ui/tokens/tokens.dart`). Values are the
/// light-theme Utsav tokens so un-migrated screens already wear the identity;
/// they are NOT dark-mode aware, which is why migration is still required.
class AppColors {
  AppColors._();

  static const _d = 'Use context.colors.<role> from lib/ui/tokens/tokens.dart';

  @Deprecated(_d) static const paper = Palette.ivory100;
  @Deprecated(_d) static const kraft = Palette.ivory200;
  @Deprecated(_d) static const kraft2 = Palette.ivory300;
  @Deprecated(_d) static const cardLight = Palette.white;

  @Deprecated(_d) static const paperDark = Palette.night900;
  @Deprecated(_d) static const kraftDark = Palette.night800;
  @Deprecated(_d) static const kraft2Dark = Palette.night700;
  @Deprecated(_d) static const cardDark = Palette.night800;

  @Deprecated(_d) static const inkLight = Palette.plum900;
  @Deprecated(_d) static const inkSoftLight = Palette.plum700;
  @Deprecated(_d) static const inkFaintLight = Palette.plum500;
  @Deprecated(_d) static const inkDark = Palette.cream100;
  @Deprecated(_d) static const inkSoftDark = Palette.cream300;
  @Deprecated(_d) static const inkFaintDark = Palette.cream500;

  @Deprecated(_d) static const terracotta = Palette.vermilion500;
  @Deprecated(_d) static const terracottaDark = Palette.vermilion600;
  @Deprecated(_d) static const terracottaBright = Palette.vermilion300;
  @Deprecated(_d) static const gold = Palette.marigold600;
  @Deprecated(_d) static const goldBright = Palette.marigold500;

  @Deprecated(_d) static const dharmaPurple = Palette.violet500;
  @Deprecated(_d) static const deityRose = Palette.magenta500;
  @Deprecated(_d) static const sacredGreen = Palette.tulsi500;
}
