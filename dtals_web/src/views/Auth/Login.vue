<template>
  <div class="min-h-screen relative flex items-center justify-center p-4 bg-cover bg-center bg-no-repeat" style="background-image: url('/bg-login.png')">
    <!-- Overlay - Giảm độ mờ -->
    <div class="absolute inset-0 bg-slate-900/40 backdrop-blur-[2px]"></div>

    <!-- Co chiều rộng khối max-w-420px cân đối hơn -->
    <div class="relative z-10 w-full max-w-[480px]">
      <!-- Background thẻ xốp mờ nhẹ -->
      <div class="bg-white/95 backdrop-blur-md rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.12)] px-8 py-10 border border-white/50">
        <div class="text-center mb-8">
          <img 
            src="/DTALS.png" 
            alt="DTALS" 
            class="h-20 mx-auto mb-4 object-contain brightness-105" 
            @error="handleImageError"
          />
          <h2 class="text-2xl font-bold text-gray-800">Đăng nhập quản trị</h2>
        </div>

        <el-form :model="form" @submit.prevent="handleLogin" label-position="top">
          <el-form-item label="Tài khoản">
            <el-input 
              v-model="form.username" 
              placeholder="Nhập tên đăng nhập, Email hoặc Số điện thoại" 
              size="large"
              @keyup.enter="passwordRef?.focus()"
            />
          </el-form-item>
          <el-form-item>
            <template #label>
              <!-- w-full và justify-between để bung rộng sát lề, đẩy Quên mật khẩu sang phải -->
              <div class="flex justify-between items-center w-full">
                <span class="font-medium text-gray-700">Mật khẩu</span>
                <el-link type="primary" :underline="false" @click="handleForgotPassword" class="text-sm font-semibold !ml-auto">
                  Quên mật khẩu?
                </el-link>
              </div>
            </template>
            <el-input 
              ref="passwordRef"
              v-model="form.password" 
              type="password" 
              placeholder="Nhập mật khẩu" 
              size="large" 
              show-password 
              @keyup.enter="handleLogin"
            />
          </el-form-item>

          <!-- Captcha Box -->
          <div v-if="showCaptcha" class="mt-2 mb-4 w-full flex justify-center flex-col items-center">
            <p class="text-sm text-red-500 mb-2 font-medium">Bạn đã đăng nhập sai nhiều lần, vui lòng xác minh bảo mật:</p>
            <div id="cf-turnstile-login"></div>
          </div>
          
          <el-button type="primary" class="w-full mt-2 font-bold shadow-md shadow-blue-500/30" size="large" :loading="loading" @click="handleLogin">
            Đăng nhập
          </el-button>

          <div class="mt-5 text-center text-sm font-medium">
            <span class="text-gray-500">Chưa có tài khoản?</span>
            <router-link to="/register" class="text-blue-600 hover:text-blue-700 ml-1">
              Đăng ký ngay
            </router-link>
          </div>
        </el-form>
        <div v-if="errorMsg" class="mt-4 text-center text-red-500 text-sm font-medium bg-red-50 p-2 rounded">{{ errorMsg }}</div>

        <!-- Dialog Quên mật khẩu -->
        <el-dialog v-model="forgotPasswordVisible" title="Quên mật khẩu" width="400px" align-center class="!rounded-xl overflow-hidden">
          <div class="mb-5 text-gray-500 text-sm">
            Vui lòng nhập địa chỉ email của bạn. Chúng tôi sẽ gửi một liên kết để đặt lại mật khẩu của tài khoản.
          </div>
          <el-input 
            v-model="forgotEmail" 
            placeholder="Nhập email của bạn (vd: example@dtals.vn)" 
            size="large" 
            @keyup.enter="submitForgotPassword"
          >
            <template #prefix>
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
            </template>
          </el-input>
          <template #footer>
            <div class="flex justify-end gap-3 mt-4">
              <el-button @click="forgotPasswordVisible = false" size="large" class="!rounded-lg">Hủy</el-button>
              <el-button type="primary" :loading="forgotLoading" @click="submitForgotPassword" size="large" class="!rounded-lg font-semibold shadow-md shadow-blue-500/30">
                Gửi liên kết
              </el-button>
            </div>
          </template>
        </el-dialog>

        <!-- Footer CSKH -->
        <div class="mt-8 pt-6 border-t border-gray-100 flex flex-col items-center">
          <p class="text-sm text-gray-400 font-medium mb-3">Hỗ trợ khách hàng (CSKH)</p>
          <div class="flex flex-col sm:flex-row items-center gap-2 sm:gap-6 text-sm text-gray-500">
            <a href="tel:0985858599" class="flex items-center gap-2 hover:text-blue-600 font-medium transition-colors">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" /></svg>
              0985 858 599
            </a>
            <a href="mailto:contact@dtals.vn" class="flex items-center gap-2 hover:text-blue-600 font-medium transition-colors">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
              contact@dtals.vn
            </a>
          </div>
        </div>

      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '../../store/auth';
import { endUserAuthApi } from '../../services/api';
import { ElMessage, ElMessageBox } from 'element-plus';

const router = useRouter();
const authStore = useAuthStore();
const loading = ref(false);
const errorMsg = ref('');
const passwordRef = ref<any>(null);
const showCaptcha = ref(false);

