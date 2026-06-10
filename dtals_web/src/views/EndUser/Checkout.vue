<template>
  <div class="max-w-4xl mx-auto">
    <div class="mb-6">
      <el-button @click="$router.push('/user/orders')" plain class="mb-4">
        &larr; Quay lại Đơn hàng
      </el-button>
      <h2 class="text-2xl font-bold text-gray-800">Thanh toán Đơn hàng</h2>
      <p class="text-gray-500">Phê duyệt và chuyển khoản thanh toán qua PayOS</p>
    </div>

    <div v-if="loading" class="flex flex-col justify-center items-center h-[300px] bg-white rounded-xl shadow-sm">
      <el-icon class="is-loading text-blue-500 text-4xl mb-4"><Loading /></el-icon>
      <span class="text-gray-500">Đang khởi tạo kết nối thanh toán an toàn...</span>
    </div>

    <!-- Layout: Left (Order Details), Right (PayOS Embedded) -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      
      <!-- Order Summary -->
      <div>
        <el-card shadow="never" class="!border-none !rounded-xl !bg-white">
          <template #header>
            <div class="font-bold flex items-center gap-2">
              <el-icon><Tickets /></el-icon>
              Thông tin đơn hàng
            </div>
          </template>
          
          <div class="space-y-4">
            <div v-for="order in orders" :key="order.id" class="flex justify-between items-start pb-4 border-b border-gray-100 last:border-0 last:pb-0">
              <div>
                <div class="font-bold text-gray-800">{{ order.packageName }}</div>
                <div class="text-sm text-gray-500">Tài khoản: {{ order.ntripAccountName }}</div>
                <div class="text-xs text-gray-400 mt-1">Đơn hàng #{{ order.id }}</div>
              </div>
              <div class="font-bold text-gray-700">
                {{ formatPrice(Number(order.amount || 0)) }}
              </div>
            </div>
          </div>

          <div class="mt-6 pt-4 border-t-2 border-gray-200">
            <div class="flex justify-between items-center mb-3">
              <span class="text-gray-500">Mã giao dịch</span>
              <span class="font-mono bg-gray-100 px-2 py-1 rounded text-gray-700 font-bold select-all">{{ payosOrderCode || '---' }}</span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-gray-600 font-medium">Tổng thanh toán</span>
              <span class="text-2xl font-bold text-blue-600">{{ formatPrice(totalPrice) }}</span>
            </div>
            <div class="text-right text-xs text-gray-400 mt-1">Đã bao gồm VAT</div>
          </div>
        </el-card>

        <div class="mt-6 p-4 rounded-xl bg-blue-50 border border-blue-100 flex gap-4 items-start">
          <el-icon class="text-blue-500 text-xl mt-1"><InfoFilled /></el-icon>
          <div class="text-sm text-blue-800">
            <p class="font-bold mb-1">Giao dịch an toàn</p>
            <p>Mọi giao dịch thanh toán đều được mã hóa bằng chuẩn bảo mật của ngân hàng theo hệ thống PayOS VietQR.</p>
          </div>
        </div>
      </div>

      <!-- PayOS Embedded Checkout -->
      <div>
        <el-card shadow="never" class="!border-none !rounded-xl h-full pb-0 !bg-white overflow-hidden">
          <template #header>
            <div class="font-bold text-center">Quét mã QR để thanh toán</div>
          </template>
          
          <!-- This ID matches the embedded target for payos-checkout -->
          <div id="payos-checkout-iframe" class="w-full h-[600px] rounded-lg overflow-hidden flex flex-col items-center justify-center bg-gray-50 border border-gray-100">
            <span v-if="!checkoutUrlReady" class="text-gray-400 animate-pulse">Đang tải biểu mẫu QR Code...</span>
          </div>
        </el-card>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ElMessage } from 'element-plus';
import { Loading, Tickets, InfoFilled } from '@element-plus/icons-vue';
import { orderApi } from '../../services/api';

// Important: import usePayOS from the installed package
import { usePayOS, type PayOSConfig } from '@payos/payos-checkout';

const route = useRoute();
const router = useRouter();
const loading = ref(true);
const orders = ref<any[]>([]);
const checkoutUrlReady = ref(false);
const payosOrderCode = ref<string | number>('');

let payOSInstance: any = null;

const orderIds = computed(() => {
  const idsParam = route.query.ids as string;
  return idsParam ? idsParam.split(',').map(Number) : [];
});

const totalPrice = computed(() => {
  return orders.value.reduce((sum, order) => sum + Number(order.amount || 0), 0);
});

onMounted(async () => {
  if (orderIds.value.length === 0) {
    ElMessage.warning('Không có đơn hàng nào được chọn');
    router.push('/user/orders');
    return;
  }
  
  await initializePayment();
});

onUnmounted(() => {
  if (payOSInstance) {
    payOSInstance.exit();
  }
});

const initializePayment = async () => {
  loading.value = true;
  try {
    // 1. Gửi ds các Order IDs muốn thanh toán gộp lên Server
    // Server sẽ gọi PayOS Create Payment Link API -> Trả về mảng orderDetail, và 1 url thanh toán gộp
    const res = await orderApi.checkout(orderIds.value);
    
    // Giả sử API trả về chi tiết các đơn hàng để hiển thị
    orders.value = res.data.orderDetails || [
      // Fallback mock nếu chưa có API thực
      { id: orderIds.value[0], packageName: 'Gói Tiêu chuẩn', ntripAccountId: 'RtkCORS_Demo', amount: 2500000 }
    ];

    const checkoutUrl = res.data.checkoutUrl;
    payosOrderCode.value = res.data.orderCode || '';
    
    if (checkoutUrl) {
      setupPayOS(checkoutUrl);
    } else {
      // Logic Mock nếu thiếu URL chạy thử nghiệm từ backend
      ElMessage.warning('Chưa cấu hình API PayOS thực. Khởi tạo UI mẫu.');
    }
  } catch (error: any) {
    console.error('Lỗi khi khởi tạo đơn hàng thanh toán', error);
    ElMessage.error(error.response?.data?.message || 'Không thể tạo phiên giao dịch');
  } finally {
    loading.value = false;
  }
};

const setupPayOS = (checkoutUrl: string) => {
  const config: PayOSConfig = {
    RETURN_URL: `${window.location.origin}/user/payment-result`,
    ELEMENT_ID: 'payos-checkout-iframe',
    CHECKOUT_URL: checkoutUrl,
    embedded: true,
    onSuccess: (event: any) => {
      // Khi giao dịch qua mã QR thành công, sdk gọi vào đây
      console.log('Payment success', event);
      // Backend Webhook sẽ xử lý việc cập nhật Order, ở đây chỉ update UI
      router.push({ path: '/user/payment-result', query: { status: 'PAID', orderCode: event.orderCode, code: '00' }});
    },
    onCancel: (event: any) => {
      console.log('Payment cancelled', event);
      ElMessage.info('Đã hủy giao dịch thanh toán');
      router.push('/user/orders');
    },
    onExit: (event: any) => {
      console.log('Payment popup closed', event);
    }
  };

  payOSInstance = usePayOS(config);
  checkoutUrlReady.value = true;
  
  // Hiển thị iframe
  setTimeout(() => {
    payOSInstance.open();
  }, 100);
};

const formatPrice = (price: number) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(price);
};
</script>
