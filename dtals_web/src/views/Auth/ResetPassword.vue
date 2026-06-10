<template>
  <div class="min-h-screen relative flex items-center justify-center p-4 bg-cover bg-center bg-no-repeat" style="background-image: url('/bg-login.png')">
    <!-- Overlay - Giảm độ mờ như Login -->
    <div class="absolute inset-0 bg-slate-900/40 backdrop-blur-[2px]"></div>

    <div class="relative z-10 w-full max-w-[420px]">
      <!-- Box Form nền trắng bóng kính mờ -->
      <div class="bg-white/95 backdrop-blur-md rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.12)] px-8 py-10 border border-white/50">
        <div class="text-center mb-8">
          <img 
            src="/DTALS.png" 
            alt="DTALS" 
            class="h-20 mx-auto mb-4 object-contain brightness-105" 
            @error="handleImageError"
          />
          <h2 class="text-2xl font-bold text-gray-800">Đặt lại mật khẩu</h2>
          <p class="text-sm text-gray-500 mt-1">Nhập mật khẩu mới cho tài khoản của bạn</p>
        </div>

        <el-form :model="form" :rules="rules" ref="formRef" @submit.prevent="handleReset" label-position="top">
          <!-- Password -->
          <el-form-item label="Mật khẩu mới" prop="newPassword">
            <el-input v-model="form.newPassword" type="password" placeholder="Tối thiểu 6 ký tự" size="large" show-password />
          </el-form-item>

          <!-- Confirm Password -->
          <el-form-item label="Xác nhận mật khẩu" prop="confirmPassword">
            <el-input v-model="form.confirmPassword" type="password" placeholder="Nhập lại mật khẩu mới" size="large" show-password />
          </el-form-item>
          
          <el-button type="primary" class="w-full mt-4 font-bold shadow-md shadow-blue-500/30" size="large" :loading="loading" @click="handleReset">
            Đổi mật khẩu
          </el-button>

          <div class="mt-5 text-center text-sm font-medium">
            <router-link to="/login" class="text-blue-600 hover:text-blue-700 ml-1">
              &larr; Quay lại Đăng nhập
            </router-link>
          </div>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { ElMessage } from 'element-plus';
import type { FormInstance, FormRules } from 'element-plus';
import { endUserAuthApi } from '../../services/api';

const router = useRouter();
const route = useRoute();

const formRef = ref<FormInstance>();
const loading = ref(false);
const token = ref('');

const form = ref({
  newPassword: '',
  confirmPassword: ''
});

onMounted(() => {
  if (route.query.token) {
    token.value = route.query.token as string;
  } else {
    ElMessage.error('Liên kết không hợp lệ. Không tìm thấy mã khôi phục.');
    router.push('/login');
  }
});

const handleImageError = (e: Event) => {
  const target = e.target as HTMLImageElement;
  if (target) {
    target.src = 'https://placehold.co/200x80?text=DTALS';
  }
};

const validatePass = (_rule: any, value: any, callback: any) => {
  if (value === '') {
    callback(new Error('Vui lòng nhập mật khẩu mới'));
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
  } else if (value !== form.value.newPassword) {
    callback(new Error('Mật khẩu xác nhận không khớp!'));
  } else {
    callback();
  }
};

const rules = ref<FormRules>({
  newPassword: [{ validator: validatePass, trigger: 'blur', required: true }],
  confirmPassword: [{ validator: validatePass2, trigger: 'blur', required: true }]
});

const handleReset = async () => {
  if (!formRef.value) return;
  await formRef.value.validate(async (valid) => {
    if (valid) {
      if (!token.value) {
        ElMessage.error('Không tìm thấy mã phiên làm việc để xử lý.');
        return;
      }
      loading.value = true;
      try {
        await endUserAuthApi.resetPassword({
          token: token.value,
          newPassword: form.value.newPassword
        });
        ElMessage.success('Đổi mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.');
        router.push('/login');
      } catch (error: any) {
        ElMessage.error(error.response?.data?.message || 'Không thể khôi phục mật khẩu. Liên kết có thể đã hết hạn.');
      } finally {
        loading.value = false;
      }
    }
  });
};
</script>

<style scoped>
/* Đồng nhất Style như form Login/Register */
:deep(.el-form-item__label) {
  display: flex !important;
  width: 100% !important;
  padding-bottom: 6px;
}
:deep(.el-input) {
  --el-input-bg-color: #f8fafc;
  --el-input-border-color: #e2e8f0;
  --el-input-hover-border-color: #cbd5e1;
  --el-input-focus-border-color: #3b82f6;
}
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
