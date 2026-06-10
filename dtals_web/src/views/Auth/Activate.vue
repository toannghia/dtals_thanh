<template>
  <div class="min-h-screen flex items-center justify-center bg-[#e9ecef] py-10">
    <div class="w-full max-w-[500px]">
      <div class="text-center mb-6">
        <div class="w-16 h-16 bg-blue-500 rounded-xl flex items-center justify-center mx-auto shadow-lg mb-3">
          <span class="text-white font-bold text-3xl">D</span>
        </div>
        <h1 class="text-2xl font-bold text-gray-800">Kích hoạt tài khoản</h1>
        <p class="text-sm text-gray-500">Hoàn tất đăng ký tài khoản DTALS Portal của bạn</p>
      </div>

      <div class="bg-white rounded-lg shadow-md p-8 text-center">
        <!-- Error Initial state (No token) -->
        <div v-if="state === 'invalid'" class="flex flex-col items-center justify-center py-4">
          <el-icon class="text-5xl text-red-500 mb-4"><CircleCloseFilled /></el-icon>
          <h2 class="text-xl font-semibold text-gray-800 mb-2">Đường dẫn không hợp lệ</h2>
          <p class="text-gray-600 mb-6">Liên kết kích hoạt này không chính xác hoặc không có mã kích hoạt.</p>
          <el-button plain size="large" class="w-full" @click="goToLogin">
            Về trang Đăng nhập
          </el-button>
        </div>

        <!-- Pending state (Waiting for user to click) -->
        <div v-else-if="state === 'pending'" class="flex flex-col items-center justify-center py-4">
          <el-icon class="text-5xl text-blue-500 mb-4"><Message /></el-icon>
          <h2 class="text-xl font-semibold text-gray-800 mb-2">Xác nhận Email</h2>
          <p class="text-gray-600 mb-6">Cảm ơn bạn đã đăng ký. Vui lòng nhấn nút bên dưới để hoàn tất việc kích hoạt tài khoản của bạn.</p>
          <el-button type="primary" size="large" class="w-full" @click="activateAccount" :loading="loading">
            Kích hoạt tài khoản
          </el-button>
        </div>

        <!-- Success state -->
        <div v-else-if="state === 'success'" class="flex flex-col items-center justify-center py-4">
          <el-icon class="text-5xl text-green-500 mb-4"><CircleCheckFilled /></el-icon>
          <h2 class="text-xl font-semibold text-gray-800 mb-2">Kích hoạt thành công!</h2>
          <p class="text-gray-600 mb-6">Tài khoản của bạn đã sẵn sàng sử dụng. Hãy tiếp tục đăng nhập để khám phá các dịch vụ.</p>
          <el-button type="primary" size="large" class="w-full" @click="goToLogin">
            Đăng nhập ngay
          </el-button>
        </div>

        <!-- Error state (Token invalid or expired) -->
        <div v-else-if="state === 'error'" class="flex flex-col items-center justify-center py-4">
          <el-icon class="text-5xl text-red-500 mb-4"><CircleCloseFilled /></el-icon>
          <h2 class="text-xl font-semibold text-gray-800 mb-2">Kích hoạt thất bại</h2>
          <p class="text-gray-600 mb-6">{{ errorMessage }}</p>
          <el-button plain size="large" class="w-full" @click="goToLogin">
            Về trang Đăng nhập
          </el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { endUserAuthApi } from '../../services/api';
import { CircleCheckFilled, CircleCloseFilled, Message } from '@element-plus/icons-vue';

const route = useRoute();
const router = useRouter();

// state: 'invalid' | 'pending' | 'success' | 'error'
const state = ref('pending');
const loading = ref(false);
const errorMessage = ref('');
const token = ref('');

onMounted(() => {
  token.value = route.query.token as string;
  
  if (!token.value) {
    state.value = 'invalid';
  }
});

const activateAccount = async () => {
  if (!token.value) return;
  
  loading.value = true;
  try {
    await endUserAuthApi.activate(token.value);
    state.value = 'success';
  } catch (e: any) {
    state.value = 'error';
    errorMessage.value = e.response?.data?.message || 'Mã kích hoạt đã hết hạn hoặc không hợp lệ.';
  } finally {
    loading.value = false;
  }
};

const goToLogin = () => {
  router.push('/login');
};
</script>
