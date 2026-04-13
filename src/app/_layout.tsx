// ============================================================
// SUPER RESERVATION PLATFORM — Root Layout
// - Forces RTL layout (Arabic-first)
// - Loads Cairo font (Arabic) + Inter (Latin)
// - Initializes auth state
// - Guards authenticated routes
// ============================================================

import { useEffect } from 'react';
import { I18nManager, Platform } from 'react-native';
import { Stack, useRouter, useSegments } from 'expo-router';
import { useFonts } from 'expo-font';
import * as SplashScreen from 'expo-splash-screen';
import * as Notifications from 'expo-notifications';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAuthStore } from '../store/auth';
import { useLanguageStore } from '../store/language';
import { usersApi } from '../services/api';

// Configure how notifications appear when the app is in the foreground
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

async function registerForPushNotifications(): Promise<void> {
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
    });
  }

  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') return; // User declined — no token to register

  const tokenData = await Notifications.getExpoPushTokenAsync();
  await usersApi.registerPushToken(tokenData.data).catch(() => {
    // Non-fatal — push will just be unavailable until next app open
  });
}

// Force RTL for Arabic-first experience
I18nManager.allowRTL(true);
I18nManager.forceRTL(true);

SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 2 * 60 * 1000,   // 2 minutes
      gcTime: 10 * 60 * 1000,     // 10 minutes
      retry: 2,
    },
  },
});

function AuthGuard({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading } = useAuthStore();
  const segments = useSegments();
  const router = useRouter();

  useEffect(() => {
    if (isLoading) return;

    const inAuthGroup = segments[0] === '(auth)';

    if (!isAuthenticated && !inAuthGroup) {
      router.replace('/(auth)/login');
    } else if (isAuthenticated && inAuthGroup) {
      router.replace('/(tabs)');
    }
  }, [isAuthenticated, isLoading, segments]);

  return <>{children}</>;
}

export default function RootLayout() {
  const initialize = useAuthStore((s) => s.initialize);
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const initLang = useLanguageStore((s) => s.initialize);

  const [fontsLoaded] = useFonts({
    'Cairo-Regular': require('../../assets/fonts/Cairo/static/Cairo-Regular.ttf'),
    'Cairo-Medium': require('../../assets/fonts/Cairo/static/Cairo-Medium.ttf'),
    'Cairo-SemiBold': require('../../assets/fonts/Cairo/static/Cairo-SemiBold.ttf'),
    'Cairo-Bold': require('../../assets/fonts/Cairo/static/Cairo-Bold.ttf'),
    'Inter-Regular': require('../../assets/fonts/Inter/static/Inter_18pt-Regular.ttf'),
    'Inter-Medium': require('../../assets/fonts/Inter/static/Inter_18pt-Medium.ttf'),
    'Inter-SemiBold': require('../../assets/fonts/Inter/static/Inter_18pt-SemiBold.ttf'),
  });

  useEffect(() => {
    initialize();
    initLang();
  }, []);

  useEffect(() => {
    if (isAuthenticated) {
      registerForPushNotifications();
    }
  }, [isAuthenticated]);

  useEffect(() => {
    if (fontsLoaded) {
      SplashScreen.hideAsync();
    }
  }, [fontsLoaded]);

  if (!fontsLoaded) return null;

  return (
    <QueryClientProvider client={queryClient}>
      <AuthGuard>
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Screen name="(auth)" />
          <Stack.Screen name="(tabs)" />
          <Stack.Screen name="search" options={{ presentation: 'card' }} />
          <Stack.Screen name="business/[id]/index" options={{ presentation: 'card' }} />
          <Stack.Screen name="booking/checkout" options={{ presentation: 'modal' }} />
          <Stack.Screen name="booking/payment" options={{ presentation: 'modal' }} />
          <Stack.Screen name="booking/confirmed" options={{ presentation: 'card', gestureEnabled: false }} />
          <Stack.Screen name="bookings/[id]/index" options={{ presentation: 'card' }} />
        </Stack>
      </AuthGuard>
    </QueryClientProvider>
  );
}
