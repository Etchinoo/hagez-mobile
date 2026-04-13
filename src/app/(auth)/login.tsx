// ============================================================
// SUPER RESERVATION PLATFORM — Login Screen
// Firebase Phone Auth + Google Sign-In + Apple Sign-In
// Country code selector. Language toggle. 6-digit OTP.
// ============================================================

import React, { useState, useRef, useEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  KeyboardAvoidingView, Platform, ActivityIndicator, Image,
  Modal, FlatList, ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import * as AppleAuthentication from 'expo-apple-authentication';
import { Ionicons } from '@expo/vector-icons';
import auth, { type FirebaseAuthTypes } from '@react-native-firebase/auth';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { authApi } from '../../services/api';
import { useAuthStore } from '../../store/auth';
import { useLanguageStore } from '../../store/language';

// ── Country codes (abbreviated names, no flags — matching dashboard) ──

const COUNTRIES = [
  { code: 'EG', dial: '20',  name: 'Egypt',        nameAr: 'مصر' },
  { code: 'SA', dial: '966', name: 'Saudi Arabia',  nameAr: 'السعودية' },
  { code: 'AE', dial: '971', name: 'UAE',           nameAr: 'الإمارات' },
  { code: 'KW', dial: '965', name: 'Kuwait',        nameAr: 'الكويت' },
  { code: 'QA', dial: '974', name: 'Qatar',         nameAr: 'قطر' },
  { code: 'BH', dial: '973', name: 'Bahrain',       nameAr: 'البحرين' },
  { code: 'OM', dial: '968', name: 'Oman',          nameAr: 'عُمان' },
  { code: 'JO', dial: '962', name: 'Jordan',        nameAr: 'الأردن' },
  { code: 'LB', dial: '961', name: 'Lebanon',       nameAr: 'لبنان' },
  { code: 'IQ', dial: '964', name: 'Iraq',          nameAr: 'العراق' },
  { code: 'LY', dial: '218', name: 'Libya',         nameAr: 'ليبيا' },
] as const;

type Country = (typeof COUNTRIES)[number];
type Step = 'phone' | 'otp';

function formatPhone(raw: string, dial: string): string {
  let digits = raw.replace(/\D/g, '');
  if (digits.startsWith('0')) digits = digits.slice(1);
  return `+${dial}${digits}`;
}

export default function LoginScreen() {
  const router = useRouter();
  const loginWithFirebase = useAuthStore((s) => s.loginWithFirebase);
  const loginWithSocial = useAuthStore((s) => s.loginWithSocial);
  const { lang, setLang } = useLanguageStore();

  const [step, setStep] = useState<Step>('phone');
  const [country, setCountry] = useState<Country>(COUNTRIES[0]);
  const [phoneRaw, setPhoneRaw] = useState('');
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [pickerOpen, setPickerOpen] = useState(false);
  const otpRef = useRef<TextInput>(null);
  const confirmationRef = useRef<FirebaseAuthTypes.ConfirmationResult | null>(null);

  const isAr = lang === 'ar';
  const fullPhone = formatPhone(phoneRaw, country.dial);

  // Configure Google Sign-In on mount
  useEffect(() => {
    GoogleSignin.configure({
      webClientId: '323829556168-6hokv97mg5gnpo5fcrhba2mri1pa5950.apps.googleusercontent.com',
    });
  }, []);

  // ── Firebase Phone Auth: send OTP ──

  const handleRequestOtp = async () => {
    const digits = phoneRaw.replace(/\D/g, '').replace(/^0/, '');
    if (digits.length < 8 || digits.length > 12) {
      setError(isAr ? 'أدخل رقم هاتف صحيح' : 'Enter a valid phone number');
      return;
    }

    setLoading(true);
    setError('');
    try {
      const confirmation = await auth().signInWithPhoneNumber(fullPhone);
      confirmationRef.current = confirmation;
      setStep('otp');
      setTimeout(() => otpRef.current?.focus(), 300);
    } catch (e: any) {
      console.error('[Firebase OTP] Send failed:', e);
      if (e.code === 'auth/too-many-requests') {
        setError(isAr ? 'محاولات كثيرة. انتظر قليلاً.' : 'Too many attempts. Wait a moment.');
      } else if (e.code === 'auth/invalid-phone-number') {
        setError(isAr ? 'رقم الهاتف غير صحيح' : 'Invalid phone number');
      } else {
        setError(isAr ? 'فشل الإرسال. حاول مرة أخرى.' : 'Failed to send. Try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  // ── Firebase Phone Auth: verify OTP ──

  const handleVerifyOtp = async () => {
    if (otp.length !== 6) {
      setError(isAr ? 'أدخل الكود المكون من 6 أرقام' : 'Enter the 6-digit code');
      return;
    }
    if (!confirmationRef.current) {
      setError(isAr ? 'أعد إرسال الكود' : 'Please resend the code');
      return;
    }

    setLoading(true);
    setError('');
    try {
      const credential = await confirmationRef.current.confirm(otp);
      const idToken = await credential?.user.getIdToken();
      if (!idToken) throw new Error('No ID token');

      await loginWithFirebase(idToken);
      router.replace('/(tabs)');
    } catch (e: any) {
      console.error('[Firebase OTP] Verify failed:', e);
      if (e.code === 'auth/invalid-verification-code') {
        setError(isAr ? 'الكود غير صحيح' : 'Invalid code');
      } else {
        setError(isAr ? 'الكود غير صحيح أو منتهي الصلاحية' : 'Invalid or expired code');
      }
    } finally {
      setLoading(false);
    }
  };

  // ── Google Sign-In ──

  const handleGoogleSignIn = async () => {
    setLoading(true);
    setError('');
    try {
      await GoogleSignin.hasPlayServices({ showPlayServicesUpdateDialog: true });
      const response = await GoogleSignin.signIn();
      const idToken = response.data?.idToken;
      if (!idToken) throw new Error('No Google ID token');

      await loginWithSocial('google', idToken);
      router.replace('/(tabs)');
    } catch (e: any) {
      if (e.code !== 'SIGN_IN_CANCELLED') {
        console.error('[Google Sign-In] Failed:', e);
        setError(isAr ? 'فشل تسجيل الدخول بـ Google' : 'Google sign-in failed');
      }
    } finally {
      setLoading(false);
    }
  };

  // ── Apple Sign-In (iOS only) ──

  const handleAppleSignIn = async () => {
    setLoading(true);
    setError('');
    try {
      const credential = await AppleAuthentication.signInAsync({
        requestedScopes: [
          AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
          AppleAuthentication.AppleAuthenticationScope.EMAIL,
        ],
      });
      if (!credential.identityToken) throw new Error('No identity token');
      await loginWithSocial('apple', credential.identityToken);
      router.replace('/(tabs)');
    } catch (e: any) {
      if (e.code !== 'ERR_REQUEST_CANCELED') {
        setError(isAr ? 'فشل تسجيل الدخول بـ Apple' : 'Apple sign-in failed');
      }
    } finally {
      setLoading(false);
    }
  };

  // ── Country picker item ──

  const renderCountryItem = ({ item }: { item: Country }) => (
    <TouchableOpacity
      style={styles.countryRow}
      onPress={() => { setCountry(item); setPickerOpen(false); }}
    >
      <Text style={styles.countryCode}>{item.code}</Text>
      <Text style={styles.countryName}>{isAr ? item.nameAr : item.name}</Text>
      <Text style={styles.countryDial}>+{item.dial}</Text>
    </TouchableOpacity>
  );

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.container}>
      {/* Language toggle */}
      <View style={styles.langRow}>
        <TouchableOpacity
          style={[styles.langBtn, lang === 'en' && styles.langBtnActive]}
          onPress={() => setLang('en')}
        >
          <Text style={[styles.langText, lang === 'en' && styles.langTextActive]}>EN</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.langBtn, lang === 'ar' && styles.langBtnActive]}
          onPress={() => setLang('ar')}
        >
          <Text style={[styles.langText, lang === 'ar' && styles.langTextActive]}>AR</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} keyboardShouldPersistTaps="handled">
        <View style={styles.header}>
          <Image
            source={require('../../../assets/logos/hagez_logo_transparent.png')}
            style={styles.logo}
            resizeMode="contain"
          />
          <Text style={styles.title}>
            {isAr ? 'احجز في ثواني' : 'Book in seconds'}
          </Text>
          <Text style={styles.subtitle}>
            {isAr ? 'مطاعم، صالونات وأكثر في تطبيق واحد' : 'Restaurants, salons & more — one app'}
          </Text>
        </View>

        <View style={styles.form}>
          {step === 'phone' ? (
            <>
              <Text style={styles.label}>
                {isAr ? 'رقم الهاتف' : 'Phone number'}
              </Text>

              <View style={[styles.phoneRow, !isAr && { flexDirection: 'row-reverse' }]}>
                <TouchableOpacity
                  style={styles.countrySelector}
                  onPress={() => setPickerOpen(true)}
                >
                  <Text style={styles.countrySelectorText}>
                    {country.code} +{country.dial}
                  </Text>
                  <Text style={styles.chevron}>▼</Text>
                </TouchableOpacity>

                <TextInput
                  style={styles.phoneInput}
                  value={phoneRaw}
                  onChangeText={setPhoneRaw}
                  placeholder={isAr ? 'رقم الهاتف' : 'Phone number'}
                  keyboardType="phone-pad"
                  textContentType="telephoneNumber"
                  autoComplete="tel"
                  autoFocus
                  textAlign={isAr ? 'right' : 'left'}
                />
              </View>

              {error ? <Text style={styles.errorText}>{error}</Text> : null}

              <TouchableOpacity style={styles.button} onPress={handleRequestOtp} disabled={loading}>
                {loading ? (
                  <ActivityIndicator color="#fff" />
                ) : (
                  <Text style={styles.buttonText}>
                    {isAr ? 'إرسال الكود' : 'Send Code'}
                  </Text>
                )}
              </TouchableOpacity>

              {/* Social sign-in */}
              <View style={styles.dividerRow}>
                <View style={styles.dividerLine} />
                <Text style={styles.dividerText}>{isAr ? 'أو' : 'or'}</Text>
                <View style={styles.dividerLine} />
              </View>

              <TouchableOpacity style={styles.googleBtn} onPress={handleGoogleSignIn} disabled={loading}>
                <Ionicons name="logo-google" size={20} color="#DB4437" style={{ marginRight: 8 }} />
                <Text style={styles.googleBtnText}>
                  {isAr ? 'الدخول بـ Google' : 'Continue with Google'}
                </Text>
              </TouchableOpacity>

              {Platform.OS === 'ios' && (
                <AppleAuthentication.AppleAuthenticationButton
                  buttonType={AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN}
                  buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.BLACK}
                  cornerRadius={12}
                  style={styles.appleBtn}
                  onPress={handleAppleSignIn}
                />
              )}
            </>
          ) : (
            <>
              <Text style={styles.label}>
                {isAr ? 'كود التحقق' : 'Verification code'}
              </Text>
              <Text style={styles.sentTo}>
                {isAr ? `أرسلنا الكود إلى ${fullPhone}` : `We sent a code to ${fullPhone}`}
              </Text>
              <TextInput
                ref={otpRef}
                style={[styles.input, styles.otpInput]}
                value={otp}
                onChangeText={(v) => setOtp(v.replace(/\D/g, '').slice(0, 6))}
                placeholder="123456"
                keyboardType="number-pad"
                maxLength={6}
                textAlign="center"
              />
              {error ? <Text style={styles.errorText}>{error}</Text> : null}
              <TouchableOpacity style={styles.button} onPress={handleVerifyOtp} disabled={loading}>
                {loading ? (
                  <ActivityIndicator color="#fff" />
                ) : (
                  <Text style={styles.buttonText}>
                    {isAr ? 'تأكيد' : 'Verify'}
                  </Text>
                )}
              </TouchableOpacity>
              <TouchableOpacity onPress={() => { setStep('phone'); setOtp(''); setError(''); confirmationRef.current = null; }}>
                <Text style={styles.backLink}>
                  {isAr ? 'تغيير رقم الهاتف' : 'Change phone number'}
                </Text>
              </TouchableOpacity>
            </>
          )}
        </View>
      </ScrollView>

      {/* Country picker modal */}
      <Modal visible={pickerOpen} transparent animationType="slide">
        <TouchableOpacity
          style={styles.modalOverlay}
          activeOpacity={1}
          onPress={() => setPickerOpen(false)}
        >
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>
              {isAr ? 'اختر الدولة' : 'Select country'}
            </Text>
            <FlatList
              data={COUNTRIES}
              keyExtractor={(c) => c.code}
              renderItem={renderCountryItem}
              ItemSeparatorComponent={() => <View style={styles.separator} />}
            />
          </View>
        </TouchableOpacity>
      </Modal>
    </KeyboardAvoidingView>
  );
}

