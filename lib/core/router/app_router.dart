import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/booking/checkout_screen.dart';
import '../../features/booking/confirmed_screen.dart';
import '../../features/booking/payment_screen.dart';
import '../../features/bookings/booking_detail_screen.dart';
import '../../features/bookings/my_bookings_screen.dart';
import '../../features/business/business_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/splash/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/otp',
      builder: (context, state) => OtpScreen(phone: state.extra as String? ?? ''),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/business/:id',
      builder: (context, state) => BusinessDetailScreen(businessId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/checkout/:businessId',
      builder: (context, state) => CheckoutScreen(businessId: state.pathParameters['businessId']!),
    ),
    GoRoute(
      path: '/payment/:bookingId',
      builder: (context, state) => PaymentScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: '/confirmed/:bookingId',
      builder: (context, state) => ConfirmedScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(path: '/bookings', builder: (context, state) => const MyBookingsScreen()),
    GoRoute(
      path: '/bookings/:id',
      builder: (context, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);
