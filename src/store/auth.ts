// ============================================================
// SUPER RESERVATION PLATFORM — Auth Store (Zustand)
// Persists auth state. Manages login/logout lifecycle.
// Firebase Phone Auth + Google Sign-In.
// ============================================================

import { create } from 'zustand';
import { tokenStorage, authApi, usersApi } from '../services/api';

interface AuthUser {
  id: string;
  phone: string;
  full_name: string;
  language_pref: 'ar' | 'en';
  no_show_count: number;
  deposit_mandatory: boolean;
}

interface AuthState {
  user: AuthUser | null;
  isLoading: boolean;
  isAuthenticated: boolean;

  loginWithFirebase: (idToken: string, full_name?: string) => Promise<void>;
  loginWithSocial: (provider: 'apple' | 'google', token: string) => Promise<void>;
  logout: () => Promise<void>;
  setUser: (user: AuthUser) => void;
  initialize: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isLoading: true,
  isAuthenticated: false,

  initialize: async () => {
    const token = await tokenStorage.getAccess();
    if (!token) {
      set({ isLoading: false, isAuthenticated: false });
      return;
    }
    try {
      const res = await usersApi.getMe();
      set({ user: res.data, isLoading: false, isAuthenticated: true });
    } catch {
      await tokenStorage.clear();
      set({ user: null, isLoading: false, isAuthenticated: false });
    }
  },

  loginWithFirebase: async (idToken: string, full_name?: string) => {
    const res = await authApi.verifyFirebaseToken(idToken, full_name);
    const { access_token, refresh_token, user } = res.data;
    await tokenStorage.setTokens(access_token, refresh_token);
    try {
      const profileRes = await usersApi.getMe();
      set({ user: profileRes.data, isAuthenticated: true });
    } catch {
      set({ user, isAuthenticated: true });
    }
  },

  loginWithSocial: async (provider, token) => {
    const res = await authApi.socialLogin(provider, token);
    const { access_token, refresh_token, user } = res.data;
    await tokenStorage.setTokens(access_token, refresh_token);
    try {
      const profileRes = await usersApi.getMe();
      set({ user: profileRes.data, isAuthenticated: true });
    } catch {
      set({ user, isAuthenticated: true });
    }
  },

  logout: async () => {
    try {
      await authApi.logout();
    } finally {
      await tokenStorage.clear();
      set({ user: null, isAuthenticated: false });
    }
  },

  setUser: (user: AuthUser) => set({ user }),
}));
