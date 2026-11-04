abstract final class AppRoutes {
  static const home = '/';
  static const homeName = 'login';
  static const foundation = '/foundation';
  static const interests = '/interests';
  static const discover = '/discover';
  static const guestDiscover = '/discover/guest';
  static const explore = '/explore';
  static const searchResults = '/explore/results';
  static const filters = '/filters';
  static const followingEvents = '/following/events';
  static const followingOrganizers = '/following/organizers';

  // TODO(Lab 3): Register protected paths together with real auth flows.
  static const protectedPaths = <String>{};
}