const NAVY = '#0F2044';
const TEAL = '#1B8A7A';

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  scrollContent: { flexGrow: 1, padding: 24 },

  // Language toggle
  langRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
    paddingTop: Platform.OS === 'ios' ? 60 : 40,
    paddingHorizontal: 24,
  },
  langBtn: {
    paddingHorizontal: 16,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: '#E0E0E0',
  },
  langBtnActive: { backgroundColor: NAVY, borderColor: NAVY },
  langText: { fontFamily: 'Inter-Medium', fontSize: 13, color: '#666' },
  langTextActive: { color: '#fff' },

  // Header
  header: { flex: 1, justifyContent: 'center', alignItems: 'center', paddingTop: 20 },
  logo: { width: 140, height: 140, marginBottom: 16 },
  title: { fontFamily: 'Cairo-Bold', fontSize: 28, color: NAVY, textAlign: 'center' },
  subtitle: { fontFamily: 'Cairo-Regular', fontSize: 16, color: '#666', textAlign: 'center', marginTop: 8 },

  // Form
  form: { paddingBottom: 40 },
  label: {
    fontFamily: 'Cairo-SemiBold', fontSize: 16, color: NAVY, marginBottom: 8,
    writingDirection: 'rtl', alignSelf: 'stretch',
  },
  sentTo: {
    fontFamily: 'Cairo-Regular', fontSize: 14, color: '#666', marginBottom: 12,
    writingDirection: 'rtl', alignSelf: 'stretch',
  },

  // Phone row
  phoneRow: { flexDirection: 'row', gap: 8, marginBottom: 8 },
  countrySelector: {
    flexDirection: 'row', alignItems: 'center',
    borderWidth: 1.5, borderColor: '#E0E0E0', borderRadius: 12,
    paddingHorizontal: 12, paddingVertical: 14, gap: 6, minHeight: 54,
  },
  countrySelectorText: { fontFamily: 'Inter-Medium', fontSize: 15, color: NAVY },
  chevron: { fontSize: 10, color: '#999' },
  phoneInput: {
    flex: 1, borderWidth: 1.5, borderColor: '#E0E0E0', borderRadius: 12,
    paddingHorizontal: 16, paddingVertical: 14,
    fontFamily: 'Inter-Regular', fontSize: 18, color: NAVY, minHeight: 54,
  },

  input: {
    borderWidth: 1.5, borderColor: '#E0E0E0', borderRadius: 12,
    paddingHorizontal: 16, paddingVertical: 14,
    fontFamily: 'Cairo-Regular', fontSize: 18, color: NAVY,
    marginBottom: 8, minHeight: 54,
  },
  otpInput: { letterSpacing: 8, fontSize: 24, fontFamily: 'Cairo-Bold' },

  errorText: { fontFamily: 'Cairo-Regular', fontSize: 14, color: '#D32F2F', marginBottom: 8 },
  button: {
    backgroundColor: TEAL, borderRadius: 12, paddingVertical: 16,
    alignItems: 'center', marginTop: 8, minHeight: 54,
  },
  buttonText: { fontFamily: 'Cairo-Bold', fontSize: 18, color: '#fff' },
  backLink: {
    fontFamily: 'Cairo-Regular', fontSize: 14, color: TEAL,
    textAlign: 'center', marginTop: 16, paddingVertical: 12,
  },

  // Social buttons
  dividerRow: { flexDirection: 'row', alignItems: 'center', marginVertical: 16, gap: 10 },
  dividerLine: { flex: 1, height: 1, backgroundColor: '#E0E0E0' },
  dividerText: { fontFamily: 'Cairo-Regular', fontSize: 13, color: '#999' },
  googleBtn: {
    flexDirection: 'row', borderWidth: 1.5, borderColor: '#E0E0E0', borderRadius: 12,
    paddingVertical: 16, alignItems: 'center', justifyContent: 'center', minHeight: 54, marginBottom: 10,
  },
  googleBtnText: { fontFamily: 'Cairo-SemiBold', fontSize: 16, color: NAVY },
  appleBtn: { width: '100%', height: 54 },

  // Country picker modal
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.4)', justifyContent: 'flex-end' },
  modalContent: {
    backgroundColor: '#fff', borderTopLeftRadius: 20, borderTopRightRadius: 20,
    padding: 20, maxHeight: '60%',
  },
  modalTitle: {
    fontFamily: 'Cairo-Bold', fontSize: 18, color: NAVY,
    textAlign: 'center', marginBottom: 16,
  },
  countryRow: {
    flexDirection: 'row', alignItems: 'center', paddingVertical: 14, paddingHorizontal: 8,
  },
  countryCode: { fontFamily: 'Inter-SemiBold', fontSize: 15, color: NAVY, width: 40 },
  countryName: { fontFamily: 'Cairo-Regular', fontSize: 15, color: '#333', flex: 1 },
  countryDial: { fontFamily: 'Inter-Medium', fontSize: 15, color: '#666' },
  separator: { height: 1, backgroundColor: '#F0F0F0' },
});
