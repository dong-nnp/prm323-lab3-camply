abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const homeName = 'welcome';
  static const login = '/login';
  static const signUp = '/signup';
  static const foundation = '/foundation';
  static const interests = '/interests';
  static const discover = '/discover';
  static const guestDiscover = '/discover/guest';
  static const explore = '/explore';
  static const searchResults = '/explore/results';
  static const filters = '/filters';
  static const followingEvents = '/following/events';
  static const followingOrganizers = '/following/organizers';

  static const protectedPaths = <String>{
    '/rewards/confirm',
    '/rewards/success',
    '/rewards/voucher',
    '/rewards/locker',
  };
  static bool requiresAuthentication(String path) =>
      protectedPaths.contains(path) ||
      [
        '/registration',
        '/my-events',
        '/profile',
        '/following',
      ].any((prefix) => path == prefix || path.startsWith('$prefix/'));
}
