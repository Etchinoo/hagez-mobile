import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { en } from '../i18n/en';
import { ar } from '../i18n/ar';

const LANG_KEY = 'hagez_language';

type Lang = 'en' | 'ar';

interface LanguageState {
  lang: Lang;
  t: typeof en;
  setLang: (lang: Lang) => void;
  initialize: () => Promise<void>;
}

const strings = { en, ar } as Record<Lang, typeof en>;

export const useLanguageStore = create<LanguageState>((set) => ({
  lang: 'en',
  t: en,

  setLang: (lang: Lang) => {
    AsyncStorage.setItem(LANG_KEY, lang);
    set({ lang, t: strings[lang] });
  },

  initialize: async () => {
    const saved = (await AsyncStorage.getItem(LANG_KEY)) as Lang | null;
    const lang = saved ?? 'en';
    set({ lang, t: strings[lang] });
  },
}));