const form = ref({ username: '', password: '', captchaToken: '' });

const forgotPasswordVisible = ref(false);
const forgotEmail = ref('');
const forgotLoading = ref(false);

onMounted(() => {
  // Tải sẵn script
  const script = document.createElement('script');
  script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';
  script.async = true;
  script.defer = true;
  document.head.appendChild(script);
});

const renderCaptcha = () => {
  nextTick(() => {
    if ((window as any).turnstile) {
      (window as any).turnstile.render('#cf-turnstile-login', {
        sitekey: '1x00000000000000000000AA', // testing site key
        callback: (token: string) => {
          form.value.captchaToken = token;
        }
      });
    }
  });
};

const handleImageError = (e: Event) => {
  const target = e.target as HTMLImageElement;
  if (target) {
    target.src = 'https://placehold.co/200x80?text=DTALS';
  }
};

const handleForgotPassword = () => {
  forgotEmail.value = '';
  forgotPasswordVisible.value = true;
};

const submitForgotPassword = async () => {
  if (!forgotEmail.value || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(forgotEmail.value)) {
    ElMessage.warning('Vui lòng nhập một địa chỉ email hợp lệ');
    return;
  }
  forgotLoading.value = true;
  try {
    const res = await endUserAuthApi.forgotPasswordInit({ email: forgotEmail.value });
    ElMessage.success(res.data?.message || 'Link khôi phục mật khẩu đã được gửi đến email của bạn.');
    forgotPasswordVisible.value = false;
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || 'Không thể gửi yêu cầu lúc này. Kiểm tra email hoặc thử lại sau.');
  } finally {
    forgotLoading.value = false;
  }
};


const handleLogin = async () => {
  if (!form.value.username || !form.value.password) {
    errorMsg.value = 'Vui lòng nhập đầy đủ thông tin';
    return;
  }
  if (showCaptcha.value && !form.value.captchaToken) {
    errorMsg.value = 'Vui lòng xác minh bảo mật (Captcha)';
    return;
  }
  loading.value = true;
  errorMsg.value = '';
  try {
    await authStore.login(form.value.username, form.value.password, form.value.captchaToken);
    if (authStore.isAdmin) {
      router.push('/');
    } else {
      router.push('/user');
    }
  } catch (e: any) {
    if (!e.response) {
      errorMsg.value = 'Không thể kết nối với máy chủ. Vui lòng kiểm tra lại kết nối mạng.';
    } else {
      const code = e.response.data?.errorCode;
      if (code === 'REQUIRED_CAPTCHA') {
        if (!showCaptcha.value) {
          showCaptcha.value = true;
          renderCaptcha();
        }
        errorMsg.value = e.response.data?.message || 'Mã bảo vệ hoặc mật khẩu không đúng';
      } else if (code === 'LOCKED') {
        errorMsg.value = '';
        ElMessageBox.alert(
          'Tài khoản của bạn đã bị tạm khóa do nhập sai mật khẩu nhiều lần. Vui lòng liên hệ Hotline: 0985 858 599 để được hỗ trợ.',
          'Tài khoản bị khóa',
          { confirmButtonText: 'Đã hiểu', type: 'error' }
        );
      } else if (e.response.status === 401 || e.response.status === 403) {
        errorMsg.value = e.response.data?.message || 'Sai tài khoản hoặc mật khẩu';
      } else {
        errorMsg.value = e.response.data?.message || 'Có lỗi xảy ra, vui lòng thử lại sau';
      }
    }
  } finally {
    loading.value = false;
  }
};
</script>

<style scoped>
/* Ép kích thước nhãn form 100% để phần flex hoạt động đúng (đẩy text sang ngang) */
:deep(.el-form-item__label) {
  display: flex !important;
  width: 100% !important;
  padding-bottom: 6px;
}

/* Gắn CSS Variable của Element Plus để đảm bảo đồng nhất mọi layer */
:deep(.el-input) {
  --el-input-bg-color: #f8fafc;
  --el-input-border-color: #e2e8f0;
  --el-input-hover-border-color: #cbd5e1;
  --el-input-focus-border-color: #3b82f6;
}

/* Ép wrapper sử dụng màu nền chính xác */
:deep(.el-input__wrapper) {
  background-color: var(--el-input-bg-color) !important;
  box-shadow: 0 0 0 1px var(--el-input-border-color) inset !important;
  transition: all 0.2s ease;
}

:deep(.el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px var(--el-input-hover-border-color) inset !important;
}

:deep(.el-input__wrapper.is-focus) {
  background-color: #ffffff !important;
  box-shadow: 0 0 0 1px var(--el-input-focus-border-color) inset !important;
}

/* Xử lý triệt để lõi màu xanh/vàng do Chrome Autofill gây ra */
:deep(.el-input__inner:-webkit-autofill),
:deep(.el-input__inner:-webkit-autofill:hover), 
:deep(.el-input__inner:-webkit-autofill:focus), 
:deep(.el-input__inner:-webkit-autofill:active) {
  -webkit-box-shadow: 0 0 0 1000px #f8fafc inset !important;
  -webkit-text-fill-color: #1f2937 !important;
  transition: background-color 5000s ease-in-out 0s;
}

:deep(.el-input__inner) {
  background-color: transparent !important;
}
</style>
