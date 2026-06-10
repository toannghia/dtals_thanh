<template>
  <div>
    <div class="mb-8">
      <!--<h2 class="text-2xl font-bold text-gray-800">Bảng điều khiển</h2>-->
      <p class="text-gray-500">Hãy thực hiện các bước dưới đây để kích hoạt tài khoản</p>
    </div>

    <!-- Overview Stepper -->
    <el-card shadow="hover" class="!border-none !rounded-xl mb-8">
      <div class="p-4">
        <el-steps :active="activeStep" finish-status="success" align-center>
          <el-step title="Đăng ký tài khoản" description="Đã hoàn thành" />
          <el-step title="Xác thực eKYC" :description="ekycDescription" />
          <el-step title="Tạo tài khoản NTRIP" :description="ntripDescription" />
          <el-step title="Thanh toán" :description="paymentDescription" />
          <el-step title="Kích hoạt" description="Sẵn sàng sử dụng" />
        </el-steps>
      </div>
    </el-card>

    <!-- Detailed Action Panel based on Active Step -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      
      <!-- Current Action Required -->
      <el-card shadow="hover" class="!border-none !rounded-xl h-full">
        <template #header>
          <div class="font-bold flex items-center gap-2">
            <span class="w-8 h-8 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center text-sm">
              {{ activeStep + 1 }}
            </span>
            Hành động tiếp theo
          </div>
        </template>
        
        <div class="flex flex-col items-center justify-center text-center py-6 h-full min-h-[200px]">
          <!-- Step 1 (Index 0 is completed since they are logged in) -->
          
          <!-- Step 2: eKYC -->
          <div v-if="activeStep === 1" class="w-full">
            <div class="w-16 h-16 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <span class="text-2xl">🛡️</span>
            </div>
            <h3 class="text-lg font-bold mb-2">Xác thực danh tính (eKYC)</h3>
            <p class="text-gray-500 text-sm mb-6 max-w-sm mx-auto">
              Theo quy định, bạn cần xác thực Căn cước công dân và Ảnh chân dung trước khi có thể tạo tài khoản NTRIP.
            </p>
            <el-button type="primary" size="large" @click="$router.push('/user/ekyc')">
              Bắt đầu xác thực ngay
            </el-button>
          <!-- Alert for Status -->
    <div v-if="ekycStatus === 'NEEDS_REVIEW' || ekycStatus === 'PENDING'" class="w-full mt-4">
      <el-alert title="Hồ sơ đang chờ phê duyệt" type="warning" description="Quản trị viên đang xem xét hồ sơ của bạn. Quá trình này có thể mất từ 1-2 ngày làm việc." show-icon :closable="false" />
    </div>
    <div v-if="ekycStatus === 'REJECTED'" class="w-full mt-4">
      <el-alert title="Hồ sơ bị từ chối" type="error" description="Hồ sơ eKYC của bạn không hợp lệ. Vui lòng thực hiện lại." show-icon :closable="false" />
    </div>
          </div>

          <!-- Step 3: NTRIP Account -->
          <div v-if="activeStep === 2" class="w-full">
            <div class="w-16 h-16 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <span class="text-2xl">👤</span>
            </div>
            <h3 class="text-lg font-bold mb-2">Tạo tài khoản NTRIP</h3>
            <p class="text-gray-500 text-sm mb-6 max-w-sm mx-auto">
              Hồ sơ eKYC của bạn đã được duyệt. Bước tiếp theo là tạo tài khoản NTRIP và chọn gói cước phù hợp.
            </p>
            <el-button type="primary" size="large" @click="$router.push('/user/ntrip-accounts')">
              Tạo tài khoản NTRIP
            </el-button>
          </div>

          <!-- Step 4: Payment -->
          <div v-if="activeStep === 3" class="w-full">
            <div class="w-16 h-16 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <span class="text-2xl">💳</span>
            </div>
            <h3 class="text-lg font-bold mb-2">Thanh toán đơn hàng</h3>
            <p class="text-gray-500 text-sm mb-6 max-w-sm mx-auto">
              Bạn có đơn hàng đang chờ thanh toán. Vui lòng hoàn tất thanh toán để hệ thống tự động kích hoạt tài khoản NTRIP.
            </p>
            <el-button type="primary" size="large" @click="$router.push('/user/orders')">
              Đến trang thanh toán
            </el-button>
          </div>

          <!-- Step 5: Active -->
          <div v-if="activeStep === 4" class="w-full">
            <div class="w-16 h-16 bg-green-50 text-green-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <span class="text-2xl">✅</span>
            </div>
            <h3 class="text-lg font-bold mb-2">Xin chào, {{ authStore.user?.fullName || authStore.user?.username }}</h3>
            <p class="text-gray-500 text-sm mb-6 max-w-sm mx-auto">
              Tài khoản của bạn đã được kích hoạt đầy đủ. Bạn có thể sử dụng dịch vụ Cors ngay bây giờ.
            </p>
            <el-button type="success" plain @click="$router.push('/user/ntrip-accounts')">
              Quản lý tài khoản NTRIP
            </el-button>
          </div>
        </div>
      </el-card>

      <!-- User Info Summary -->
      <el-card shadow="hover" class="!border-none !rounded-xl h-full">
        <template #header>
          <div class="font-bold">Thông tin cá nhân</div>
        </template>
        <div class="space-y-4">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center text-gray-500 font-bold text-lg">
              {{ authStore.user?.fullName?.charAt(0) || authStore.user?.username?.charAt(0) || 'U' }}
            </div>
            <div>
              <div class="font-medium">{{ authStore.user?.fullName || 'Chưa cập nhật tên' }}</div>
              <div class="text-sm text-gray-500">{{ authStore.user?.email }}</div>
            </div>
          </div>
          
          <el-divider class="!my-4" />
          
          <div class="grid grid-cols-2 gap-4 text-sm">
            <div>
              <div class="text-gray-500 mb-1">Trạng thái định danh</div>
              <el-tag :type="getKycTagType()" size="small">
                 {{ getKycLabel() }}
              </el-tag>
            </div>
            <div>
              <div class="text-gray-500 mb-1">Số lượng NTRIP</div>
              <div class="font-bold text-green-600">{{ ntripCount }} hoạt động</div>
              <div v-if="pendingNtrips.length > 0" class="font-bold text-orange-500 mt-1">
                {{ pendingNtrips.length }} chờ kích hoạt
              </div>
            </div>
          </div>
          
          <!-- Danh sách chờ kích hoạt -->
          <div v-if="pendingNtrips.length > 0" class="mt-4 p-3 bg-orange-50 rounded border border-orange-100">
            <div class="text-sm font-semibold text-orange-800 mb-2">Tài khoản chờ thanh toán:</div>
            <ul class="text-sm text-gray-700 space-y-1 pl-4 list-disc">
              <li v-for="ntrip in pendingNtrips" :key="ntrip.id">
                <span class="font-medium">{{ ntrip.ntripAccountName }}</span>
                <span class="text-gray-500 ml-1">({{ ntrip.packageName }})</span>
              </li>
            </ul>
             <el-button size="small" type="primary" plain class="mt-3" @click="$router.push('/user/orders')">
              Thanh toán ngay
            </el-button>
          </div>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useAuthStore } from '../../store/auth';
