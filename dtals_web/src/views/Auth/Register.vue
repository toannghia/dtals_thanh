<template>
  <div class="min-h-screen relative flex items-center justify-center p-4 bg-cover bg-center bg-no-repeat" style="background-image: url('/bg-login.png')">
    <!-- Overlay -->
    <div class="absolute inset-0 bg-slate-900/40 backdrop-blur-[2px]"></div>

    <!-- Màn đăng ký nhiều trường nên để rộng hơn một chút (480px) -->
    <div class="relative z-10 w-full max-w-[480px]">
      <div class="bg-white/95 backdrop-blur-md rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.12)] px-8 py-10 border border-white/50">
        <div class="text-center mb-8">
          <img 
            src="/DTALS.png" 
            alt="DTALS" 
            class="h-20 mx-auto mb-4 object-contain brightness-105" 
            @error="handleImageError"
          />
          <h2 class="text-2xl font-bold text-gray-800">Đăng ký tài khoản</h2>
          <p class="text-sm text-gray-500 mt-1">Tạo tài khoản DTALS Platform của bạn</p>
        </div>

        <el-form :model="form" :rules="rules" ref="formRef" @submit.prevent="handleRegister" label-position="top">
          <!-- Full Name -->
          <el-form-item label="Họ và tên" prop="fullName">
            <el-input v-model="form.fullName" placeholder="Nguyễn Văn A" size="large" />
          </el-form-item>

          <!-- Username -->
          <el-form-item label="Tên đăng nhập" prop="username">
            <el-input v-model="form.username" placeholder="Nhập tên đăng nhập" size="large" />
          </el-form-item>

          <!-- Email -->
          <el-form-item label="Email" prop="email">
            <el-input v-model="form.email" type="email" placeholder="example@email.com" size="large" />
            <div class="text-xs text-gray-500 mt-1">Vui lòng nhập Email thật để nhận được link kích hoạt tài khoản</div>
          </el-form-item>

          <!-- Phone (Bắt buộc) -->
          <el-form-item label="Số điện thoại" prop="phoneNumber">
            <el-input v-model="form.phoneNumber" placeholder="Nhập số điện thoại của bạn" size="large" />
          </el-form-item>

          <!-- Password -->
          <el-form-item label="Mật khẩu" prop="password">
            <el-input v-model="form.password" type="password" placeholder="Mật khẩu (ít nhất 6 ký tự)" size="large" show-password />
          </el-form-item>

          <!-- Confirm Password -->
          <el-form-item label="Xác nhận mật khẩu" prop="confirmPassword">
            <el-input v-model="form.confirmPassword" type="password" placeholder="Nhập lại mật khẩu" size="large" show-password />
          </el-form-item>

          <!-- Chính sách -->
          <el-form-item prop="agreePolicy" class="mb-2">
            <el-checkbox v-model="form.agreePolicy">
              Tôi đồng ý với <a href="#" class="text-blue-600 hover:underline">Chính sách bảo vệ dữ liệu cá nhân</a>
            </el-checkbox>
          </el-form-item>
          
          <!-- Captcha -->
          <div id="cf-turnstile-register" class="mt-2 mb-4 flex justify-center"></div>

          <el-button type="primary" class="w-full mt-4 font-bold shadow-md shadow-blue-500/30" size="large" :loading="loading" @click="handleRegister">
            Đăng ký
          </el-button>

          <div class="mt-5 text-center text-sm font-medium">
            <span class="text-gray-500">Đã có tài khoản?</span>
            <router-link to="/login" class="text-blue-600 hover:text-blue-700 ml-1">
              Đăng nhập ngay
            </router-link>
          </div>
        </el-form>

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
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import type { FormInstance, FormRules } from 'element-plus';
import { endUserAuthApi } from '../../services/api';

const handleImageError = (e: Event) => {
  const target = e.target as HTMLImageElement;
  if (target) {
    target.src = 'https://placehold.co/200x80?text=DTALS';
  }
};

const router = useRouter();
const formRef = ref<FormInstance>();
const loading = ref(false);

