<template>
  <div class="h-full flex flex-col items-center justify-center py-20">
    <el-card shadow="never" class="!border-none !rounded-2xl max-w-md w-full text-center shadow-lg py-8">
      
      <!-- SUCCESS -->
      <div v-if="resultStatus === 'success'">
        <div class="w-20 h-20 bg-green-100 text-green-500 rounded-full flex items-center justify-center mx-auto mb-6">
          <el-icon class="text-4xl"><CircleCheckFilled /></el-icon>
        </div>
        <h2 class="text-2xl font-bold text-gray-800 mb-2">Thanh toán thành công!</h2>
        <p class="text-gray-500 mb-6">Mã đơn hàng: <strong class="text-gray-700">#{{ orderCode }}</strong></p>
        <p class="text-sm text-gray-600 mb-8 bg-gray-50 p-4 rounded-lg">
          Hệ thống đã ghi nhận thanh toán và đang kích hoạt tài khoản NTRIP của bạn. 
          Vui lòng kiểm tra lại danh sách thiết bị.
        </p>
        
        <div class="flex flex-col gap-3">
          <el-button type="primary" size="large" @click="$router.push('/user/ntrip-accounts')">
            Xem Tài khoản NTRIP
          </el-button>
          <el-button plain size="large" @click="$router.push('/user')">
            Về Bảng điều khiển
          </el-button>
        </div>
      </div>

      <!-- CANCELLED -->
      <div v-else-if="resultStatus === 'cancelled'">
        <div class="w-20 h-20 bg-yellow-100 text-yellow-600 rounded-full flex items-center justify-center mx-auto mb-6">
          <el-icon class="text-4xl"><WarningFilled /></el-icon>
        </div>
        <h2 class="text-2xl font-bold text-gray-800 mb-2">Giao dịch bị hủy!</h2>
        <p class="text-gray-500 mb-6">Mã tham chiếu: <strong class="text-gray-700">#{{ orderCode || 'N/A' }}</strong></p>
        <p class="text-sm text-gray-600 mb-8 px-4">
          Bạn đã hủy giao dịch thanh toán hoặc quá thời gian cho phép. Các đơn hàng vẫn đang ở trạng thái Chờ thanh toán.
        </p>

        <div class="flex flex-col gap-3">
          <el-button type="primary" size="large" @click="$router.push('/user/orders')">
            Quay lại Đơn hàng
          </el-button>
        </div>
      </div>

      <!-- FAILED / ERROR -->
      <div v-else>
        <div class="w-20 h-20 bg-red-100 text-red-500 rounded-full flex items-center justify-center mx-auto mb-6">
          <el-icon class="text-4xl"><CircleCloseFilled /></el-icon>
        </div>
        <h2 class="text-2xl font-bold text-gray-800 mb-2">Giao dịch thất bại!</h2>
        <p class="text-gray-500 mb-6 font-mono text-xs">Mã lỗi: {{ errorCode }}</p>
        <p class="text-sm text-gray-600 mb-8 px-4">
          Giao dịch thanh toán không thành công do lỗi hệ thống hoặc tham số không hợp lệ. Vui lòng liên hệ bộ phận hỗ trợ nếu bạn đã bị trừ tiền.
        </p>

        <div class="flex flex-col gap-3">
          <el-button type="primary" size="large" @click="$router.push('/user/orders')">
            Quay lại Đơn hàng
          </el-button>
        </div>
      </div>

    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { CircleCheckFilled, CircleCloseFilled, WarningFilled } from '@element-plus/icons-vue';
import { paymentApi } from '../../services/api';

const route = useRoute();
const resultStatus = ref<'success' | 'cancelled' | 'error'>('error');
const orderCode = ref('');
const errorCode = ref('');

onMounted(() => {
  // Parsers form PayOS returnUrl
  // Extracted fields: ?code=00&id=...&cancel=true&status=CANCELLED&orderCode=803347
  
  const codeParam = route.query.code as string;
  const statusParam = route.query.status as string;
  const cancelParam = route.query.cancel as string;
  
  orderCode.value = (route.query.orderCode as string) || '';
  errorCode.value = codeParam || 'UNKNOWN';

  if (codeParam === '00' || statusParam === 'PAID') {
    if (cancelParam === 'true' || statusParam === 'CANCELLED') {
      resultStatus.value = 'cancelled';
    } else {
      resultStatus.value = 'success';
      // Sync with backend PayOS manually to handle localhost webhook misses
      if (orderCode.value) {
        paymentApi.syncStatus(orderCode.value).catch(err => console.error('Failed to sync PayOS status', err));
      }
    }
  } else if (cancelParam === 'true') {
     resultStatus.value = 'cancelled';
  } else {
    // Other codes (e.g. 01, 02) mean FAILED / INVALID
    resultStatus.value = 'error';
  }
});
</script>