import { ekycApi, orderApi, ntripUserApi } from '../../services/api';

const authStore = useAuthStore();

// Trạng thái workflow
const ekycStatus = ref<string>('NONE'); // NONE, PENDING, NEEDS_REVIEW, APPROVED, REJECTED
const ntripCount = ref(0);
const pendingOrdersCount = ref(0);
const pendingNtrips = ref<any[]>([]); // Danh sách tài khoản chờ kích hoạt
const loading = ref(true);

onMounted(async () => {
  await loadDashboardData();
});

const loadDashboardData = async () => {
  loading.value = true;
  try {
    // 1. Fetch eKYC Status
    try {
      const ekycRes = await ekycApi.getStatus();
      let status = ekycRes.data.kycStatus || ekycRes.data.status || 'NONE';
      if (status === 'PENDING' && !ekycRes.data.latestSubmission) {
        status = 'NONE';
      }
      ekycStatus.value = status;
    } catch {
      ekycStatus.value = 'NONE';
    }

    // 2. Fetch NTRIP Account Count (Need end user specific endpoint if needed, assuming list works with their token)
    try {
      const ntripRes = await ntripUserApi.list({ page: 1, size: 10 });
      ntripCount.value = ntripRes.data.total || 0;
    } catch {
      ntripCount.value = 0;
    }

    // 3. Fetch Pending Orders Count & List
    if (ekycStatus.value === 'APPROVED' || ekycStatus.value === 'VERIFIED') {
      try {
        const orderRes = await orderApi.list({ status: 'PENDING' });
        const orders = orderRes.data || [];
        pendingOrdersCount.value = orders.length;
        pendingNtrips.value = orders.filter((o: any) => o.ntripAccountName);
      } catch {
        pendingOrdersCount.value = 0;
        pendingNtrips.value = [];
      }
    }

  } catch (error) {
    console.error('Lỗi khi tải dữ liệu dashboard', error);
  } finally {
    loading.value = false;
  }
};

// Tính toán bước hiện tại
const isKycVerified = computed(() => ekycStatus.value === 'APPROVED' || ekycStatus.value === 'VERIFIED');

const activeStep = computed(() => {
  if (!isKycVerified.value) {
    return 1; // Đang ở bước eKYC
  }
  if (pendingOrdersCount.value > 0) {
    return 3; // Có đơn NTRIP chờ thanh toán
  }
  if (ntripCount.value === 0) {
    return 2; // Đã duyệt KYC, cần tạo NTRIP
  }
  return 4; // Hoàn tất, có NTRIP active
});

// Dynamic descriptions
const ekycDescription = computed(() => {
  if (isKycVerified.value) return 'Đã phê duyệt';
  if (ekycStatus.value === 'NEEDS_REVIEW' || ekycStatus.value === 'PENDING') return 'Chờ admin duyệt';
  if (ekycStatus.value === 'REJECTED') return 'Bị từ chối';
  return 'Chưa làm KYC';
});

const ntripDescription = computed(() => {
  if (activeStep.value < 2) return 'Chờ xác thực KYC';
  if (ntripCount.value > 0 || pendingOrdersCount.value > 0) return `Đã tạo tài khoản`;
  return 'Tạo thiết bị';
});

const paymentDescription = computed(() => {
  if (activeStep.value < 3) return 'Chờ tạo đơn';
  if (pendingOrdersCount.value > 0) return `${pendingOrdersCount.value} đơn chờ thanh toán`;
  return 'Đã thanh toán';
});

// Helper functions cho UI
const getKycTagType = () => {
  switch (ekycStatus.value) {
    case 'APPROVED':
    case 'VERIFIED': return 'success';
    case 'NEEDS_REVIEW':
    case 'PENDING': return 'warning';
    case 'REJECTED': return 'danger';
    default: return 'info';
  }
};

const getKycLabel = () => {
  switch (ekycStatus.value) {
    case 'APPROVED':
    case 'VERIFIED': return 'Đã xác minh';
    case 'NEEDS_REVIEW':
    case 'PENDING': return 'Đang chờ duyệt';
    case 'REJECTED': return 'Cần làm lại';
    default: return 'Chưa xác minh';
  }
};
</script>