const form = ref({
  fullName: '',
  username: '',
  email: '',
  phoneNumber: '',
  password: '',
  confirmPassword: '',
  agreePolicy: false,
  captchaToken: ''
});

onMounted(() => {
  // Load Turnstile script
  const script = document.createElement('script');
  script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';
  script.async = true;
  script.defer = true;
  document.head.appendChild(script);

  script.onload = () => {
    if ((window as any).turnstile) {
      (window as any).turnstile.render('#cf-turnstile-register', {
        sitekey: '1x00000000000000000000AA', // testing site key
        callback: (token: string) => {
          form.value.captchaToken = token;
        }
      });
    }
  };
});

const validatePass = (_rule: any, value: any, callback: any) => {
  if (value === '') {
    callback(new Error('Vui lòng nhập mật khẩu'));
  } else if (value.length < 6) {
    callback(new Error('Mật khẩu phải chứa ít nhất 6 ký tự'));
  } else {
    if (form.value.confirmPassword !== '') {
      if (!formRef.value) return;
      formRef.value.validateField('confirmPassword');
    }
    callback();
  }
};

const validatePass2 = (_rule: any, value: any, callback: any) => {
  if (value === '') {
    callback(new Error('Vui lòng xác nhận lại mật khẩu'));
  } else if (value !== form.value.password) {
    callback(new Error('Mật khẩu xác nhận không khớp!'));
  } else {
    callback();
  }
};

const rules = ref<FormRules>({
  fullName: [
    { required: true, message: 'Vui lòng nhập họ và tên', trigger: 'blur' }
  ],
  username: [
    { required: true, message: 'Vui lòng nhập tên đăng nhập', trigger: 'blur' },
    { min: 3, message: 'Tên đăng nhập từ 3 ký tự trở lên', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_\-\.]+$/, message: 'Tên đăng nhập không được có dấu hoặc ký tự đặc biệt', trigger: 'blur' }
  ],
  phoneNumber: [
    { required: true, message: 'Vui lòng nhập số điện thoại', trigger: 'blur' },
    { pattern: /^(0|\+84)[3|5|7|8|9][0-9]{8}$/, message: 'Số điện thoại không hợp lệ', trigger: 'blur' }
  ],
  email: [
    { required: true, message: 'Vui lòng nhập địa chỉ email', trigger: 'blur' },
    { type: 'email', message: 'Địa chỉ email không hợp lệ', trigger: ['blur', 'change'] }
  ],
  password: [
    { validator: validatePass, trigger: 'blur', required: true }
  ],
  confirmPassword: [
    { validator: validatePass2, trigger: 'blur', required: true }
  ],
  agreePolicy: [
    { validator: (_rule: any, value: boolean, callback: any) => value ? callback() : callback(new Error('Vui lòng đồng ý với chính sách bảo vệ dữ liệu')), trigger: 'change' }
  ]
});

const handleRegister = async () => {
  if (!formRef.value) return;
  await formRef.value.validate(async (valid) => {
    if (valid) {
      if (!form.value.captchaToken) {
        ElMessage.warning('Vui lòng xác minh Captcha');
        return;
      }
      loading.value = true;
      try {
        await endUserAuthApi.register({
          fullName: form.value.fullName,
          username: form.value.username,
          email: form.value.email,
          phoneNumber: form.value.phoneNumber,
          password: form.value.password,
          captchaToken: form.value.captchaToken
        } as any);
        ElMessage.success({
          message: 'Đăng ký thành công! Vui lòng kiểm tra email của bạn để kích hoạt tài khoản trước khi đăng nhập.',
          duration: 5000,
          showClose: true
        });
        router.push('/login');
      } catch (e: any) {
        ElMessage.error(e.response?.data?.message || 'Đã xảy ra lỗi trong quá trình đăng ký');
      } finally {
        loading.value = false;
      }
    }
  });
};
</script>

<style scoped>
/* Gắn CSS Variable của Element Plus để đảm bảo đồng nhất hệ thống Input */
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
